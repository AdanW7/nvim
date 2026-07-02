local M = {}

local python_keywords = {
  ['False'] = true,
  ['None'] = true,
  ['True'] = true,
  ['and'] = true,
  ['as'] = true,
  ['assert'] = true,
  ['async'] = true,
  ['await'] = true,
  ['break'] = true,
  ['class'] = true,
  ['continue'] = true,
  ['def'] = true,
  ['del'] = true,
  ['elif'] = true,
  ['else'] = true,
  ['except'] = true,
  ['finally'] = true,
  ['for'] = true,
  ['from'] = true,
  ['global'] = true,
  ['if'] = true,
  ['import'] = true,
  ['in'] = true,
  ['is'] = true,
  ['lambda'] = true,
  ['nonlocal'] = true,
  ['not'] = true,
  ['or'] = true,
  ['pass'] = true,
  ['raise'] = true,
  ['return'] = true,
  ['try'] = true,
  ['while'] = true,
  ['with'] = true,
  ['yield'] = true,
}

local function trim(s)
  return (s or ''):match('^%s*(.-)%s*$')
end

local function rtrim(s)
  return (s or ''):gsub('%s+$', '')
end

local function clean_block_comment_text(s)
  s = trim(s)
  s = s:gsub('^%*', '')
  return trim(s)
end

local function python_identifier(name)
  name = trim(name)

  if python_keywords[name] then
    return name .. '_'
  end

  return name
end

local function normalize_args(args)
  local out = {}

  for arg in (args .. ','):gmatch('([^,]*),') do
    arg = trim(arg)

    if arg ~= '' then
      table.insert(out, python_identifier(arg))
    end
  end

  return table.concat(out, ', ')
end

local function join_continued_lines(lines)
  local joined = {}
  local current = nil

  for _, line in ipairs(lines) do
    local continued = line:match('\\%s*$') ~= nil
    local part = line:gsub('\\%s*$', '')

    if current then
      current = current .. ' ' .. trim(part)
    else
      current = part
    end

    if not continued then
      table.insert(joined, current)
      current = nil
    end
  end

  if current then
    table.insert(joined, current)
  end

  return joined
end

local function strip_outer_parens(s)
  s = trim(s)

  while s:sub(1, 1) == '(' and s:sub(-1) == ')' do
    local depth = 0
    local wraps_whole_expr = true

    for i = 1, #s do
      local c = s:sub(i, i)

      if c == '(' then
        depth = depth + 1
      elseif c == ')' then
        depth = depth - 1

        if depth == 0 and i < #s then
          wraps_whole_expr = false
          break
        end
      end
    end

    if depth ~= 0 or not wraps_whole_expr then
      break
    end

    s = trim(s:sub(2, -2))
  end

  return s
end

local function strip_simple_identifier_parens(s)
  local previous

  repeat
    previous = s
    s = s:gsub('%(([A-Za-z_][A-Za-z0-9_]*)%)', '%1')
    s = s:gsub('%((0[xX]%x+)%)', '%1')
    s = s:gsub('%((%d+)%)', '%1')
  until s == previous

  return s
end

local function strip_c_int_suffixes(s)
  local function strip_suffix(number)
    return number:gsub('[uUlL]+$', '')
  end

  s = s:gsub('0[xX]%x+[uUlL]*', strip_suffix)
  s = s:gsub('%f[%d]%d+[uUlL]+%f[^%w_]', strip_suffix)

  return s
end

local function strip_c_casts(s)
  local c_types = 'u?int%d+_t|uint%d+_t|int%d+_t|size_t|bool|char|short|int|long|float|double'

  s = s:gsub('%((' .. c_types .. ')%)%s*%(([^%(%)]-)%)', '%2')
  s = s:gsub('%((' .. c_types .. ')%)%s*([A-Za-z_][A-Za-z0-9_]*)', '%2')

  return s
end

local function translate_c_tokens(expr)
  expr = expr:gsub('%f[%w_]NULL%f[^%w_]', 'None')
  expr = expr:gsub('%f[%w_]true%f[^%w_]', 'True')
  expr = expr:gsub('%f[%w_]false%f[^%w_]', 'False')
  expr = expr:gsub('%f[%w_]TRUE%f[^%w_]', 'True')
  expr = expr:gsub('%f[%w_]FALSE%f[^%w_]', 'False')
  expr = expr:gsub('&&', ' and ')
  expr = expr:gsub('%|%|', ' or ')
  expr = expr:gsub('!([^=])', ' not %1')

  return expr
end

