--[[
  Mitchell's ruby/commands.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- Commands for the ruby module.
-- There are several option variables used:
--   PLATFORM: OS platform (linux or windows).
--   FILE_IN: Location of the temporary file used as STDIN for
--     various operations.
--   FILE_OUT: Location of the temporary file that will contain
--     output for various operations.
--   REDIRECT: The command line symbol used for redirecting STDOUT
--     to a file.
module('modules.ruby.commands', package.seeall)

-- platform-specific options
local PLATFORM = PLATFORM or 'linux'
local FILE_IN, FILE_OUT, REDIRECT
if PLATFORM == 'linux' then
  FILE_IN  = '/tmp/scite_input'
  FILE_OUT = '/tmp/scite_output'
  REDIRECT = ' &> '
elseif PLATFORM == 'windows' then
  FILE_IN  = os.getenv('TEMP')..'\scite_input.txt'
  FILE_OUT = os.getenv('TEMP')..'\scite_output.txt'
  REDIRECT = ' > '
end
-- end options

--- Patterns for auto 'end' completion for control structures.
-- @class table
-- @name control_structure_patterns
-- @see try_to_autocomplete_end
local control_structure_patterns = {
  '^%s*begin', '^%s*case',  '^%s*class',  '^%s*def',
  '^%s*for',   '^%s*if',    '^%s*module', '^%s*unless',
  '^%s*until', '^%s*while', 'do%s*|*.*|*%s*$'
}

---
-- Try to autocomplete Lua's 'end' keyword for control structures
-- like 'if', 'while', 'for', etc.
-- @see control_structure_patterns
function try_to_autocomplete_end()
  editor:BeginUndoAction()
  editor:LineEnd() editor:NewLine()
  local line_num = editor:LineFromPosition(editor.CurrentPos)
  local line = editor:GetLine(line_num - 1)
  for _, regex in ipairs(control_structure_patterns) do
    if string.find(line, regex) then
      local indent = editor.LineIndentation[line_num - 1]
      editor:AddText('\nend')
      editor.LineIndentation[line_num + 1] = indent
      editor.LineIndentation[line_num] = indent + editor.Indent
      editor:LineUp()
      break
    end
  end
  editor:EndUndoAction()
end

---
-- Determine the Ruby file being 'require'd, and search through
-- the RUBYPATH for that file and open it in SciTE.
function goto_required()
  local line = editor:GetLine(
    editor:LineFromPosition(editor.CurrentPos) )
  local _, _, _, filename = string.find(line,
    '^%s*require%s*([\'"])(.-)%1.*$')
  os.execute("ruby -e 'puts $:'"..REDIRECT..FILE_OUT)
  local f = io.open(FILE_OUT)
  for path in f:lines() do
    path = path..'/'..filename..'.rb'
    local f2 = io.open(path)
    if f2 then f2:close() scite.Open(path) break end
  end
  f:close()
end

---
-- Perform method autocompletion via rcodetools.
-- WARNING: rcodetools EXECUTES code to do its method completion.
function autocomplete(char)
  editor:AddText(char)
  local txt = editor:GetText()
  local f = io.open(FILE_IN, 'w') f:write(txt) f:close()
  local line = editor:LineFromPosition(editor.CurrentPos) + 1
  local col  = editor.Column[editor.CurrentPos]
  os.execute('rct-complete --line='..line..' --column='..col..
    ' '..FILE_IN..REDIRECT..FILE_OUT)
  f = io.open(FILE_OUT) txt = f:read('*all') f:close()
  if not string.find(txt, '^[^\n]-:%d+:in') then
    local sep = string.char(editor.AutoCSeparator)
    txt = string.gsub(txt, '[^%w_?!\n]+\n?', '') -- word methods
    txt = string.gsub(txt, '\n+$', '') -- remove trailing \n's
    txt = string.gsub(txt, '\n', sep)  -- create completion list
    editor:AutoCShow(0, txt)
  else
    _, _, txt = string.find(txt, '(undefined.-\')')
    print(txt)
  end
end

---
-- Print ri documentation via rcodetools to the SciTE output pane.
function ri_doc()
  local pos = editor.CurrentPos
  if editor.CharAt[pos - 1] == 40 then pos = pos - 1 end -- '('
  local txt = editor:GetText()
  local f = io.open(FILE_IN, 'w') f:write(txt) f:close()
  local line = editor:LineFromPosition(pos) + 1
  local col  = editor.Column[pos]
  os.execute('rct-doc --line='..line..' --column='..col..
    ' '..FILE_IN..REDIRECT..FILE_OUT)
  f = io.open(FILE_OUT) txt = f:read('*all') f:close()
  _, _, txt = string.find(txt, '^(.-)\n')
  os.execute('ri "'..txt..'"'..REDIRECT..FILE_OUT)
  f = io.open(FILE_OUT) txt = f:read('*all') f:close()
  if not string.find(txt, '^[^\n]-:%d+:in') then
    txt = string.gsub(txt, '\n+$', '')
    editor:CallTipShow(editor.CurrentPos, txt)
  else print(txt) end
end

---
-- Toggles between brace and do..end style Ruby blocks.
-- If no text is selected, the single-line brace style block is
-- assumed to be on the current line. It is converted into a
-- do..end style block. If text is selected, the entire lines
-- the beginning and end of the selection are on are searched
-- for a 'do' and 'end'. When found, they are replaced by braces.
function toggle_block()
  editor:BeginUndoAction()
  if editor:GetSelText() == '' then
    editor:LineEnd()
    local match_pos = editor:BraceMatch(editor.CurrentPos - 1)
    if match_pos > 0 then
      editor:SetSel(match_pos, editor.CurrentPos)
      local line = editor:LineFromPosition(editor.CurrentPos)
      local code = editor:GetSelText()
      code = string.gsub(code, '^{%s*(|.-|)%s*(.-)%s*}$',
        'do %1\n  %2\nend')
      editor:ReplaceSel(code)
      local indent = editor.LineIndentation[line]
      editor.LineIndentation[line + 1] = indent + editor.Indent
      editor.LineIndentation[line + 2] = indent
      if string.find(code, '\n  \nend$') then editor:LineUp() end
    end
  else
    local pos1, pos2 = editor.CurrentPos, editor.Anchor
    if pos1 > pos2 then pos1, pos2 = pos2, pos1 end
    local s, _ = editor:findtext('do', 0, pos1)
    if s < pos2 then
      editor:SetSel(s, pos2)
      local code = editor:GetSelText()
      code = string.gsub(code, '^do%s*(|.-|)%s*(.-)%s*end$',
        '{ %1 %2 }')
      editor:ReplaceSel(code)
      if string.find(code, '  }$') then
        editor:CharLeft() editor:CharLeft()
      end
    end
  end
  editor:EndUndoAction()
end

-- Ruby-specific key commands
local keys = _G.keys
if type(keys) == 'table' then
  local m_functions = modules.scite.functions
  keys[SCLEX_RUBY].ac = {
    f = {
      l = { m_functions.show,      'def' },
      a = { m_functions.show_args, 'def' },
    },
    t = { toggle_block  },
    g = { goto_required }
  }
  keys[SCLEX_RUBY]['s\n'] = { try_to_autocomplete_end }
  keys[SCLEX_RUBY]['cs?'] = { ri_doc                  }
  keys[SCLEX_RUBY][SCE_RB_STRING] = {
    ['s#'] = { modules.scite.snippets.insert, '#{${0}}' }
  }
end
