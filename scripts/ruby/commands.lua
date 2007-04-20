--[[
  Mitchell's ruby/commands.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Commands for the Ruby "bundle"
]]--

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

-- toggles between single and multi-line Ruby blocks
function Ruby.toggle_block()
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

-- regexes for auto 'end' completion
Ruby.regexes = {
  '^%s*begin', '^%s*case',  '^%s*class',  '^%s*def',
  '^%s*for',   '^%s*if',    '^%s*module', '^%s*unless',
  '^%s*until', '^%s*while', 'do%s*|*.*|*%s*$'
}

-- autocomplete 'end' for if, unless, do, etc.
function Ruby.try_to_autocomplete_end()
  editor:BeginUndoAction()
  editor:LineEnd() editor:NewLine()
  local line_num = editor:LineFromPosition(editor.CurrentPos)
  local line = editor:GetLine(line_num - 1)
  for _, regex in ipairs(Ruby.regexes) do
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

-- goto file being 'require'd on current line
function Ruby.goto_required()
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

-- method autocompletion via rcodetools
function Ruby.autocomplete(char)
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

-- ri documentation via rcodetools
function Ruby.ri_doc()
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

-- Ruby-specific key commands
if type(keys) == 'table' then
  keys[SCLEX_RUBY].ac = {
    f = {
      l = { Functions.show,      'def' },
      a = { Functions.show_args, 'def' },
    },
    t = { Ruby.toggle_block  },
    g = { Ruby.goto_required }
  }
  keys[SCLEX_RUBY]['s\n'] = { Ruby.try_to_autocomplete_end }
  -- keys[SCLEX_RUBY]['.']   = { Ruby.autocomplete, '.'       }
  keys[SCLEX_RUBY]['cs?'] = { Ruby.ri_doc                  }
  keys[SCLEX_RUBY]['s:']  = { function()
    if editor.CharAt[editor.CurrentPos - 1] == 58 then -- ::
      Ruby.autocomplete(':')
      return true
    end
    return false
  end }
  keys[SCLEX_RUBY][SCE_RB_STRING] = {
    ['s#'] = { Snippets.insert, '#{${0}}' }
  }
end