local function find_top_level_ternary(expr)
  local depth = 0
  local question_pos = nil

  for i = 1, #expr do
    local c = expr:sub(i, i)

    if c == '(' then
      depth = depth + 1
    elseif c == ')' then
      depth = depth - 1
    elseif c == '?' and depth == 0 then
      question_pos = i
      break
    end
  end

  if not question_pos then
    return nil, nil
  end

  depth = 0

  for i = question_pos + 1, #expr do
    local c = expr:sub(i, i)

    if c == '(' then
      depth = depth + 1
    elseif c == ')' then
      depth = depth - 1
    elseif c == ':' and depth == 0 then
      return question_pos, i
    end
  end

  return nil, nil
end

local function convert_ternary(expr)
  expr = strip_outer_parens(expr)

  local question_pos, colon_pos = find_top_level_ternary(expr)

  if not question_pos then
    return expr
  end

  local condition = trim(expr:sub(1, question_pos - 1))
  local true_expr = trim(expr:sub(question_pos + 1, colon_pos - 1))
  local false_expr = trim(expr:sub(colon_pos + 1))

  condition = convert_ternary(strip_outer_parens(condition))
  true_expr = convert_ternary(strip_outer_parens(true_expr))
  false_expr = convert_ternary(strip_outer_parens(false_expr))

  return string.format('%s if %s else %s', true_expr, condition, false_expr)
end

local function split_python_comment(s)
  local before, comment = s:match('^(.-)%s+#%s*(.*)$')

  if before then
    return trim(before), ' # ' .. trim(comment)
  end

  return trim(s), ''
end

local normalize_expr

local function split_top_level_commas(s)
  local parts = {}
  local depth = 0
  local start_pos = 1

  for i = 1, #s do
    local c = s:sub(i, i)

    if c == '(' or c == '[' or c == '{' then
      depth = depth + 1
    elseif c == ')' or c == ']' or c == '}' then
      depth = depth - 1
    elseif c == ',' and depth == 0 then
      table.insert(parts, trim(s:sub(start_pos, i - 1)))
      start_pos = i + 1
    end
  end

  table.insert(parts, trim(s:sub(start_pos)))

  return parts
end

local function detect_block_start(line)
  local code = split_python_comment(line)
  local before_brace = code:match('^%s*(.-)%s*{%s*$')

  if not before_brace then
    return nil
  end

  local typedef_enum_name = before_brace:match('^typedef%s+enum%s+([A-Za-z_][A-Za-z0-9_]*)$')

  if typedef_enum_name then
    return { kind = 'enum', name = typedef_enum_name, is_typedef = true }
  end

  if before_brace:match('^typedef%s+enum%s*$') then
    return { kind = 'enum', is_typedef = true }
  end

  local enum_name = before_brace:match('^enum%s+([A-Za-z_][A-Za-z0-9_]*)$')

  if enum_name then
    return { kind = 'enum', name = enum_name, is_typedef = false }
  end

  local typedef_struct_name = before_brace:match('^typedef%s+struct%s+([A-Za-z_][A-Za-z0-9_]*)$')

  if typedef_struct_name then
    return { kind = 'struct', name = typedef_struct_name, is_typedef = true }
  end

  if before_brace:match('^typedef%s+struct%s*$') then
    return { kind = 'struct', is_typedef = true }
  end

  local struct_name = before_brace:match('^struct%s+([A-Za-z_][A-Za-z0-9_]*)$')

  if struct_name then
    return { kind = 'struct', name = struct_name, is_typedef = false }
  end

  return nil
end

local function detect_block_end(line)
  local code, comment = split_python_comment(line)
  local name = code:match('^%s*}%s*([A-Za-z_][A-Za-z0-9_]*)%s*;%s*$')

  if name then
    return name, comment
  end

  if code:match('^%s*}%s*;%s*$') then
    return nil, comment
  end

  return nil, nil
end

local function numeric_value(expr)
  expr = trim(expr)

  if expr:match('^0[xX]%x+$') then
    return tonumber(expr)
  end

  if expr:match('^%-?%d+$') then
    return tonumber(expr)
  end

  return nil
end

local function convert_enum_block(block)
  local out = {}
  local class_name = python_identifier(block.name or 'CEnum')
  local next_value = 0

  table.insert(out, string.format('class %s(Enum):%s', class_name, block.comment or ''))

  for _, line in ipairs(block.body) do
    local code, comment = split_python_comment(line)
    code = trim(code):gsub(',%s*$', '')

    if code ~= '' and code:sub(1, 1) ~= '#' then
      for _, entry in ipairs(split_top_level_commas(code)) do
        local entry_comment = ''
        entry = trim(entry):gsub(',%s*$', '')

        if entry ~= '' then
          local name, value = entry:match('^([A-Za-z_][A-Za-z0-9_]*)%s*=%s*(.+)$')

          if not name then
            name = entry:match('^([A-Za-z_][A-Za-z0-9_]*)$')
          end

          if name then
            if value then
              value = normalize_expr(value)
              local parsed_value = numeric_value(value)

              if parsed_value then
                next_value = parsed_value + 1
              else
                next_value = nil
              end
            elseif next_value then
              value = tostring(next_value)
              next_value = next_value + 1
            else
              value = '...'
              entry_comment = ' # TODO: fill enum value'
            end

            table.insert(out, string.format('    %s = %s%s%s', python_identifier(name), value, comment, entry_comment))
            comment = ''
          end
        end
      end
    elseif trim(line):sub(1, 1) == '#' then
      table.insert(out, '    ' .. trim(line))
    end
  end

  if #out == 1 then
    table.insert(out, '    pass')
  end

  return out
