"""Convert C enum/struct/#define/function declarations to equivalent Python code.

Standalone, dependency-free (stdlib only), so it can be shared with
teammates who don't use Neovim/Lua at all. Works on Linux, macOS, and
Windows -- always invoke it explicitly with an interpreter rather than
relying on execute permissions or a shebang line:

    python3 c_to_python.py < input.c > output.py      (Linux/macOS)
    python c_to_python.py < input.c > output.py        (Windows, cmd/PowerShell)
    py c_to_python.py < input.c > output.py             (Windows, py launcher)

    echo '#define FOO 5' | python3 c_to_python.py

Also usable as a library:
    from c_to_python import convert_lines
    convert_lines(["#define FOO 5"])  # -> ["FOO = 5"]

Requires Python 3.11+ (the generated output uses `X | Y` unions and
`match`/`case` natively, so both this script and its output rely on
modern syntax rather than `typing.Union`/`Optional` or if/elif chains).

Notes on scope:
    - Object-like macros (#define NAME value) become plain assignments:
      `#define FOO 5` -> `FOO = 5`
    - Function-like macros (#define NAME(args) value) are intentionally
      skipped and left as a TODO comment; converting C macro semantics into
      correct Python functions isn't reliably automatable.
    - `enum`/`struct`/`union` (including typedef'd forms) are converted to
      an IntEnum subclass / a plain class with annotated fields,
      respectively. Nested struct/union/enum blocks (anonymous or named)
      are converted to nested classes. Callers are expected to provide
      `from enum import IntEnum` themselves; this script never emits that
      import.
    - Function declarations/definitions get their *signature* converted
      (return type, parameter names/types) into a real `def ...:` line, with
      basic C types mapped to Python types -- int/unsigned/signed variants,
      the fixed-width stdint types (int8_t..uint64_t), size_t/ssize_t, bool,
      float/double, and char*/char[] all map to their natural Python
      equivalent (mostly `int`, `str` for char).
    - Function *bodies* are transpiled statement-by-statement on a
      best-effort basis (if/else, while, for, do/while, switch->match,
      declarations, assignments, calls, return/break/continue). The result
      is only guaranteed to be syntactically valid Python, not runtime
      correct -- it may call functions or reference names that don't exist
      in Python, since it's a mechanical rewrite of C, not a real compiler.
      Constructs that can't be confidently rewritten (goto/labels, and
      anything that plain doesn't parse) are kept as a comment instead of
      being guessed at.
    - Anything that can't be confidently converted is left as a
      `# TODO: manual conversion needed: ...` comment rather than guessed.
"""

from __future__ import annotations
import re
import sys
from dataclasses import dataclass, field

PYTHON_KEYWORDS = {
    "False",
    "None",
    "True",
    "and",
    "as",
    "assert",
    "async",
    "await",
    "break",
    "class",
    "continue",
    "def",
    "del",
    "elif",
    "else",
    "except",
    "finally",
    "for",
    "from",
    "global",
    "if",
    "import",
    "in",
    "is",
    "lambda",
    "nonlocal",
    "not",
    "or",
    "pass",
    "raise",
    "return",
    "try",
    "while",
    "with",
    "yield",
}

C_TYPES = r"u?int\d+_t|size_t|bool|char|short|int|long|float|double"

CONTROL_KEYWORDS = {"if", "for", "while", "switch", "else", "do", "return", "goto"}


# ---------------------------------------------------------------------------
# Small string helpers
# ---------------------------------------------------------------------------


def python_identifier(name: str) -> str:
    """Escape a C identifier that collides with a Python keyword."""
    name = name.strip()
    return name + "_" if name in PYTHON_KEYWORDS else name


def normalize_args(args: str) -> str:
    if args.strip() in ("", "void"):
        return ""
    parts = [python_identifier(a) for a in args.split(",") if a.strip()]
    return ", ".join(parts)


def clean_block_comment_text(s: str) -> str:
    s = s.strip()
    s = re.sub(r"^\*", "", s).strip()
    return s


def join_continued_lines(lines: list[str]) -> list[str]:
    """Join C line-continuations (trailing backslash) into single logical lines."""
    joined: list[str] = []
    current: str | None = None

    for line in lines:
        continued = bool(re.search(r"\\\s*$", line))
        part = re.sub(r"\\\s*$", "", line)
        current = f"{current} {part.strip()}" if current is not None else part
        if not continued:
            joined.append(current)
            current = None

    if current is not None:
        joined.append(current)

    return joined


def strip_outer_parens(s: str) -> str:
    s = s.strip()

    while s.startswith("(") and s.endswith(")"):
        depth = 0
        wraps_whole_expr = True

        for i, c in enumerate(s):
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0 and i < len(s) - 1:
                    wraps_whole_expr = False
                    break

        if depth != 0 or not wraps_whole_expr:
            break

        s = s[1:-1].strip()

    return s


def strip_simple_identifier_parens(s: str) -> str:
    """Drop redundant parens around a bare identifier/number, e.g. `(FOO)` -> `FOO`."""
    previous = None
    while previous != s:
        previous = s
        s = re.sub(r"\(([A-Za-z_]\w*)\)", r"\1", s)
        s = re.sub(r"\((0[xX][0-9a-fA-F]+)\)", r"\1", s)
        s = re.sub(r"\((\d+)\)", r"\1", s)
    return s


def strip_c_int_suffixes(s: str) -> str:
    def strip_suffix(m: re.Match[str]) -> str:
        return re.sub(r"[uUlL]+$", "", m.group(0))

    s = re.sub(r"0[xX][0-9a-fA-F]+[uUlL]*", strip_suffix, s)
    s = re.sub(r"(?<![\w])\d+[uUlL]+(?![\w])", strip_suffix, s)
    return s


def strip_c_casts(s: str) -> str:
    s = re.sub(rf"\(({C_TYPES})\)\s*\(([^()]*?)\)", r"\2", s)
    s = re.sub(rf"\(({C_TYPES})\)\s*([A-Za-z_]\w*)", r"\2", s)
    return s


def translate_c_tokens(expr: str) -> str:
    expr = re.sub(r"\bNULL\b", "None", expr)
    expr = re.sub(r"\btrue\b", "True", expr)
    expr = re.sub(r"\bfalse\b", "False", expr)
    expr = re.sub(r"\bTRUE\b", "True", expr)
    expr = re.sub(r"\bFALSE\b", "False", expr)
    expr = expr.replace("&&", " and ")
    expr = expr.replace("||", " or ")
    expr = re.sub(r"!([^=])", r" not \1", expr)
    # `.` already covers Python attribute access for both values and
    # pointers, so C's `->` collapses onto the same operator.
    expr = expr.replace("->", ".")
    return expr


