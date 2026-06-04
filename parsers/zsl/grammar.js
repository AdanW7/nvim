/* eslint-disable */
/// <reference types="tree-sitter-cli/zsl" />
//@ts-check
module.exports = grammar({
  name: 'zsl',
  extras: $ => [/[\s\r\n\t]/, $.comment],
  word: $ => $.identifier,
  conflicts: $ => [
    [$.array_type, $.tuple_type],
    [$.field, $.pattern_field],
    [$.primitive_type, $.literal],
    [$.array_bound, $.literal],
    [$.annotation, $.atom_type],
    [$.annotation_arg, $.atom_type],

    [$.json_value, $.literal],
    [$.json_value, $.primitive_type, $.literal],
    [$.json_object, $.object_type],
    [$.json_array, $.tuple_type],
    [$.json_value, $.array_bound, $.literal],
  ],
  rules: {
    source_file: $ => repeat($.declaration),

    declaration: $ => choice(
      $.root_declaration,
      $.metadata_declaration,
      $.named_declaration,
    ),
    root_declaration: $ => seq('$', '=', field('value', $.type_expr)),
    metadata_declaration: $ => seq(
      '$', field('name', $.identifier), '=',
      field('value', $.metadata_object),
    ),
    named_declaration: $ => seq(field('name', $.identifier), '=', field('value', $.type_expr)),

    // --- Metadata ---
    metadata_object: $ => seq('{', optional(commaSep($.metadata_field)), '}'),
    metadata_field: $ => seq(field('name', $.identifier), ':', field('value', $.json_value)),

    // --- JSON values (for annotations and metadata) ---
    json_value: $ => choice(
      $.string,
      $.integer,
      $.float,
      'true',
      'false',
      'null',
      $.json_array,
      $.json_object,
    ),
    json_array: $ => seq('[', optional(commaSep($.json_value)), ']'),
    json_object: $ => seq('{', optional(commaSep($.json_object_field)), '}'),
    json_object_field: $ => seq(
      field('name', choice($.identifier, $.string)),
      ':',
      field('value', $.json_value),
    ),

    // --- Type expressions ---
    type_expr: $ => $.required_type,
    required_type: $ => choice(seq('!', $.union_type), $.union_type),
    union_type: $ => prec.left(1, seq($.oneof_type, repeat(seq('|', $.oneof_type)))),
    oneof_type: $ => prec.left(2, seq($.intersection_type, repeat(seq('^', $.intersection_type)))),
    intersection_type: $ => prec.left(3, seq($.nullable_type, repeat(seq('&', $.nullable_type)))),
    nullable_type: $ => choice(seq('?', $.nullable_type), $.prefix_type),
    prefix_type: $ => choice(seq('not', $.prefix_type), $.array_type, $.tuple_type, $.postfix_type),
    postfix_type: $ => seq($.atom_type, repeat(choice($.member_access, $.annotation))),
    member_access: $ => seq('.', field('name', choice($.identifier, $.format_identifier))),

    // Annotation args: named (key: value/type), positional value, or positional type_expr
    annotation: $ => seq(
      '@',
      field('name', $.identifier),
      optional(seq(
        '(',
        optional(commaSep($.annotation_arg)),
        ')',
      )),
    ),
    annotation_arg: $ => choice(
      seq(field('key', $.identifier), ':', field('val', choice($.json_value, $.type_expr))),
      $.json_value,
      $.type_expr,
    ),

    atom_type: $ => choice(
      $.primitive_type,
      $.literal,
      $.identifier,
      $.object_type,
      $.map_type,
      $.enum_type,
      $.union_block,
      $.combinator_block,
      $.extends_type,
      seq('(', $.type_expr, ')'),
    ),

    primitive_type: _ => choice('bool', 'int', 'uint', 'float', 'string', 'null', 'any'),

    array_type: $ => seq('[', optional($.array_bound), ']', $.nullable_type),
    array_bound: $ => choice(
      $.integer,
      seq(optional($.integer), ':', optional($.integer)),
    ),

    tuple_type: $ => seq('[', optional(commaSep(choice($.type_expr, $.tuple_rest))), ']'),
    tuple_rest: $ => seq('...', optional($.type_expr)),

    object_type: $ => seq(
      optional('struct'),
      optional($.open_marker),
      '{',
      optional(commaSep(choice($.field, $.pattern_field))),
      '}',
    ),
    open_marker: $ => seq('*', optional(seq('[', $.type_expr, ']'))),
    field: $ => seq(field('name', choice($.identifier, $.string)), ':', field('value', $.type_expr)),
    pattern_field: $ => seq('~', field('pattern', $.string), ':', field('value', $.type_expr)),

    map_type: $ => seq(token(prec(1, 'map')), '{', $.type_expr, optional(seq(':', $.type_expr)), '}'),

    enum_type: $ => seq(
      'enum', '(', field('backing', $.primitive_type), ')',
      '{', optional(commaSep($.enum_variant)), '}',
    ),
    enum_variant: $ => seq(field('name', $.identifier), optional(seq('=', field('value', $.literal)))),

    union_block: $ => seq(
      'union',
      optional(seq('(', $.identifier, ',', choice($.string, $.identifier), ')')),
      '{', optional(commaSep(choice($.tagged_branch, $.type_expr))), '}',
    ),
    tagged_branch: $ => seq(field('name', $.identifier), ':', field('value', $.type_expr)),

    combinator_block: $ => seq(
      choice('anyOf', 'oneOf', 'allOf'),
      '{', optional(commaSep($.type_expr)), '}',
    ),

    // extends BaseType { extra_fields }
    extends_type: $ => seq(
      'extends',
      field('base', $.type_expr),
      field('body', $.object_type),
    ),

    literal: $ => choice($.string, $.integer, $.float, 'true', 'false', 'null'),
    comment: _ => token(seq('#', /.*/)),
    identifier: _ => /[A-Za-z_][A-Za-z0-9_]*/,
    format_identifier: _ => /[A-Za-z_][A-Za-z0-9_-]*/,
    integer: _ => /-?(0|[1-9][0-9]*)/,
    float: _ => /-?([0-9]+\.[0-9]+([eE][+-]?[0-9]+)?|[0-9]+[eE][+-]?[0-9]+)/,
    string: _ => /"([^"\\\n]|\\(["\\\/bfnrt]|u[0-9A-Fa-f]{4}))*"/,
  }
});

function commaSep(rule) {
  return seq(rule, repeat(seq(',', rule)), optional(','));
}
