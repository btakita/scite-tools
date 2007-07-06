--[[
  Mitchell's functions.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- Source language functions functions for the scite module.
-- There are a couple options variables used:
--   USER_LIST_NUM: The integer to use for SciTE's UserListShow function.
--   KEYWORD_STYLE: The integer style for keywords.
module('modules.scite.functions', package.seeall)

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

--- Identified functions in the current buffer.
local function_table = {}

---
-- SciTE Lua OnUserListSelection extension function.
-- Jumps to the function the user has chosen from a list of functions.
function _G.OnUserListSelection(list, text)
  if list == USER_LIST_NUM then
    local line = get_line(text)
    if line then editor:GotoPos(line) end
  end
end

-- local functions
local update_function_table

---
-- Displays all identified functions in the current source file as a user list
-- the user can select from to 'jump' to a specific function.
-- @param func_def The language-specific keyword used to define a function.
--   ('def' for Ruby, 'function' for Lua, etc.)
function show(func_def)
  update_function_table(func_def)
  local list, list_str = {}, ''
  for k in pairs(function_table) do list[#list + 1] = k end
  table.sort(list)
  for _, v in ipairs(list) do list_str = list_str..v..';' end
  if list_str == '' then return end
  local sep = editor.AutoCSeparator
  editor.AutoCSeparator = string.byte(';')
  list_str = list_str:sub(1, #list_str - 1)
  editor:UserListShow(USER_LIST_NUM, list_str)
  editor.AutoCSeparator = sep
end

---
-- If the function declaration specified exists, return its line number.
-- @param name The function declaration. This function is generally called by
--   OnUserListSelection to 'jump' to a function.
function get_line(name)
  if not function_table[name] then return nil end
  return function_table[name].pos
end

---
-- If possible, display the arguments of the function to the left of the caret.
-- (FIXME: this is not very reliable.)
-- @param func_def The language-specific keyword used to define a function.
--   ('def' for Ruby, 'function' for Lua, etc.)
function show_args(func_def)
  local pos = editor.CurrentPos
  if editor.CharAt[pos - 1] == string.byte('(') then pos = pos - 1 end
  local func_start = editor:WordStartPosition(pos)
  local func = editor:textrange(func_start, pos)
  local s, e = editor:findtext(func_def..' '..func)
  if s and e then
    local line = editor:GetLine( editor:LineFromPosition(s) )
    local params = line:match('(%b())')
    if params == nil then params = 'No params' end
    editor:CallTipShow(editor.CurrentPos, params)
  end
end

---
-- [Local function] Searches through the current buffer to identify functions
-- to 'jump' to.
-- @param func_def The language-specific keyword used to define a function.
--   ('def' for Ruby, 'function' for Lua, etc.)
update_function_table = function(func_def)
  function_table = {}
  local patt = func_def..'%s+(([%w_]+)%s*%(?.*%)?)'
  for match in editor:match(func_def..' .+', SCFIND_REGEXP) do
    local signature, name = match.text:match(patt)
    if signature and name and
      editor.StyleAt[match.pos] == KEYWORD_STYLES[editor.Lexer] then
      function_table[signature] = { pos = match.pos, name = name }
    end
  end
end