def find_top_level_ternary(expr: str) -> tuple[int | None, int | None]:
    """Return (index of '?', index of ':') for the first depth-0 ternary, else (None, None)."""
    depth = 0
    question_pos: int | None = None

    for i, c in enumerate(expr):
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
        elif c == "?" and depth == 0:
            question_pos = i
            break

    if question_pos is None:
        return None, None

    depth = 0
    for i in range(question_pos + 1, len(expr)):
        c = expr[i]
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
        elif c == ":" and depth == 0:
            return question_pos, i

    return None, None


def convert_ternary(expr: str) -> str:
    expr = strip_outer_parens(expr)
    question_pos, colon_pos = find_top_level_ternary(expr)

    if question_pos is None or colon_pos is None:
        return expr

    condition = expr[:question_pos].strip()
    true_expr = expr[question_pos + 1 : colon_pos].strip()
    false_expr = expr[colon_pos + 1 :].strip()

    condition = convert_ternary(strip_outer_parens(condition))
    true_expr = convert_ternary(strip_outer_parens(true_expr))
    false_expr = convert_ternary(strip_outer_parens(false_expr))

    return f"{true_expr} if {condition} else {false_expr}"


def split_python_comment(s: str) -> tuple[str, str]:
    """Split `code # comment` (comments already normalized to `#` by this point)."""
    m = re.match(r"^(.*?)\s+#\s*(.*)$", s)
    if m:
        return m.group(1).strip(), " # " + m.group(2).strip()
    return s.strip(), ""


def split_top_level(s: str, sep: str) -> list[str]:
    """Split `s` on `sep` characters that aren't nested inside (), [], or {}."""
    parts: list[str] = []
    depth = 0
    start = 0

    for i, c in enumerate(s):
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == sep and depth == 0:
            parts.append(s[start:i].strip())
            start = i + 1

    parts.append(s[start:].strip())
    return parts


def split_top_level_commas(s: str) -> list[str]:
    return split_top_level(s, ",")


def normalize_expr(expr: str) -> str:
    expr = strip_c_int_suffixes(expr)
    expr = strip_c_casts(expr)
    expr = strip_outer_parens(expr)
    expr = strip_c_casts(expr)
    expr = strip_outer_parens(expr)
    expr = translate_c_tokens(expr)
    expr = convert_ternary(expr)
    expr = strip_simple_identifier_parens(expr)
    expr = re.sub(r"\s+", " ", expr.strip())
    return expr


def unsupported_reason(expr: str) -> str | None:
    if re.search(r"sizeof\s*\(", expr):
        return "sizeof needs manual conversion"
    return None


# ---------------------------------------------------------------------------
# Shared C-type -> Python-type mapping (used by struct fields, locals, and
# function signatures)
# ---------------------------------------------------------------------------


def c_base_type_to_annotation(
    base_type: str, is_pointer: bool = False, is_array: bool = False
) -> str:
    """Map a C base type (qualifiers/stars/array-brackets already stripped
    out of `base_type` itself, but described via `is_pointer`/`is_array`)
    to a Python type-annotation string."""
    t = re.sub(r"\b(const|volatile|struct|enum|unsigned|signed)\b", " ", base_type)
    t = re.sub(r"\s+", " ", t).strip()

    if t == "void":
        return "None" if not is_pointer else "object"
    if re.search(r"\bbool\b", t):
        return "bool"
    if re.search(r"\b(float|double)\b", t):
        return "float"
    if re.search(r"\bchar\b", t):
        # Whether it's `char`, `char*`, or `char[]`, str is the natural
        # Python stand-in; a bare `char` is just a 1-byte character too.
        return "str"
    if re.search(r"\b(u?int(8|16|32|64)_t|size_t|ssize_t)\b", t):
        return "int"
    if re.search(r"\b(int|short|long)\b", t):
        return "int"
    # Unresolvable/aggregate type (probably a struct or enum name defined
    # elsewhere) -- can't safely guess more than "some object".
    return "object"


def default_value_for_annotation(annotation: str) -> str:
    return {
        "bool": "False",
        "float": "0.0",
        "str": "''",
        "int": "0",
    }.get(annotation, "None")


# ---------------------------------------------------------------------------
# Comment normalization (// and /* */ -> #)
# ---------------------------------------------------------------------------


def convert_c_comments(lines: list[str]) -> list[str]:
    converted: list[str] = []
    in_block_comment = False

    for line in lines:
        out = ""
        comments: list[str] = []
        rest = line

        while rest != "":
            if in_block_comment:
                close_start = rest.find("*/")
                if close_start != -1:
                    comment_text = clean_block_comment_text(rest[:close_start])
                    if comment_text:
                        comments.append(comment_text)
                    rest = rest[close_start + 2 :]
                    in_block_comment = False
                else:
                    comment_text = clean_block_comment_text(rest)
                    if comment_text:
                        comments.append(comment_text)
                    rest = ""
            else:
                block_start = rest.find("/*")
                slash_start = rest.find("//")

                if slash_start != -1 and (
                    block_start == -1 or slash_start < block_start
                ):
                    out += rest[:slash_start]
                    comment_text = rest[slash_start + 2 :].strip()
                    if comment_text:
                        comments.append(comment_text)
                    rest = ""
                elif block_start != -1:
                    out += rest[:block_start]
                    rest = rest[block_start + 2 :]
                    in_block_comment = True
                else:
                    out += rest
                    rest = ""

        out = out.rstrip()

        if comments:
            if out.strip() == "":
                converted.append("# " + " ".join(comments))
            else:
                converted.append(out + " # " + " ".join(comments))
        elif out.strip() == "" and in_block_comment:
            converted.append("#")
        else:
            converted.append(out)

    return converted


# ---------------------------------------------------------------------------
# enum / struct / union block handling
# ---------------------------------------------------------------------------


@dataclass
class BlockInfo:
    kind: str  # "enum", "struct", or "union"
    name: str | None = None
    is_typedef: bool = False
    body: list[str] = field(default_factory=list)
    comment: str = ""
    # Trailing identifier after the closing brace when it names a
    # *variable/field* rather than the type itself, e.g. the `p` in
    # `struct Point { ... } p;` or the `inner` in a nested struct member.
    var_name: str | None = None


