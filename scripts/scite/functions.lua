--[[
  Mitchell's functions.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Source language functions functions for the SciTE "bundle"

  API (see functions for descriptions):
    - Functions.show(function_def_string)
    - Functions.get_line(function_name)
    - Functions.show_args(function_def_string)

  Note: function_def_string would be 'def' for Ruby,
    'function' for Lua, etc.
]]--

-- options
local USER_LIST_NUM = 10
local KEYWORD_STYLES = {
  -- [SCLEX_PYTHON] = 5,
  -- [SCLEX_CPP]    = 5,
  [SCLEX_HTML]      = 121,
  -- [SCLEX_PERL]   = 5,
  [SCLEX_LUA]       = 5,
  [SCLEX_RUBY]      = 5,
  -- [SCLEX_BASH]   = 4
}
-- end options

local function_table = {}
-- local functions
local update_function_table

-- goto selected function
function OnUserListSelection(list, text)
  if list == USER_LIST_NUM then
    local line = Functions.get_line(text)
    if line then editor:GotoPos(line) end
  end
end

-- get all functions in the current source file
update_function_table = function(func_def)
  function_table = {}
  local pat = func_def..'%s+(([%w_]+)%s*%(?.*%)?)'
  for match in editor:match(func_def..' .+', SCFIND_REGEXP) do
    local _, _, signature, name = string.find(match.text, pat)
    if signature and name and editor.StyleAt[match.pos] ==
        KEYWORD_STYLES[editor.Lexer] then
      function_table[signature] = { pos = match.pos, name = name }
    end
  end
end

Functions = {}

-- displays all functions in the current source file
function Functions.show(func_def)
  update_function_table(func_def)
  local list, list_str = {}, ''
  for k,_ in pairs(function_table) do table.insert(list, k) end
  table.sort(list)
  for _,v in ipairs(list) do list_str = list_str..v..';' end
  if list_str == '' then return end
  local sep = editor.AutoCSeparator
  editor.AutoCSeparator = string.byte(';')
  list_str = string.sub( list_str, 0, string.len(list_str) - 1 )
  editor:UserListShow(USER_LIST_NUM, list_str)
  editor.AutoCSeparator = sep
end

-- returns line number the function declaration is on
function Functions.get_line(name)
  if function_table[name] == nil then return nil end
  return function_table[name].pos
end

-- displays arguments of the function to the left of the cursor
function Functions.show_args(func_def)
  local pos = editor.CurrentPos
  if editor.CharAt[pos - 1] == string.byte('(') then
    pos = pos - 1
  end
  local func_start = editor:WordStartPosition(pos)
  local func = editor:textrange(func_start, pos)
  local s, e = editor:findtext(func_def..' '..func)
  if s and e then
    local line = editor:GetLine( editor:LineFromPosition(s) )
    local _, _, params = string.find(line, '(%(.+%))')
    if params == nil then params = 'No params' end
    editor:CallTipShow(editor.CurrentPos, params)
  end
end
