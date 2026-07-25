"""Convert an IAR EWARM compilation database to clangd-compatible JSON.

The converter is dependency-free and can be shared independently of Neovim.
It reads JSON from stdin and writes converted JSON to stdout:

    python iar_to_clang_compdb.py < compile_commands.json > clang_commands.json
    python iar_to_clang_compdb.py --compiler clangd < compile_commands.json

It can also split a multi-config database into clangd database directories:

    python iar_to_clang_compdb.py --split compile_commands.json
    python iar_to_clang_compdb.py --split compile_commands.json --out-root .clangd-db --flat

Use ``--fragment`` when stdin contains one or more comma-separated entries
selected from inside a JSON array rather than a complete database:

    python iar_to_clang_compdb.py --fragment < selected_entries.json

Conversion is idempotent. IAR ``iccarm`` entries are normalized, while already
standard ``arguments`` or ``command`` entries are preserved.

Requires Python 3.11 or newer.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from enum import StrEnum
from pathlib import Path, PurePath
from typing import Any


class Compiler(StrEnum):
    """Compiler family used in generated compilation database entries."""

    IAR = "iar"
    CLANGD = "clangd"
    GCC = "gcc"

    @classmethod
    def detect(cls, arguments: Any) -> Compiler | None:
        """Identify a compiler family from a compilation database argument list."""
        if not isinstance(arguments, list) or not arguments:
            return None

        executable = str(arguments[0]).replace("\\", "/").rsplit("/", 1)[-1].lower()
        if executable in {"iccarm", "iccarm.exe"}:
            return cls.IAR
        if executable in {"clang", "clang.exe", "clang++", "clang++.exe"}:
            return cls.CLANGD
        if executable in {
            "gcc",
            "gcc.exe",
            "g++",
            "g++.exe",
            "arm-none-eabi-gcc",
            "arm-none-eabi-gcc.exe",
            "arm-none-eabi-g++",
            "arm-none-eabi-g++.exe",
        }:
            return cls.GCC
        return None

    @staticmethod
    def is_cpp(file_path: str) -> bool:
        return PurePath(file_path).suffix.lower() in CPP_SUFFIXES

    def driver_for(self, file_path: str) -> str:
        """Return this compiler family's C or C++ driver for ``file_path``.

        ``CLANGD`` emits clang/clang++ because clangd consumes compile
        commands; clangd itself is not a compiler driver.
        """
        is_cpp = self.is_cpp(file_path)
        if self is Compiler.GCC:
            return "arm-none-eabi-g++" if is_cpp else "arm-none-eabi-gcc"
        if self is Compiler.CLANGD:
            return "clang++" if is_cpp else "clang"
        return "iccarm"

    @property
    def preserves_iar_arguments(self) -> bool:
        return self is Compiler.IAR

    def command_prefix(self, file_path: str) -> list[str]:
        prefix = [self.driver_for(file_path)]
        if not self.preserves_iar_arguments:
            prefix.append("--target=arm-none-eabi")
        return prefix


class ArmCpu(StrEnum):
    """ARM CPU spellings accepted by GCC and Clang compiler drivers."""

    CORTEX_M0 = "cortex-m0"
    CORTEX_M0PLUS = "cortex-m0plus"
    CORTEX_M1 = "cortex-m1"
    CORTEX_M23 = "cortex-m23"
    CORTEX_M3 = "cortex-m3"
    CORTEX_M4 = "cortex-m4"
    CORTEX_M33 = "cortex-m33"
    CORTEX_M35P = "cortex-m35p"
    CORTEX_M55 = "cortex-m55"
    CORTEX_M7 = "cortex-m7"

    @classmethod
    def from_iar(cls, iar_name: str) -> ArmCpu:
        normalized = iar_name.lower().replace("+", "plus")
        try:
            return cls(normalized)
        except ValueError as error:
            supported = ", ".join(cpu.iar_name for cpu in cls)
            raise ValueError(
                f"unsupported IAR CPU {iar_name!r}; supported CPUs: {supported}"
            ) from error

    @property
    def iar_name(self) -> str:
        suffix = self.value.removeprefix("cortex-").replace("m0plus", "M0+")
        return f"Cortex-{suffix if suffix == 'M0+' else suffix.upper()}"

    @property
    def compiler_flag(self) -> str:
        return f"-mcpu={self.value}"


# Change this one line to select a different default for library and CLI use.
DEFAULT_COMPILER = Compiler.GCC

CPP_SUFFIXES = {".cc", ".cp", ".cxx", ".cpp", ".c++"}
SOURCE_SUFFIXES = CPP_SUFFIXES | {".c"}


def _source_suffix(path: str) -> str:
    return PurePath(path).suffix.lower()


class IarArgumentTranslator:
    """Translate IAR compiler arguments for one target compiler family."""

    FLAG_MAP = {
        "--cpu_mode=thumb": ["-mthumb"],
        "--fpu=VFPv4_sp": ["-mfpu=fpv4-sp-d16"],
        "--char_is_unsigned": ["-funsigned-char"],
        "--no_rtti": ["-fno-rtti"],
        "--no_exceptions": ["-fno-exceptions"],
    }
    DROPPED_FLAGS = {
        "--c++",
        "--silent",
        "--debug",
        "--endian=little",
        "--no_path_in_file_macros",
        "--warnings_are_errors",
        "--fpu=None",
        "-e",
        "-Oh",
        "-Ohs",
        "-Ohz",
        "-On",
        "--use_c++_inline",
        "--no_cse",
        "--no_unroll",
        "--no_inline",
        "--no_code_motion",
        "--no_static_destruction",
        "--no_tbaa",
        "--no_clustering",
        "--no_scheduling",
    }
    DROPPED_PAIRED_FLAGS = {
        "--preprocess=s",
        "--dlib_config",
        "--diag_suppress",
        "--mfc",
        "-o",
    }

    def __init__(self, compiler: Compiler) -> None:
        self.compiler = compiler

    @staticmethod
    def _operand(arguments: list[Any], index: int, flag: str) -> str:
        if index + 1 >= len(arguments):
            raise ValueError(f"{flag} is missing its operand")
        return str(arguments[index + 1])

    def translate(self, entry: dict[str, Any]) -> list[str]:
        arguments = entry["arguments"]
        converted = self.compiler.command_prefix(str(entry["file"]))
        index = 1

        while index < len(arguments):
            argument = str(arguments[index])

            if argument in self.DROPPED_PAIRED_FLAGS:
                self._operand(arguments, index, argument)
                index += 2
                continue
            if argument == "--preinclude":
                converted.extend(
                    ["-include", self._operand(arguments, index, argument)]
                )
                index += 2
                continue
            if argument.startswith("--preinclude="):
                operand = argument.partition("=")[2]
                if not operand:
                    raise ValueError("--preinclude= is missing its operand")
                converted.extend(["-include", operand])
            elif (
                argument.startswith("--diag_suppress=")
                or argument in self.DROPPED_FLAGS
            ):
                pass
            elif argument.startswith("--cpu="):
                converted.append(
                    ArmCpu.from_iar(argument.partition("=")[2]).compiler_flag
                )
            else:
                converted.extend(self.FLAG_MAP.get(argument, [argument]))
            index += 1

        return converted


class CompilationDatabaseConverter:
    """Convert IAR compilation database entries without performing file I/O."""

    def __init__(self, compiler: Compiler = DEFAULT_COMPILER) -> None:
        self.compiler = compiler
        self.argument_translator = IarArgumentTranslator(compiler)

    def convert_entry(self, value: Any) -> dict[str, Any] | None:
        if not isinstance(value, dict):
            return None

        file_path = value.get("file")
        if (
            not isinstance(file_path, str)
            or _source_suffix(file_path) not in SOURCE_SUFFIXES
        ):
            return None
        if value.get("type", "COMPILER") != "COMPILER":
            return None

        if Compiler.detect(value.get("arguments")) is Compiler.IAR:
            if self.compiler.preserves_iar_arguments:
                return self._without_type(value)

            converted: dict[str, Any] = {
                "directory": str(value.get("directory", "")),
                "arguments": self.argument_translator.translate(value),
                "file": file_path,
            }
            if value.get("output") not in (None, ""):
                converted["output"] = value["output"]
            return converted

        if isinstance(value.get("arguments"), list) or isinstance(
            value.get("command"), str
        ):
            return self._without_type(value)
        return None

    def convert_database(self, values: Any) -> list[dict[str, Any]]:
        if not isinstance(values, list):
            raise ValueError("compilation database must be a JSON array")
        return [
            entry
            for value in values
            if (entry := self.convert_entry(value)) is not None
        ]

    def convert_fragment(self, text: str) -> str:
        indent = _leading_indent(text)
        stripped = text.strip()
        trailing_comma = stripped.endswith(",")
        if trailing_comma:
            stripped = stripped[:-1].rstrip()

        try:
            parsed = json.loads(stripped)
        except json.JSONDecodeError:
            parsed = json.loads(f"[{stripped}]")

        if isinstance(parsed, dict):
            entry = self.convert_entry(parsed)
            converted = [] if entry is None else [entry]
        elif isinstance(parsed, list):
            converted = self.convert_database(parsed)
        else:
            raise ValueError("selected JSON must contain compilation database entries")

        rendered = ",\n".join(
            _indent(json.dumps(entry, indent=2), indent) for entry in converted
        )
        if trailing_comma and rendered:
            rendered += ","
        return rendered + "\n"

    def convert_text(self, text: str, *, fragment: bool = False) -> str:
        if fragment:
            return self.convert_fragment(text)
        return json.dumps(self.convert_database(json.loads(text)), indent=2) + "\n"

    @staticmethod
    def _without_type(entry: dict[str, Any]) -> dict[str, Any]:
        converted = dict(entry)
        converted.pop("type", None)
        return converted


def _leading_indent(text: str) -> str:
    for line in text.splitlines():
        if line.strip():
            return line[: len(line) - len(line.lstrip())]
    return ""


def _indent(text: str, prefix: str) -> str:
    return "\n".join(prefix + line if line else line for line in text.splitlines())


def convert_arguments(
    entry: dict[str, Any], compiler: Compiler = DEFAULT_COMPILER
) -> list[str]:
    """Compatibility delegate for translating one IAR argument array."""
    return IarArgumentTranslator(compiler).translate(entry)


def convert_entry(
    value: Any, compiler: Compiler = DEFAULT_COMPILER
) -> dict[str, Any] | None:
    """Compatibility delegate for converting one database entry."""
    return CompilationDatabaseConverter(compiler).convert_entry(value)


def convert_database(
    values: Any, compiler: Compiler = DEFAULT_COMPILER
) -> list[dict[str, Any]]:
    """Compatibility delegate for converting a parsed database."""
    return CompilationDatabaseConverter(compiler).convert_database(values)


def convert_fragment(text: str, compiler: Compiler = DEFAULT_COMPILER) -> str:
    """Compatibility delegate for converting selected JSON entries."""
    return CompilationDatabaseConverter(compiler).convert_fragment(text)


def convert_text(
    text: str,
    *,
    fragment: bool = False,
    compiler: Compiler = DEFAULT_COMPILER,
) -> str:
    return CompilationDatabaseConverter(compiler).convert_text(text, fragment=fragment)


class CompilationDatabaseSplitter:
    """Detect CMake configurations and write independent clangd databases."""

    OUTPUT_CONFIG_RE = re.compile(r"CMakeFiles[/\\][^/\\]+\.dir[/\\]([^/\\]+)")
    COMMAND_CONFIG_RE = re.compile(r'CMAKE_INTDIR=\\?"([^"\\]+)\\?"')

    def __init__(
        self,
        input_path: Path,
        out_root: Path,
        *,
        also_write_flat_files: bool = False,
    ) -> None:
        self.input_path = input_path
        self.out_root = out_root
        self.also_write_flat_files = also_write_flat_files

    @classmethod
    def entry_config(cls, value: Any) -> str | None:
        if not isinstance(value, dict):
            return None

        output = value.get("output")
        if isinstance(output, str) and (match := cls.OUTPUT_CONFIG_RE.search(output)):
            return match.group(1)

        command = value.get("command")
        if isinstance(command, str) and (
            match := cls.COMMAND_CONFIG_RE.search(command)
        ):
            return match.group(1)
        return None

    def split(self) -> list[str]:
        values = json.loads(self.input_path.read_text(encoding="utf-8-sig"))
        if not isinstance(values, list):
            raise ValueError("compilation database must be a JSON array")

        configs = sorted(
            {config for value in values if (config := self.entry_config(value))}
        )
        if not configs:
            return self._write_single_database(values)
        return self._write_config_databases(values, configs)

    def _write_single_database(self, values: list[Any]) -> list[str]:
        output_path = self.out_root / "compile_commands.json"
        self._write_database(output_path, values)
        return [
            "No config metadata found; copied active compile database.",
            f"Wrote {len(values):4d} entries -> {output_path}",
        ]

    def _write_config_databases(
        self, values: list[Any], configs: list[str]
    ) -> list[str]:
        messages = ["Discovered configs: " + ", ".join(configs)]
        for config in configs:
            self._validate_config_name(config)
            config_values = (
                values
                if len(configs) == 1
                else self._last_entry_per_file(
                    [value for value in values if self.entry_config(value) == config]
                )
            )
            config_path = self.out_root / config / "compile_commands.json"
            self._write_database(config_path, config_values)
            messages.append(f"Wrote {len(config_values):4d} entries -> {config_path}")

            if self.also_write_flat_files:
                flat_path = self.input_path.parent / f"compile_commands.{config}.json"
                self._write_database(flat_path, config_values)
                messages.append(f"                 -> {flat_path}")
        return messages

    @staticmethod
    def _validate_config_name(config: str) -> None:
        if config in {".", ".."}:
            raise ValueError(f"unsafe configuration name: {config!r}")

    @staticmethod
    def _last_entry_per_file(values: list[Any]) -> list[Any]:
        """Match jq's ``reverse | unique_by(.file) | reverse`` behavior."""
        seen: set[Any] = set()
        selected: list[Any] = []
        for value in reversed(values):
            file_path = value.get("file") if isinstance(value, dict) else None
            if file_path not in seen:
                seen.add(file_path)
                selected.append(value)
        selected.reverse()
        return selected

    @staticmethod
    def _write_database(path: Path, values: list[Any]) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(values, indent=2) + "\n", encoding="utf-8")