# Matches a complete enum/struct/union declaration written entirely on one
# line, e.g.:
#   typedef enum myenum{ADAM=0,bas}myenum;
#   struct Point{int x;int y;};
#   typedef struct{int x;int y;}Point;
#   union { int i; float f; } u;
ONE_LINE_BLOCK_RE = re.compile(
    r"^(?P<typedef>typedef\s+)?"
    r"(?P<kind>enum|struct|union)\s*"
    r"(?P<tag>[A-Za-z_]\w*)?\s*"
    r"\{(?P<body>.*)\}\s*"
    r"(?P<trailing>[A-Za-z_]\w*)?\s*;$"
)


def try_convert_one_line_block(line: str) -> tuple[list[str], str | None] | None:
    """If `line` is a *complete* enum/struct/union declaration on a single
    line, convert it and return (converted_lines, trailing_var_name).
    Otherwise return None so the multi-line scanner (detect_block_start /
    try_convert_block) gets a chance instead."""
    code, comment = split_python_comment(line)
    m = ONE_LINE_BLOCK_RE.match(code.strip())

    if not m:
        return None

    kind = m.group("kind")
    is_typedef = m.group("typedef") is not None
    tag = m.group("tag")
    trailing = m.group("trailing")
    body = m.group("body")

    type_name = trailing if (is_typedef and trailing) else tag
    var_name = trailing if not is_typedef else None

    block = BlockInfo(
        kind=kind, name=type_name, is_typedef=is_typedef, body=[body], comment=comment
    )

    converted = (
        convert_enum_block(block) if kind == "enum" else convert_struct_block(block)
    )
    return converted, var_name


def detect_block_start(line: str) -> BlockInfo | None:
    code, _ = split_python_comment(line)
    m = re.match(r"^\s*(.*?)\s*\{\s*$", code)
    if not m:
        return None
    before_brace = m.group(1)

    for kind in ("enum", "struct", "union"):
        m = re.match(rf"^typedef\s+{kind}\s+([A-Za-z_]\w*)$", before_brace)
        if m:
            return BlockInfo(kind=kind, name=m.group(1), is_typedef=True)
        if re.match(rf"^typedef\s+{kind}\s*$", before_brace):
            return BlockInfo(kind=kind, is_typedef=True)
        m = re.match(rf"^{kind}\s+([A-Za-z_]\w*)$", before_brace)
        if m:
            return BlockInfo(kind=kind, name=m.group(1), is_typedef=False)
        if re.match(rf"^{kind}\s*$", before_brace):
            # Anonymous, non-typedef block -- most common as a nested
            # member inside another struct/union, e.g. `struct { ... } x;`.
            return BlockInfo(kind=kind, is_typedef=False)

    return None


def detect_block_end(line: str) -> tuple[str | None, str | None]:
    """Return (trailing_identifier_or_None, comment) if this line closes a
    block, else (None, None). The trailing identifier is either the
    typedef name or a variable/field name depending on context; the caller
    decides which based on `block.is_typedef`."""
    code, comment = split_python_comment(line)
    m = re.match(r"^\s*\}\s*([A-Za-z_]\w*)\s*;\s*$", code)
    if m:
        return m.group(1), comment
    if re.match(r"^\s*\}\s*;\s*$", code):
        return None, comment
    return None, None


def numeric_value(expr: str) -> int | None:
    expr = expr.strip()
    if re.match(r"^0[xX][0-9a-fA-F]+$", expr):
        return int(expr, 16)
    if re.match(r"^-?\d+$", expr):
        return int(expr)
    return None


def convert_enum_block(block: BlockInfo) -> list[str]:
    out: list[str] = []
    class_name = python_identifier(block.name or "CEnum")
    next_value: int | None = 0

    out.append(f"class {class_name}(IntEnum):{block.comment}")

    for line in block.body:
        code, comment = split_python_comment(line)
        code = re.sub(r",\s*$", "", code.strip())

        if code != "" and not code.startswith("#"):
            for entry in split_top_level_commas(code):
                entry_comment = ""
                entry = re.sub(r",\s*$", "", entry.strip())

                if entry == "":
                    continue

                m = re.match(r"^([A-Za-z_]\w*)\s*=\s*(.+)$", entry)
                if m:
                    name, value = m.group(1), m.group(2)
                else:
                    m = re.match(r"^([A-Za-z_]\w*)$", entry)
                    name, value = (m.group(1), None) if m else (None, None)

                if name:
                    if value is not None:
                        value = normalize_expr(value)
                        parsed_value = numeric_value(value)
                        next_value = (
                            parsed_value + 1 if parsed_value is not None else None
                        )
                    elif next_value is not None:
                        value = str(next_value)
                        next_value += 1
                    else:
                        value = "..."
                        entry_comment = " # TODO: fill enum value"

                    out.append(
                        f"    {python_identifier(name)} = {value}{comment}{entry_comment}"
                    )
                    comment = ""
        elif line.strip().startswith("#"):
            out.append("    " + line.strip())

    if len(out) == 1:
        out.append("    pass")

    return out


def map_c_field_type(c_type: str, declarator: str) -> tuple[str, str]:
    is_array = "[" in declarator
    is_pointer = "*" in declarator

    annotation = c_base_type_to_annotation(
        c_type, is_pointer=is_pointer, is_array=is_array
    )

    # A non-char array becomes a list (str already covers char[] naturally).
    if is_array and annotation != "str":
        annotation = "list"

    return annotation, default_value_for_annotation(annotation)


@dataclass
class StructField:
    name: str
    annotation: str
    default: str
    comment: str


C_QUALIFIERS = {"const", "volatile", "unsigned", "signed", "struct", "static"}


def split_c_type_and_declarators(code: str) -> tuple[str, str] | None:
    """Split '<c type> <declarator[, declarator...]>' into (type, declarators).

    Handles multi-word types (e.g. "const char *label", "unsigned long x")
    by consuming leading qualifier words plus one base-type word, rather
    than naively splitting on the first whitespace (which misparses
    "const char *label" as type="const", declarator="char *label").
    """
    tokens = code.split()
    if len(tokens) < 2:
        return None

    i = 0
    type_words = []

    while i < len(tokens) - 1 and tokens[i] in C_QUALIFIERS:
        type_words.append(tokens[i])
        i += 1

    if i >= len(tokens):
        return None

    type_words.append(tokens[i])
    i += 1

    if i >= len(tokens):
        return None

    return " ".join(type_words), " ".join(tokens[i:])


def looks_like_type(c_type: str) -> bool:
    """Heuristic for whether a leading token sequence reads as a C type
    (used to tell local variable declarations apart from plain expression
    statements like function calls, which parse the same shape)."""
    tokens = c_type.split()
    if not tokens:
        return False
    if any(t in C_QUALIFIERS for t in tokens):
        return True
    if re.search(rf"\b({C_TYPES})\b", c_type):
        return True
    last = tokens[-1]
    # A capitalized or `_t`-suffixed final token reads like a typedef'd
    # struct/enum name (common C naming convention).
    return last.endswith("_t") or last[:1].isupper()