end

local function map_c_field_type(c_type, declarator)
  local normalized_type = trim(c_type)
    :gsub('%f[%w_]const%f[^%w_]', '')
    :gsub('%f[%w_]volatile%f[^%w_]', '')
    :gsub('%s+', ' ')
  local is_array = declarator:find('%[') ~= nil
  local is_pointer = declarator:find('%*') ~= nil

  if normalized_type:find('%f[%w_]bool%f[^%w_]') then
    return 'bool', 'False'
  end

  if normalized_type:find('%f[%w_]float%f[^%w_]') or normalized_type:find('%f[%w_]double%f[^%w_]') then
    return 'float', '0.0'
  end

  if normalized_type:find('%f[%w_]char%f[^%w_]') and (is_array or is_pointer) then
    return 'str', "''"
  end

  if is_array then
    return 'list', 'None'
  end

  if normalized_type:find('int') or normalized_type:find('%f[%w_]size_t%f[^%w_]') or normalized_type:find('%f[%w_]short%f[^%w_]') or normalized_type:find('%f[%w_]long%f[^%w_]') then
    return 'int', '0'
  end

  return 'object', 'None'
end

local function parse_struct_field(line)
  local code, comment = split_python_comment(line)
  code = trim(code):gsub(';%s*$', '')

  if code == '' or code:sub(1, 1) == '#' then
    return nil
  end

  if code:find('[{}]') then
    return { todo = '# TODO: manual conversion needed: ' .. line }
  end

  local c_type, declarators = code:match('^(.-)%s+(.+)$')

  if not c_type or not declarators then
    return { todo = '# TODO: manual conversion needed: ' .. line }
  end

  local fields = {}

  for _, declarator in ipairs(split_top_level_commas(declarators)) do
    local name = declarator:match('([A-Za-z_][A-Za-z0-9_]*)%s*%[[^%]]*%]%s*$')
      or declarator:match('%**%s*([A-Za-z_][A-Za-z0-9_]*)%s*$')

    if name then
      local annotation, default = map_c_field_type(c_type, declarator)

      table.insert(fields, {
        name = python_identifier(name),
        annotation = annotation,
        default = default,
        comment = comment,
      })
      comment = ''
    else
      table.insert(fields, { todo = '# TODO: manual conversion needed: ' .. line })
    end
  end

  return fields
end

local function convert_struct_block(block)
  local out = {}
  local fields = {}
  local todos = {}
  local class_name = python_identifier(block.name or 'CStruct')

  table.insert(out, string.format('class %s:%s', class_name, block.comment or ''))

  for _, line in ipairs(block.body) do
    if trim(line):sub(1, 1) == '#' then
      table.insert(todos, trim(line))
    else
      local parsed = parse_struct_field(line)

      if parsed then
        for _, field in ipairs(parsed) do
          if field.todo then
            table.insert(todos, field.todo)
          else
            table.insert(fields, field)
          end
        end
      end
    end
  end

  for _, todo in ipairs(todos) do
    table.insert(out, '    ' .. todo)
  end

  if #fields == 0 then
    table.insert(out, '    pass')
    return out
  end

  table.insert(out, '    def __init__(')
  table.insert(out, '        self,')

  for _, field in ipairs(fields) do
    table.insert(out, string.format('        %s: %s = %s,', field.name, field.annotation, field.default))
  end

  table.insert(out, '    ):')

  for _, field in ipairs(fields) do
    table.insert(out, string.format('        self.%s = %s%s', field.name, field.name, field.comment))
  end

  return out
end

local function try_convert_block(lines, start_index)
  local block = detect_block_start(lines[start_index])

  if not block then
    return nil, nil
  end

  block.body = {}

  for index = start_index + 1, #lines do
    local end_name, end_comment = detect_block_end(lines[index])

    if end_name or lines[index]:match('^%s*}%s*;%s*') then
      if block.is_typedef and end_name then
        block.name = end_name
      end

      block.comment = end_comment

      if block.kind == 'enum' then
        return convert_enum_block(block), index + 1
      end

      return convert_struct_block(block), index + 1
    end

    table.insert(block.body, lines[index])
  end

  return { '# TODO: unterminated C ' .. block.kind .. ' block: ' .. lines[start_index] }, #lines + 1