def split_database(
    input_path: Path, out_root: Path, *, also_write_flat_files: bool = False
) -> list[str]:
    """Compatibility delegate for splitting a compilation database."""
    return CompilationDatabaseSplitter(
        input_path,
        out_root,
        also_write_flat_files=also_write_flat_files,
    ).split()


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--fragment",
        action="store_true",
        help="convert selected entry objects rather than a complete JSON array",
    )
    parser.add_argument(
        "--split",
        type=Path,
        metavar="COMPILE_COMMANDS",
        help="split a compilation database file by detected configuration",
    )
    parser.add_argument(
        "--out-root",
        type=Path,
        default=Path(".clangd-db"),
        help="split output root (default: .clangd-db)",
    )
    parser.add_argument(
        "--flat",
        action="store_true",
        help="also write compile_commands.CONFIG.json beside the input file",
    )
    parser.add_argument(
        "--compiler",
        type=Compiler,
        choices=list(Compiler),
        default=DEFAULT_COMPILER,
        help=f"generated compiler family (default: {DEFAULT_COMPILER})",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        if args.split is not None:
            messages = split_database(
                args.split,
                args.out_root,
                also_write_flat_files=args.flat,
            )
            print("\n".join(messages))
        else:
            sys.stdout.write(
                convert_text(
                    sys.stdin.read(),
                    fragment=args.fragment,
                    compiler=args.compiler,
                )
            )
    except (json.JSONDecodeError, KeyError, OSError, TypeError, ValueError) as error:
        print(f"iar_to_clang_compdb: {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