def parse_struct_field(line: str) -> list["StructField | str"] | None:
    """Return a list mixing StructField entries and TODO-comment strings, or None to skip."""
    code, comment = split_python_comment(line)
    code = re.sub(r";\s*$", "", code.strip())

    if code == "" or code.startswith("#"):
        return None

    if "{" in code or "}" in code:
        return ["# TODO: manual conversion needed: " + line]

    split_result = split_c_type_and_declarators(code)
    if not split_result:
        return ["# TODO: manual conversion needed: " + line]

    c_type, declarators = split_result
    fields: list["StructField | str"] = []

    for declarator in split_top_level_commas(declarators):
        name_match = re.search(r"([A-Za-z_]\w*)\s*\[[^\]]*\]\s*$", declarator)
        if not name_match:
            name_match = re.search(r"\**\s*([A-Za-z_]\w*)\s*$", declarator)

        if name_match:
            annotation, default = map_c_field_type(c_type, declarator)
            fields.append(
                StructField(
                    name=python_identifier(name_match.group(1)),
                    annotation=annotation,
                    default=default,
                    comment=comment,
                )
            )
            comment = ""
        else:
            fields.append("# TODO: manual conversion needed: " + line)

    return fields


def split_struct_body_lines(body_lines: list[str]) -> list[str]:
    """Expand any body line containing multiple ';'-separated field
    declarations (as happens with a fully single-line struct body like
    'int x;int y;') into one entry per field."""
    expanded: list[str] = []

    for line in body_lines:
        code, comment = split_python_comment(line)
        parts = [p for p in split_top_level(code, ";") if p.strip() != ""]

        if len(parts) <= 1:
            expanded.append(line)
        else:
            for i, part in enumerate(parts):
                suffix = comment if i == len(parts) - 1 else ""
                expanded.append(part.strip() + ";" + suffix)

    return expanded


def instance_line(class_lines: list[str], var_name: str, annotated: bool) -> str:
    """Build the `field = Type()` (or annotated `field: Type = Type()`)
    line for a nested/variable instance of a block just converted to a
    class, given that class's already-converted lines."""
    m = re.match(r"^class\s+(\w+)", class_lines[0]) if class_lines else None
    class_name = m.group(1) if m else "object"
    is_enum = bool(class_lines) and "IntEnum" in class_lines[0]
    value = f"{class_name}(0)" if is_enum else f"{class_name}()"
    name = python_identifier(var_name)
    return f"{name}: {class_name} = {value}" if annotated else f"{name} = {value}"


def rename_generic_class(class_lines: list[str], var_name: str) -> list[str]:
    """An anonymous nested block gets a placeholder class name (CStruct /
    CEnum); once we know the field name it ends up assigned to, give the
    class that name instead (PascalCased) so multiple anonymous members
    don't collide on the same generic name."""
    if not class_lines:
        return class_lines
    m = re.match(r"^class (CStruct|CEnum)\b", class_lines[0])
    if not m:
        return class_lines
    new_name = python_identifier(
        "".join(w.capitalize() for w in re.split(r"[_\s]+", var_name) if w) or "Nested"
    )
    return [re.sub(r"^class \w+", f"class {new_name}", class_lines[0])] + class_lines[
        1:
    ]


def convert_member_lines(body_lines: list[str]) -> tuple[list[str], bool]:
    """Convert the lines inside a struct/union body -- fields, nested
    struct/union/enum blocks, and pass-through comments -- into Python
    lines for one class-body level (not yet indented)."""
    out: list[str] = []
    i = 0
    n = len(body_lines)

    while i < n:
        nested = try_convert_block(body_lines, i)
        if nested is not None:
            class_lines, next_i, var_name = nested
            if var_name:
                class_lines = rename_generic_class(class_lines, var_name)
            out.extend(class_lines)
            if var_name:
                out.append(instance_line(class_lines, var_name, annotated=True))
            i = next_i
            continue

        line = body_lines[i]
        if line.strip().startswith("#"):
            out.append(line.strip())
            i += 1
            continue

        for field_line in split_struct_body_lines([line]):
            parsed = parse_struct_field(field_line)
            if parsed:
                for item in parsed:
                    if isinstance(item, str):
                        out.append(item)
                    else:
                        out.append(
                            f"{item.name}: {item.annotation} = {item.default}{item.comment}"
                        )
        i += 1

    return out, bool(out)


def convert_struct_block(block: BlockInfo) -> list[str]:
    class_name = python_identifier(block.name or "CStruct")
    header_comment = block.comment
    if block.kind == "union" and not header_comment:
        header_comment = "  # NOTE: originally a C union"

    out = [f"class {class_name}:{header_comment}"]
    body_out, has_members = convert_member_lines(block.body)
    out.extend("    " + l for l in (body_out if has_members else ["pass"]))
    return out


def try_convert_block(
    lines: list[str], start_index: int
) -> tuple[list[str], int, str | None] | None:
    """If `lines[start_index]` opens (or entirely is) an enum/struct/union
    block, convert it and return (converted_lines, index_after_block,
    trailing_var_name). Otherwise None. `trailing_var_name` is set when the
    block is followed by a variable/field name rather than being purely a
    type declaration, e.g. the `inner` in `struct { ... } inner;`."""
    one_line = try_convert_one_line_block(lines[start_index])
    if one_line is not None:
        class_lines, var_name = one_line
        return class_lines, start_index + 1, var_name

    block = detect_block_start(lines[start_index])
    if not block:
        return None

    depth = 1  # the opening '{' consumed by detect_block_start

    for index in range(start_index + 1, len(lines)):
        depth += brace_delta(lines[index])
        end_name, end_comment = detect_block_end(lines[index])
        looks_like_close = end_name is not None or re.match(
            r"^\s*\}\s*;\s*", lines[index]
        )

        # Only treat this as the block's own closing brace once depth has
        # actually unwound to 0 -- otherwise a nested anonymous
        # struct/union's "} name;" line gets mistaken for the outer
        # block's end and everything after it (including the real closing
        # brace) leaks out as unconverted trailing text.
        if looks_like_close and depth == 0:
            var_name = None
            if block.is_typedef and end_name:
                block.name = end_name
            elif end_name:
                var_name = end_name
            block.comment = end_comment or ""

            converted = (
                convert_enum_block(block)
                if block.kind == "enum"
                else convert_struct_block(block)
            )
            return converted, index + 1, var_name

        block.body.append(lines[index])

    return (
        [f"# TODO: unterminated C {block.kind} block: {lines[start_index]}"],
        len(lines) + 1,
        None,
    )


