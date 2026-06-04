[
  "any"
  "anyOf"
  "allOf"
  "bool"
  "enum"
  "false"
  "float"
  "int"
  "map"
  "not"
  "null"
  "oneOf"
  "string"
  "struct"
  "true"
  "uint"
  "union"
  "extends"
] @keyword

; Operators and punctuation
["$" "!" "?" "*" "|" "^" "&" "~" "not"] @operator
["," ":" "=" "."] @punctuation.delimiter
["(" ")" "[" "]" "{" "}"] @punctuation.bracket

(primitive_type) @type.builtin
(identifier) @variable
(named_declaration name: (identifier) @type.definition)

(comment) @comment
(string) @string
(integer) @number
(float) @number.float

; Struct / object keys
(field name: (identifier) @property)
(field name: (string) @property)
(pattern_field pattern: (string) @property.definition)
(tagged_branch name: (identifier) @property)
(member_access name: (_) @property)

; Enum variants
(enum_variant name: (identifier) @constant)

; Annotations
(annotation "@" @punctuation.special)
(annotation name: (identifier) @attribute)
(annotation name: (identifier) @keyword.conditional
  (#any-of? @keyword.conditional "if" "then" "else"))

; Schema metadata block
(metadata_declaration "$" @variable.builtin)
(metadata_declaration name: (identifier) @namespace)
(metadata_field name: (identifier) @property.definition)
(metadata_field value: (json_value (string)) @string.special)

; Root declaration
(root_declaration "$" @variable.builtin)


(ERROR) @error
