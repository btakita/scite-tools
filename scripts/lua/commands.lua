--[[
  Mitchell's lua/commands.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Commands for the Lua "bundle"
]]--

-- regexes for auto 'end' completion
Lua.regexes = {
  '^%s*for', '^%s*function', '^%s*if', '^%s*repeat', '^%s*while',
  'function%s*%(.*%)%s*$', '^%s*local%s*function'
}

-- autocomplete 'end' for if, while, for, etc.
function Lua.try_to_autocomplete_end()
  editor:BeginUndoAction()
  editor:LineEnd() editor:NewLine()
  local line_num = editor:LineFromPosition(editor.CurrentPos)
  local line = editor:GetLine(line_num - 1)
  for _, regex in ipairs(Lua.regexes) do
    if string.find(line, regex) then
      local indent = editor.LineIndentation[line_num - 1]
      if string.find(regex, 'repeat') then
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

-- goto file being 'require'd
function Lua.goto_required()
  local line = editor:GetLine(
    editor:LineFromPosition(editor.CurrentPos) )
  local _, _, _, filename = string.find(line,
    '^.*require%s*([\'"])(.-)%1.*$')
  for path in string.gfind(LUA_PATH..';', '(.-);') do
    path = string.gsub(path, '?', filename)
    local f = io.open(path)
    if f then f:close() scite.Open(path) break end
  end
end

-- Lua-specific key commands
if type(keys) == 'table' then
  keys[SCLEX_LUA].ac = {
    f = {
      l = { Functions.show,      'function' },
      a = { Functions.show_args, 'function' },
    },
    g = { Lua.goto_required }
  }
  keys[SCLEX_LUA]['s\n'] = { Lua.try_to_autocomplete_end }
end