# ---------------------------------------------------------------------------
# Function declaration / definition handling
# ---------------------------------------------------------------------------

# Multi-line-safe: matches a return type + name + "(params)" followed by
# either "{" (definition start) or ";" (prototype), all on one line, e.g.:
#   int add(int a, int b) {
#   char *get_name(void);
#   static unsigned int clamp(unsigned int v, unsigned int lo, unsigned int hi) {
FUNC_SIG_RE = re.compile(
    r"^(?P<quals>(?:static\s+|inline\s+|extern\s+)*)"
    r"(?P<rettype>[A-Za-z_][\w\s]*?)"
    r"\s*(?P<stars>\**)\s*"
    r"(?P<name>[A-Za-z_]\w*)\s*"
    r"\((?P<params>[^()]*)\)\s*"
    r"(?P<tail>\{|;)\s*$"
)

# Matches a complete function definition (signature + body) on one line:
#   int add(int a, int b){return a+b;}
ONE_LINE_FUNC_RE = re.compile(
    r"^(?P<quals>(?:static\s+|inline\s+|extern\s+)*)"
    r"(?P<rettype>[A-Za-z_][\w\s]*?)"
    r"\s*(?P<stars>\**)\s*"
    r"(?P<name>[A-Za-z_]\w*)\s*"
    r"\((?P<params>[^()]*)\)\s*"
    r"\{(?P<body>.*)\}\s*$"
)


def is_control_keyword_match(m: re.Match[str]) -> bool:
    return (
        m.group("rettype").strip() in CONTROL_KEYWORDS
        or m.group("name") in CONTROL_KEYWORDS
    )


def brace_delta(line: str) -> int:
    """Net change in brace depth contributed by this line's code (comments
    are ignored, so a converted `# note: {like this}` can't desync depth
    tracking). Not aware of braces inside string/char literals."""
    code, _ = split_python_comment(line)
    return code.count("{") - code.count("}")


def parse_function_params(params: str) -> list[tuple[str, str]]:
    """Return [(python_name, annotation), ...] for a C parameter list.
    `annotation` is "" for a bare variadic '...' (rendered as *args)."""
    params = params.strip()
    if params == "" or params == "void":
        return []

    result: list[tuple[str, str]] = []

    for i, raw in enumerate(split_top_level_commas(params)):
        raw = raw.strip()
        if raw == "":
            continue
        if raw == "...":
            result.append(("*args", ""))
            continue

        is_array = "[" in raw
        is_pointer = "*" in raw

        name_match = re.search(r"([A-Za-z_]\w*)\s*(\[[^\]]*\])?\s*$", raw)
        if name_match and name_match.group(1) not in C_TYPES.split("|"):
            name = python_identifier(name_match.group(1))
            base_type = raw[: name_match.start()]
        else:
            # Unnamed parameter (common in prototypes, e.g. "int, char*").
            name = f"arg{i}"
            base_type = raw

        annotation = c_base_type_to_annotation(
            base_type, is_pointer=is_pointer, is_array=is_array
        )
        if is_array and annotation != "str":
            annotation = "list"

        result.append((name, annotation))

    return result


def format_function_signature(
    name: str, params_str: str, rettype: str, is_ret_pointer: bool
) -> str:
    params = parse_function_params(params_str)
    ret_annotation = c_base_type_to_annotation(rettype, is_pointer=is_ret_pointer)

    parts = []
    for pname, annotation in params:
        parts.append(pname if pname == "*args" else f"{pname}: {annotation}")

    return f"def {python_identifier(name)}({', '.join(parts)}) -> {ret_annotation}:"


def try_convert_function(
    lines: list[str], start_index: int
) -> tuple[list[str], int] | None:
    """If `lines[start_index]` is a C function prototype/definition, convert
    it and return (converted_lines, index_after_block). Otherwise None."""
    code, comment = split_python_comment(lines[start_index])
    code = code.strip()

    one_line = ONE_LINE_FUNC_RE.match(code)
    if one_line and not is_control_keyword_match(one_line):
        signature = format_function_signature(
            one_line.group("name"),
            one_line.group("params"),
            one_line.group("rettype"),
            bool(one_line.group("stars")),
        )
        body = one_line.group("body").strip()
        out = [signature + comment]

        if not body:
            out.append("    pass")
        elif "{" in body:
            # A fully single-line definition whose body itself has nested
            # braces (e.g. an inline if/for) isn't line-based, so it falls
            # back to a manual-conversion note rather than being guessed at.
            out.append("    # TODO: manual conversion needed -- original C body:")
            out.append(f"    #     {body}")
            out.append("    pass")
        else:
            stmts = [s.strip() + ";" for s in split_top_level(body, ";") if s.strip()]
            converted = convert_c_body(stmts) if stmts else []
            out.extend("    " + l for l in (converted or ["pass"]))

        return out, start_index + 1

    m = FUNC_SIG_RE.match(code)
    if not m or is_control_keyword_match(m):
        return None

    signature = format_function_signature(
        m.group("name"), m.group("params"), m.group("rettype"), bool(m.group("stars"))
    )

    if m.group("tail") == ";":
        return [
            signature + comment,
            "    ...  # TODO: implement (from C prototype)",
        ], start_index + 1

    # tail == "{": scan forward, tracking brace depth, to find the matching '}'.
    body_lines: list[str] = []
    depth = brace_delta(lines[start_index])  # accounts for the opening '{' itself
    index = start_index + 1

    while index < len(lines) and depth > 0:
        depth += brace_delta(lines[index])
        if depth > 0:
            body_lines.append(lines[index])
        index += 1

    converted_body = convert_c_body(body_lines)
    out = [signature + comment]
    out.extend("    " + l for l in (converted_body or ["pass"]))

    return out, index


# ---------------------------------------------------------------------------
# Function-body statement conversion (best-effort, syntax-valid-only)
# ---------------------------------------------------------------------------


def paren_delta(s: str) -> int:
    return s.count("(") - s.count(")")


def split_close_brace_else(lines: list[str]) -> list[str]:
    """Split a `} else ...` (or `} else if (...) {`) line into a standalone
    `}` line plus its own `else ...` line, so the statement scanner can
    treat every `if`/`elif`/`else` as its own, independently dispatched
    line regardless of how the original C was formatted."""
    out: list[str] = []
    for line in lines:
        code, comment = split_python_comment(line)
        m = re.match(r"^(?P<closes>\}+)\s*(?P<rest>else\b.*)$", code.strip())
        if m:
            out.append(m.group("closes"))
            out.append(m.group("rest") + comment)
        else:
            out.append(line)
    return out