end

local function convert_c_comments(lines)
  local converted = {}
  local in_block_comment = false

  for _, line in ipairs(lines) do
    local out = ''
    local comments = {}
    local rest = line

    while rest ~= '' do
      if in_block_comment then
        local close_start = rest:find('*/', 1, true)

        if close_start then
          local comment_text = clean_block_comment_text(rest:sub(1, close_start - 1))
          if comment_text ~= '' then
            table.insert(comments, comment_text)
          end
          rest = rest:sub(close_start + 2)
          in_block_comment = false
        else
          local comment_text = clean_block_comment_text(rest)
          if comment_text ~= '' then
            table.insert(comments, comment_text)
          end
          rest = ''
        end
      else
        local block_start = rest:find('/*', 1, true)
        local slash_start = rest:find('//', 1, true)

        if slash_start and (not block_start or slash_start < block_start) then
          out = out .. rest:sub(1, slash_start - 1)
          local comment_text = trim(rest:sub(slash_start + 2))
          if comment_text ~= '' then
            table.insert(comments, comment_text)
          end
          rest = ''
        elseif block_start then
          out = out .. rest:sub(1, block_start - 1)
          rest = rest:sub(block_start + 2)
          in_block_comment = true
        else
          out = out .. rest
          rest = ''
        end
      end
    end

    out = rtrim(out)

    if #comments > 0 then
      if trim(out) == '' then
        table.insert(converted, '# ' .. table.concat(comments, ' '))
      else
        table.insert(converted, out .. ' # ' .. table.concat(comments, ' '))
      end
    elseif trim(out) == '' and in_block_comment then
      table.insert(converted, '#')
    else
      table.insert(converted, out)
    end
  end

  return converted
end

function normalize_expr(expr)
  expr = strip_c_int_suffixes(expr)
  expr = strip_c_casts(expr)
  expr = strip_outer_parens(expr)
  expr = strip_c_casts(expr)
  expr = strip_outer_parens(expr)
  expr = translate_c_tokens(expr)
  expr = convert_ternary(expr)
  expr = strip_simple_identifier_parens(expr)
  expr = trim(expr):gsub('%s+', ' ')

  return expr
end

local function unsupported_reason(expr)
  if expr:find('sizeof%s*%(') then
    return 'sizeof needs manual conversion'
  end

  if expr:find('%-%>') or expr:find('%.') then
    return 'C member access needs manual conversion'
  end

  return nil
end

local function convert_define_line(line)
  local fn_name, args, fn_value = line:match('^%s*#%s*define%s+([A-Za-z_][A-Za-z0-9_]*)%(([^)]*)%)%s*(.+)$')

  if fn_name then
    local expr, comment = split_python_comment(fn_value)
    local reason = unsupported_reason(expr)

    if reason then
      return { '# TODO: manual conversion needed (' .. reason .. '): ' .. line }
    end

    expr = normalize_expr(expr)

    return {
      string.format('def %s(%s):%s', python_identifier(fn_name), normalize_args(args), comment),
      string.format('    return %s', expr),
    }
  end

  local name, value = line:match('^%s*#%s*define%s+([A-Za-z_][A-Za-z0-9_]*)%s+(.+)$')

  if name then
    local expr, comment = split_python_comment(value)
    local reason = unsupported_reason(expr)

    if reason then
      return { '# TODO: manual conversion needed (' .. reason .. '): ' .. line }
    end

    expr = normalize_expr(expr)

    return { string.format('%s: Final = %s%s', python_identifier(name), expr, comment) }
  end

  return { line }
end

function M.convert_lines(lines)
  local out = {}
  local normalized_lines = convert_c_comments(join_continued_lines(lines))
  local index = 1

  while index <= #normalized_lines do
    local block_lines, next_index = try_convert_block(normalized_lines, index)

    if block_lines then
      for _, converted_line in ipairs(block_lines) do
        table.insert(out, converted_line)
      end

      index = next_index
    else
      local line = normalized_lines[index]
    local converted = convert_define_line(line)

    for _, converted_line in ipairs(converted) do
      table.insert(out, converted_line)
    end

      index = index + 1
    end
  end

  return out
end

function M.setup()
  if not vim or not vim.api then
    error('c_define_to_python.setup() must be called from Neovim')
  end

  vim.api.nvim_create_user_command('CDefineToPython', function(opts)
    local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
    local out = M.convert_lines(lines)

    vim.api.nvim_buf_set_lines(0, opts.line1 - 1, opts.line2, false, out)
  end, {
    range = '%',
  })
end

return M
