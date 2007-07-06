--[[
  Mitchell's lua/commands.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- Commands for the lua module.
module('modules.lua.commands', package.seeall)

---
-- Patterns for auto 'end' completion for control structures.
-- @class table
-- @name control_structure_patterns
-- @see try_to_autocomplete_end
local control_structure_patterns = {
  '^%s*for', '^%s*function', '^%s*if', '^%s*repeat', '^%s*while',
  'function%s*%b()%s*$', '^%s*local%s*function'
}

---
-- Try to autocomplete Lua's 'end' keyword for control structures like 'if',
-- 'while', 'for', etc.
-- @see control_structure_patterns
function try_to_autocomplete_end()
  editor:BeginUndoAction()
  editor:LineEnd() editor:NewLine()
  local line_num = editor:LineFromPosition(editor.CurrentPos)
  local line = editor:GetLine(line_num - 1)
  for _, patt in ipairs(control_structure_patterns) do
    if line:match(patt) then
      local indent = editor.LineIndentation[line_num - 1]
      if patt:match('repeat') then
        editor:AddText('\nuntil')
      else
        editor:AddText('\nend')
      end
      editor.LineIndentation[line_num + 1] = indent
      editor.LineIndentation[line_num] = indent + editor.Indent
      editor:LineUp()
      break
    end
  end
  editor:EndUndoAction()
end

---
-- Determine the Lua file being 'require'd, and search through package.path for
-- that file and open it in SciTE.
function goto_required()
  local line = editor:GetLine( editor:LineFromPosition(editor.CurrentPos) )
  local patterns = { 'require%s*(%b())', 'require%s*(([\'"])[^%2]+%2)' }
  local file
  for _, patt in ipairs(patterns) do
    file = line:match(patt)
    if file then break end
  end
  file = loadstring('return '..file)()
  for path in package.path:gmatch('[^;]+') do
    path = path:gsub('?', file)
    local f = io.open(path)
    if f then f:close() scite.Open(path) break end
  end
end

-- Lua-specific key commands
local keys = _G.keys
if type(keys) == 'table' then
  local m_functions = modules.scite.functions
  keys[SCLEX_LUA].ac = {
    f = {
      l = { m_functions.show,      'function' },
      a = { m_functions.show_args, 'function' },
    },
    g = { goto_required }
  }
  keys[SCLEX_LUA]['s\n'] = { try_to_autocomplete_end }
end