def join_header_continuations(lines: list[str]) -> list[str]:
    """Merge lines whose control-statement header (if/for/while/switch (...))
    spans multiple physical lines due to unbalanced parens, so each header
    ends up on one logical line for regex matching."""
    out: list[str] = []
    buf: str | None = None
    depth = 0

    for line in lines:
        code, _ = split_python_comment(line)
        delta = paren_delta(code)
        if buf is None:
            buf = line
            depth = delta
        else:
            buf += " " + line.strip()
            depth += delta
        if depth <= 0:
            out.append(buf)
            buf = None
            depth = 0

    if buf is not None:
        out.append(buf)

    return out


def matching_brace_end(lines: list[str], start: int) -> int:
    """`start` is the index right after an opening '{' whose own depth
    contribution has already been consumed. Returns the index of the line
    containing the matching '}'."""
    depth = 1
    i = start
    while i < len(lines):
        depth += brace_delta(lines[i])
        if depth == 0:
            return i
        i += 1
    return len(lines)


def match_ctrl_header(stripped: str) -> tuple[str, str | None, bool] | None:
    """Recognize an if/else-if/else/while/do/for/switch header line and
    return (kind, condition-or-header-text, has_opening_brace)."""
    m = re.match(r"^else\s+if\s*\((?P<cond>.*)\)\s*(?P<brace>\{)?\s*$", stripped)
    if m:
        return "elseif", m.group("cond"), bool(m.group("brace"))
    m = re.match(r"^else\s*(?P<brace>\{)?\s*$", stripped)
    if m:
        return "else", None, bool(m.group("brace"))
    m = re.match(r"^if\s*\((?P<cond>.*)\)\s*(?P<brace>\{)?\s*$", stripped)
    if m:
        return "if", m.group("cond"), bool(m.group("brace"))
    m = re.match(r"^while\s*\((?P<cond>.*)\)\s*(?P<brace>\{)?\s*$", stripped)
    if m:
        return "while", m.group("cond"), bool(m.group("brace"))
    m = re.match(r"^do\s*(?P<brace>\{)?\s*$", stripped)
    if m:
        return "do", None, bool(m.group("brace"))
    m = re.match(r"^for\s*\((?P<header>.*)\)\s*(?P<brace>\{)?\s*$", stripped)
    if m:
        return "for", m.group("header"), bool(m.group("brace"))
    m = re.match(r"^switch\s*\((?P<cond>.*)\)\s*(?P<brace>\{)?\s*$", stripped)
    if m:
        return "switch", m.group("cond"), bool(m.group("brace"))
    return None


def convert_increment_decrement(code: str) -> str | None:
    ident = r"[A-Za-z_]\w*(?:\[[^\]]*\]|\.[A-Za-z_]\w*|->[A-Za-z_]\w*)*"
    m = re.match(rf"^(?P<var>{ident})\s*(?P<op>\+\+|--)$", code)
    if not m:
        m = re.match(rf"^(?P<op>\+\+|--)(?P<var>{ident})$", code)
    if not m:
        return None
    op = "+=" if m.group("op") == "++" else "-="
    return f"{translate_c_tokens(m.group('var'))} {op} 1"


def try_convert_local_declaration(code: str) -> str | None:
    """Convert a local variable declaration (with an optional C type this
    doesn't recognize rejected via `looks_like_type`, so ordinary
    expression statements like function calls don't get misread as one)."""
    split_result = split_c_type_and_declarators(code)
    if not split_result:
        return None
    c_type, declarators = split_result
    if not looks_like_type(c_type):
        return None

    parts = []
    for declarator in split_top_level_commas(declarators):
        declarator = declarator.strip()
        if not declarator:
            continue

        eq_parts = split_top_level(declarator, "=")
        decl_part = eq_parts[0].strip()
        init_part = "=".join(eq_parts[1:]).strip() if len(eq_parts) > 1 else None

        name_match = re.search(r"([A-Za-z_]\w*)\s*(\[[^\]]*\])?\s*$", decl_part)
        if not name_match:
            return None

        name = python_identifier(name_match.group(1))
        annotation, default = map_c_field_type(c_type, decl_part)
        value = normalize_expr(init_part) if init_part else default
        parts.append(f"{name}: {annotation} = {value}")

    return "; ".join(parts) if parts else None


def convert_simple_statement(stmt: str) -> str:
    """Convert one ';'-terminated C statement (declaration, assignment,
    call, return/break/continue, or increment/decrement) into one Python
    line. Falls back to a normalized expression statement -- still only a
    syntax-level rewrite, so it may reference names that don't exist."""
    code, comment = split_python_comment(stmt)
    code = code.strip()
    if code.endswith(";"):
        code = code[:-1].strip()

    if code == "":
        return comment.strip() if comment.strip() else "pass"
    if code == "break":
        return "break" + comment
    if code == "continue":
        return "continue" + comment

    m_return = re.match(r"^return\s*(?P<expr>.*)$", code)
    if m_return:
        expr = m_return.group("expr").strip()
        return (f"return {normalize_expr(expr)}" if expr else "return") + comment

    decl = try_convert_local_declaration(code)
    if decl is not None:
        return decl + comment

    incr = convert_increment_decrement(code)
    if incr is not None:
        return incr + comment

    return normalize_expr(code) + comment


def convert_for_header(header: str, inner_lines: list[str]) -> list[str]:
    parts = split_top_level(header, ";")
    while len(parts) < 3:
        parts.append("")
    init_part, cond_part, incr_part = (p.strip() for p in parts[:3])

    body = convert_stmt_seq(inner_lines, 0, len(inner_lines))
    range_info = try_for_range(init_part, cond_part, incr_part)

    out: list[str] = []
    if range_info:
        var, start_expr, stop_expr, step_expr = range_info
        args = f"{start_expr}, {stop_expr}"
        if step_expr != "1":
            args += f", {step_expr}"
        out.append(f"for {var} in range({args}):")
        out.extend("    " + l for l in (body or ["pass"]))
        return out

    if init_part:
        out.extend(convert_stmt_seq([init_part + ";"], 0, 1))
    out.append(f"while {normalize_expr(cond_part) if cond_part else 'True'}:")
    loop_body = body[:]
    if incr_part:
        loop_body.extend(convert_stmt_seq([incr_part + ";"], 0, 1))
    out.extend("    " + l for l in (loop_body or ["pass"]))
    return out


def try_for_range(init: str, cond: str, incr: str) -> tuple[str, str, str, str] | None:
    """Recognize the common `for (T i = start; i < stop; i++)` shape and
    return (var, start, stop, step) for a Python `range()`. Anything else
    (descending loops, unrelated conditions, ...) falls back to a while-loop
    rewrite in the caller instead."""
    m_init = re.match(
        r"^(?:[A-Za-z_]\w*(?:\s+[A-Za-z_]\w*)*\s+)?([A-Za-z_]\w*)\s*=\s*(.+)$", init
    )
    if not m_init:
        return None
    var = m_init.group(1)
    start_expr = normalize_expr(m_init.group(2))

    m_cond = re.match(rf"^{re.escape(var)}\s*(<=|<)\s*(.+)$", cond)
    if not m_cond:
        return None
    stop_raw = normalize_expr(m_cond.group(2))
    stop_expr = stop_raw if m_cond.group(1) == "<" else f"{stop_raw} + 1"

    if re.match(rf"^{re.escape(var)}\s*\+\+\s*$", incr):
        step_expr = "1"
    else:
        m_incr = re.match(rf"^{re.escape(var)}\s*\+=\s*(.+)$", incr)
        if not m_incr:
            return None
        step_expr = normalize_expr(m_incr.group(1))

    return var, start_expr, stop_expr, step_expr


def convert_switch_body(body_lines: list[str]) -> list[str]:
    """Convert a switch body into `match`/`case` arms (Python 3.10+).
    Consecutive empty `case`/`default` labels are combined with `|`;
    fallthrough between non-empty cases (no `break`) isn't representable
    in `match`, so each case only gets its own statements."""
    groups: list[tuple[list[str | None], list[str]]] = []
    values: list[str | None] = []
    stmts: list[str] = []

    def flush() -> None:
        nonlocal values, stmts
        if values or stmts:
            groups.append((values, stmts))
        values = []
        stmts = []

    for line in body_lines:
        code, _ = split_python_comment(line)
        stripped = code.strip()
        m_case = re.match(r"^case\s+(.+?)\s*:\s*$", stripped)
        m_default = re.match(r"^default\s*:\s*$", stripped)

        if m_case:
            if stmts:
                flush()
            values.append(normalize_expr(m_case.group(1)))
        elif m_default:
            if stmts:
                flush()
            values.append(None)
        elif re.match(r"^break\s*;\s*$", stripped):
            continue
        else:
            stmts.append(line)

    flush()

    out: list[str] = []
    for group_values, group_stmts in groups:
        converted = convert_stmt_seq(group_stmts, 0, len(group_stmts))
        if any(v is None for v in group_values):
            pattern = "_"
        else:
            pattern = " | ".join(group_values) if group_values else "_"
        out.append(f"case {pattern}:")
        out.extend("    " + l for l in (converted or ["pass"]))

    return out


def convert_stmt_seq(lines: list[str], start: int, end: int) -> list[str]:
    """Convert a run of already comment/brace-preprocessed C statement
    lines (lines[start:end]) into Python source lines, recursing into any
    nested compound statements (if/while/for/do/switch/plain `{ }` blocks)."""
    out: list[str] = []
    i = start

    while i < end:
        code, comment = split_python_comment(lines[i])
        stripped = code.strip()

        if stripped == "":
            i += 1
            if comment.strip():
                out.append(comment.strip())
            continue

        if stripped.startswith("#"):
            out.append(stripped)
            i += 1
            continue

        if stripped == "{":
            close = matching_brace_end(lines, i + 1)
            out.extend(convert_stmt_seq(lines, i + 1, close))
            i = close + 1
            continue

        if stripped == "}":
            i += 1
            continue

        header = match_ctrl_header(stripped)
        if header is not None:
            kind, cond, has_brace = header

            if has_brace:
                body_start = i + 1
                body_end = matching_brace_end(lines, body_start)
                inner_lines = lines[body_start:body_end]
                next_i = body_end + 1
            else:
                inner_lines = [lines[i + 1]] if i + 1 < end else []
                next_i = i + 2

            if kind == "if":
                out.append(f"if {normalize_expr(cond)}:")
                out.extend(
                    "    " + l
                    for l in (
                        convert_stmt_seq(inner_lines, 0, len(inner_lines)) or ["pass"]
                    )
                )
            elif kind == "elseif":
                out.append(f"elif {normalize_expr(cond)}:")
                out.extend(
                    "    " + l
                    for l in (
                        convert_stmt_seq(inner_lines, 0, len(inner_lines)) or ["pass"]
                    )
                )
            elif kind == "else":
                out.append("else:")
                out.extend(
                    "    " + l
                    for l in (
                        convert_stmt_seq(inner_lines, 0, len(inner_lines)) or ["pass"]
                    )
                )
            elif kind == "while":
                out.append(f"while {normalize_expr(cond)}:")
                out.extend(
                    "    " + l
                    for l in (
                        convert_stmt_seq(inner_lines, 0, len(inner_lines)) or ["pass"]
                    )
                )
            elif kind == "do":
                body = convert_stmt_seq(inner_lines, 0, len(inner_lines))
                close_line = (
                    split_python_comment(lines[body_end])[0].strip()
                    if has_brace and body_end < end
                    else ""
                )
                m_end = re.match(r"^\}\s*while\s*\((?P<cond>.*)\)\s*;\s*$", close_line)
                do_cond = m_end.group("cond") if m_end else "False"
                out.append("while True:")
                out.extend("    " + l for l in (body or ["pass"]))
                out.append(f"    if not ({normalize_expr(do_cond)}):")
                out.append("        break")
            elif kind == "for":
                out.extend(convert_for_header(cond, inner_lines))
            elif kind == "switch":
                out.append(f"match {normalize_expr(cond)}:")
                case_lines = convert_switch_body(inner_lines)
                out.extend("    " + l for l in (case_lines or ["case _:", "    pass"]))

            i = next_i
            continue

        if re.match(r"^goto\s+\w+\s*;$", stripped) or re.match(r"^\w+\s*:$", stripped):
            out.append(f"# TODO: manual conversion needed (goto/label): {stripped}")
            i += 1
            continue

        parts = [p for p in split_top_level(stripped, ";") if p.strip()]
        for j, part in enumerate(parts):
            line_out = convert_simple_statement(part.strip() + ";")
            if j == len(parts) - 1 and comment.strip():
                line_out += comment
            out.append(line_out)
        i += 1

    return out


def convert_c_body(body_lines: list[str]) -> list[str]:
    """Best-effort conversion of a C function body into Python statements.
    Guaranteed to be syntactically valid Python; not guaranteed to run
    correctly, since it's a mechanical rewrite rather than a real compiler."""
    prepped = split_close_brace_else(body_lines)
    merged = join_header_continuations(prepped)
    return convert_stmt_seq(merged, 0, len(merged))


# ---------------------------------------------------------------------------
# Brace-initialized variable declarations
#   casm_t foo = {0};                 -> foo: casm_t = casm_t(0)
#   Point p = {.x = 1, .y = 2};       -> p: Point = Point(x=1, y=2)
#   Point pts[2] = {{1,2}, {3,4}};    -> pts: list = [Point(1, 2), Point(3, 4)]
#   int nums[3] = {1, 2, 3};          -> nums: list = [1, 2, 3]
# ---------------------------------------------------------------------------

VAR_BRACE_INIT_RE = re.compile(
    r"^(?P<quals>(?:static\s+|const\s+|volatile\s+|register\s+|struct\s+|enum\s+)*)"
    r"(?P<type>[A-Za-z_]\w*)\s*(?P<stars>\**)\s+"
    r"(?P<name>[A-Za-z_]\w*)\s*"
    r"(?P<array>\[[^\]]*\])?\s*"
    r"=\s*\{(?P<init>.*)\}\s*;\s*$"
)


def designated_initializer(entry: str) -> tuple[str, str] | None:
    """Match a C99 `.field = value` designated initializer entry."""
    m = re.match(r"^\.\s*([A-Za-z_]\w*)\s*=\s*(.+)$", entry)
    if m:
        return python_identifier(m.group(1)), m.group(2).strip()
    return None


def convert_initializer_entries(entries: list[str]) -> str | None:
    """Turn already-split initializer entries into a Python call-argument
    string, e.g. "1, 2" or "x=1, y=2" or "1, y=2". Returns None if an
    entry uses an indexed designator ([i] = ...), which isn't supported."""
    parts: list[str] = []

    for entry in entries:
        entry = entry.strip()
        if entry == "":
            continue
        if entry.startswith("["):
            return None  # indexed designator, e.g. [2] = 5 -- unsupported

        designated = designated_initializer(entry)
        if designated:
            field, value = designated
            parts.append(f"{field}={normalize_expr(value)}")
        else:
            parts.append(normalize_expr(entry))

    return ", ".join(parts)


def convert_brace_value(type_name: str, init_str: str, is_array: bool) -> str | None:
    entries = [e for e in split_top_level_commas(init_str) if e.strip() != ""]

    if is_array:
        # Array of nested compound literals: {{1,2}, {3,4}} -> [Type(1, 2), Type(3, 4)]
        if entries and all(
            e.strip().startswith("{") and e.strip().endswith("}") for e in entries
        ):
            elements = []
            for e in entries:
                inner = e.strip()[1:-1]
                converted = convert_initializer_entries(split_top_level_commas(inner))
                if converted is None:
                    return None
                elements.append(f"{type_name}({converted})")
            return "[" + ", ".join(elements) + "]"

        # Plain scalar array: {1, 2, 3} -> [1, 2, 3]
        converted = convert_initializer_entries(entries)
        if converted is None:
            return None
        return "[" + converted + "]"

    converted = convert_initializer_entries(entries)
    if converted is None:
        return None
    return f"{type_name}({converted})"


def try_convert_var_brace_init(line: str) -> list[str] | None:
    code, comment = split_python_comment(line)
    m = VAR_BRACE_INIT_RE.match(code.strip())
    if not m:
        return None

    type_name = python_identifier(m.group("type"))
    name = python_identifier(m.group("name"))
    is_array = m.group("array") is not None

    value = convert_brace_value(type_name, m.group("init"), is_array)
    if value is None:
        return [f"# TODO: manual conversion needed (indexed designator): {line}"]

    annotation = "list" if is_array else type_name
    return [f"{name}: {annotation} = {value}{comment}"]


# ---------------------------------------------------------------------------
# #define handling
# ---------------------------------------------------------------------------


def convert_define_line(line: str) -> list[str]:
    m = re.match(r"^\s*#\s*define\s+([A-Za-z_]\w*)\(([^)]*)\)\s*(.+)$", line)
    if m:
        name, args, value = m.group(1), m.group(2), m.group(3)
        expr, comment = split_python_comment(value)
        reason = unsupported_reason(expr)

        # Only a single C *expression* can become a lambda body. Anything
        # with statements (';'), a block ('{'), or multiple top-level
        # comma expressions isn't reliably one Python expression, so it
        # stays a manual-conversion TODO just like before.
        looks_like_statements = ";" in expr or "{" in expr or "}" in expr

        if reason or looks_like_statements:
            return [
                f"# TODO: skipped function-like macro '{name}', needs manual conversion: {line}"
            ]

        params = normalize_args(args)
        expr = normalize_expr(expr)
        lambda_sig = f"lambda {params}: " if params else "lambda: "
        return [f"{python_identifier(name)} = {lambda_sig}{expr}{comment}"]

    m = re.match(r"^\s*#\s*define\s+([A-Za-z_]\w*)\s+(.+)$", line)
    if m:
        name, value = m.group(1), m.group(2)
        expr, comment = split_python_comment(value)
        reason = unsupported_reason(expr)

        if reason:
            return [f"# TODO: manual conversion needed ({reason}): {line}"]

        expr = normalize_expr(expr)
        return [f"{python_identifier(name)} = {expr}{comment}"]

    return [line]


# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------


def convert_lines(lines: list[str]) -> list[str]:
    out: list[str] = []
    normalized_lines = convert_c_comments(join_continued_lines(lines))
    index = 0

    while index < len(normalized_lines):
        block_result = try_convert_block(normalized_lines, index)
        if block_result is not None:
            block_lines, next_index, var_name = block_result
            if var_name:
                block_lines = rename_generic_class(block_lines, var_name)
            out.extend(block_lines)
            if var_name:
                out.append(instance_line(block_lines, var_name, annotated=False))
            index = next_index
            continue

        func_result = try_convert_function(normalized_lines, index)
        if func_result is not None:
            block_lines, next_index = func_result
            out.extend(block_lines)
            index = next_index
            continue

        var_init = try_convert_var_brace_init(normalized_lines[index])
        if var_init is not None:
            out.extend(var_init)
            index += 1
            continue

        out.extend(convert_define_line(normalized_lines[index]))
        index += 1

    return out


def main() -> None:
    lines = sys.stdin.read().splitlines()
    sys.stdout.write("\n".join(convert_lines(lines)) + "\n")


if __name__ == "__main__":
    main()
