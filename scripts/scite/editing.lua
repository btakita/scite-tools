--[[
  Mitchell's editing.lua
  Copyright (c) 2006 Mitchell Foral. All rights reserved.
  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Editing commands for the SciTE "bundle"

  API (see functions for descriptions):
    - Editing.smart_cutcopy(action=cut)
    - Editing.smart_paste(action=paste)
    - Editing.current_word(action=select)
    - Editing.transpose_char
    - Editing.squeeze(char)
    - Editing.join_lines
    - Editing.move_line
    - Editing.enclose(enclosure)
    - Editing.select_enclosed(enclosure)
    - Editing.select_line
    - Editing.select_paragraph
    - Editing.select_indented_block
    - Editing.select_scope
    - Editing.ruby_exec
    - Editing.lua_exec
    - Editing.reformat_paragraph
    - Editing.convert(what) [commented out]
    - Editing.goto_ctag [commented out]
]]--

-- platform specific options
local PLATFORM = PLATFORM or 'linux'
local FILE_IN, FILE_OUT, REDIRECT, RUBY_CMD, FMTP_CMD
if PLATFORM == 'linux' then
  FILE_IN  = '/tmp/scite_input'
  FILE_OUT = '/tmp/scite_output'
  REDIRECT = ' &> '
  RUBY_CMD = 'ruby '
  FMTP_CMD = 'fmt -c -w 66 '
elseif PLATFORM == 'windows' then
  FILE_IN  = os.getenv('TEMP')..'\\scite_input.rb'
  FILE_OUT = os.getenv('TEMP')..'\\scite_output.txt'
  REDIRECT = ' > '
  RUBY_CMD = 'ruby '
end
-- end options

-- for kill-ring
local kill_ring = { pos = 1, maxn = 10 }

-- for matching enclosures
local char_matches = {
  ['('] = ')', ['['] = ']', ['{'] = '}',
  ["'"] = "'", ['"'] = '"'
}

-- for enclosing text or selecting text in enclosures
-- note chars and tag enclosures are generated on the fly
local enclosure = {
  dbl_quotes = { left = '"', right = '"' },
  sng_quotes = { left = "'", right = "'" },
  parens     = { left = '(', right = ')' },
  brackets   = { left = '[', right = ']' },
  braces     = { left = '{', right = '}' },
  chars      = { left = ' ', right = ' ' },
  tags       = { left = '>', right = '<' },
  tag        = { left = ' ', right = ' ' },
  single_tag = { left = '<', right = ' />' }
}

-- local functions
local insert_into_kill_ring, scroll_kill_ring
local get_preceding_number, get_sel_or_line

-- matches enclosure characters
function OnChar(c)
  if char_matches[c] then
    editor:InsertText( -1, char_matches[c] )
  end
end

Editing = {}

-- selects to end of line if no text is currently selected and
-- pushes it to the kill-ring before cutting (default) or copying
function Editing.smart_cutcopy(action)
  local txt = editor:GetSelText()
  if string.len(txt) == 0 then editor:LineEndExtend() end
  txt = editor:GetSelText()
  insert_into_kill_ring(txt)
  kill_ring.pos = 1
  if action ~= 'copy' then editor:Cut() return end
  editor:Copy()
  insert_into_kill_ring(txt)
end

-- retrieves top item off kill-ring, or scrolls through it
-- if no args, does standard paste from current item in kill-ring
-- if arg is 'cycle', starts cycling through previous cuts/copies
-- if arg is 'reverse', cycles in reverse order
function Editing.smart_paste(...)
  local anchor, pos = editor.Anchor, editor.CurrentPos
  if pos < anchor then anchor = pos end
  local txt = editor:GetSelText()
  if txt == kill_ring[kill_ring.pos] then
    scroll_kill_ring( arg[1] )
  end

  -- if text was copied to the clipboard from other apps, insert
  -- it into the kill-ring so it can be pasted (thanks to Nathan
  -- Robinson)
  local clip_txt, found = scite.GetClipboardText(), false
  if clip_txt ~= '' then
    for _, ring_txt in ipairs(kill_ring) do
      if clip_txt == ring_txt then found = true break end
    end
    if not found then insert_into_kill_ring(clip_txt) end
  end

  txt = kill_ring[kill_ring.pos]
  if txt then
    editor:ReplaceSel(txt)
    if arg[1] then editor.Anchor = anchor end -- cycle
  end
end

-- selects or deletes word under cursor
function Editing.current_word(action)
  local s = editor:WordStartPosition(editor.CurrentPos)
  local e = editor:WordEndPosition(editor.CurrentPos)
  editor:SetSel(s, e)
  if action == 'delete' then editor:DeleteBack() end
end

-- if at the end of the current word, transposes the two chars
-- before the caret; otherwise transposes char to the left of the
-- caret with the current one
function Editing.transpose_chars()
  editor:BeginUndoAction()
  local pos  = editor.CurrentPos
  local char = editor.CharAt[pos - 1]
  editor:DeleteBack()
  if pos > editor.Length or editor.CharAt[pos - 1] == 32 then
    editor:CharLeft()
  else
    editor:CharRight()
  end
  editor:InsertText( -1, string.char(char) )
  editor:SetSel(pos, pos)
  editor:EndUndoAction()
end

-- reduces multiple character occurances to the left of the
-- cursor to just one; if char is not given, the character under
-- the cursor is used
function Editing.squeeze(char)
  if not char then char = editor.CharAt[editor.CurrentPos - 1] end
  local s, e = editor.CurrentPos - 1, editor.CurrentPos - 1
  while editor.CharAt[s] == char do s = s - 1 end
  while editor.CharAt[e] == char do e = e + 1 end
  editor:SetSel(s + 1, e)
  editor:ReplaceSel( string.char(char) )
end


-- joins current line with line below, eliminating whitespace
function Editing.join_lines()
  editor:BeginUndoAction()
  editor:LineEnd() editor:Clear() editor:AddText(' ')
  Editing.squeeze()
  editor:EndUndoAction()
end

-- moves current line up or down
function Editing.move_line(direction)
  local column = editor.Column[editor.CurrentPos]
  editor:BeginUndoAction()
  if direction == 'up' then
    editor:LineTranspose()
    editor:LineUp()
  elseif direction == 'down' then
    editor:LineDown()
    editor:LineTranspose()
    column = editor.CurrentPos + column -- starts at line home
    editor:SetSel(column, column)
  end
  editor:EndUndoAction()
end

-- encloses text in an enclosure set
-- if there is text selected, it is enclosed; otherwise the
-- previous word is enclosed
-- multiple previous words can be enclosed by appending a number
-- to the end of the last word (e.g. enclose this2); if enclosing
-- with multiple characters, the same rule applies (e.g. this**2)
function Editing.enclose(str)
  editor:BeginUndoAction()
  local txt = editor:GetSelText()
  if txt == '' then
    if str == 'chars' then
      local num_chars, len_num_chars = get_preceding_number()
      for i = 1, len_num_chars do editor:DeleteBack() end
      for i = 1, num_chars do editor:CharLeftExtend() end
      enclosure[str].left  = editor:GetSelText()
      enclosure[str].right = enclosure[str].left
      editor:DeleteBack()
    end
    local num_words, len_num_chars = get_preceding_number()
    for i = 1, len_num_chars do editor:DeleteBack() end
    for i = 1, num_words do editor:WordLeftExtend() end
    txt = editor:GetSelText()
  end
  local len = 0
  if str == 'tag' then
    enclosure[str].left  = '<'..txt..'>'
    enclosure[str].right = '</'..txt..'>'
    len = string.len(txt) + 3 txt = ''
  end
  local left  = enclosure[str].left
  local right = enclosure[str].right
  editor:ReplaceSel(left..txt..right)
  if str == 'tag' then editor:GotoPos(editor.CurrentPos - len) end
  editor:EndUndoAction()
end

-- selects text in a specified enclosure; if none specified,
-- searches for matching character pairs defined in char_matches
-- from the inside out
function Editing.select_enclosed(str)
  if str then
    editor:SearchAnchor(editor.CurrentPos)
    local s = editor:SearchPrev( 0, enclosure[str].left )
    local e = editor:SearchNext( 0, enclosure[str].right )
    if s and e then editor:SetSel(s + 1, e) end
  else
    -- TODO: ignore enclosures in comment scopes?
    s, e = editor.Anchor, editor.CurrentPos
    if s > e then s, e = e, s end
    local char = string.char( editor.CharAt[s - 1] )
    if s ~= e and char_matches[char] then
      s, e = s - 2, e + 1 -- don't match the same enclosure
    end
    while s >= 0 do
      char = string.char( editor.CharAt[s] )
      if char_matches[char] then
        local _, e = editor:findtext( char_matches[char], 0, e )
        if e then editor:SetSel(s + 1, e - 1) break end
      end
      s = s - 1
    end
  end
end

-- select current line
function Editing.select_line()
  editor:Home() editor:LineEndExtend()
end

-- select current paragraph (delimited by newlines)
function Editing.select_paragraph()
  editor:ParaUp() editor:ParaDownExtend()
end

-- if no block of text is selected, selects block of text with
-- the current indentation; otherwise if border lines are both
-- one level of indentation up, they are added to the selection;
-- else acts like no block of text is selected
function Editing.select_indented_block()
  local s = editor:LineFromPosition(editor.Anchor)
  local e = editor:LineFromPosition(editor.CurrentPos)
  if s > e then s, e = e, s end
  local indent = editor.LineIndentation[s] - editor.Indent
  if indent < 0 then return end
  if editor:GetSelText() ~= '' then
    if editor.LineIndentation[s - 1] == indent and
      editor.LineIndentation[e + 1] == indent then
      s, e = s - 1, e + 1
      indent = indent + editor.Indent -- don't run while loops
    end
  end
  while editor.LineIndentation[s - 1] > indent do s = s - 1 end
  while editor.LineIndentation[e + 1] > indent do e = e + 1 end
  s = editor:PositionFromLine(s)
  e = editor.LineEndPosition[e]
  editor:SetSel(s, e)
end

-- selects text in scope (style) under cursor
function Editing.select_scope()
  local start_pos = editor.CurrentPos
  local base_style = editor.StyleAt[start_pos]
  local pos = start_pos - 1
  while editor.StyleAt[pos] == base_style do pos = pos - 1 end
  local start_style = pos
  pos = start_pos + 1
  while editor.StyleAt[pos] == base_style do pos = pos + 1 end
  editor:SetSel(start_style + 1, pos)
end

-- executes line or selection as Ruby code
function Editing.ruby_exec()
  local txt = get_sel_or_line()
  local f, out
  -- write the file
  f = io.open(FILE_IN, 'w') f:write(txt) f:close()
  -- check the syntax
  os.execute(RUBY_CMD..'-cw '..FILE_IN..REDIRECT..FILE_OUT)
  f = io.open(FILE_OUT) out = f:read('*all') f:close()
  -- execute the file
  if out == 'Syntax OK\n' then
    os.execute(RUBY_CMD..FILE_IN..REDIRECT..FILE_OUT)
    f = io.open(FILE_OUT) out = f:read('*all') f:close()
    if string.sub(out, -1) == '\n' then
      out = string.sub(out, 1, -2) -- chomp
    end
  end
  editor:ReplaceSel(out)
end

-- executes line or selection as Lua code
function Editing.lua_exec()
  local txt = get_sel_or_line()
  dostring(txt)
  editor:SetSel(editor.CurrentPos, editor.CurrentPos)
end

-- reformats current paragraph or reformats selected text
function Editing.reformat_paragraph()
  if PLATFORM ~= 'linux' then print('Linux only') return end
  if editor:GetSelText() == '' then Editing.select_paragraph() end
  local txt = editor:GetSelText()
  local f, out
  f = io.open(FILE_IN, 'w') f:write(txt) f:close()
  os.execute(FMTP_CMD..FILE_IN..REDIRECT..FILE_OUT)
  f = io.open(FILE_OUT) out = f:read('*all') f:close()
  if string.sub(txt, -1) ~= '\n' and
    string.sub(out, -1) == '\n' then
    out = string.sub(out, 1, -2) -- chomp
  end
  editor:ReplaceSel(out)
end

-- convert spaces to tabs or vice-versa
--[[
function Editing.convert(what)
  local spaces_per_tab = editor.TabWidth
  editor:BeginUndoAction()
  for i = 0, editor.LineCount - 1 do
    if editor.LineIndentation[i] ~= 0 then
      local vhome = editor.LineIndentPosition[i]
      local home  = editor:PositionFromLine(i)
      editor:SetSel(home, vhome)
      local indent = editor:GetSelText()
      local spaces = string.rep(' ', spaces_per_tab)
      if what == 'spaces_to_tabs' then
        indent = string.gsub(indent, spaces, '\t')
      elseif what == 'tabs_to_spaces' then
        indent = string.gsub(indent, '\t', spaces)
      end
      editor:ReplaceSel(indent)
    end
  end
  editor:EndUndoAction()
  return true
end
]]--

--[[
function Editing.goto_ctag()
  local line = get_sel_or_line()
  local s1, s2, tag_name, file_name, tag_pattern =
        string.find(line, '([^\t]*)\t([^\t]*)\t(.*)$')
  if file_name == nil then return end
  scite.Open(file_name)
  s1 = string.find(tag_pattern, '$/')
  if s1 ~= nil then
    tag_pattern = string.sub(tag_pattern, 3, s1 - 1)
    tag_pattern = string.gsub(tag_pattern, '\\/', '/')
    local p1, p2 = editor:findtext(tag_pattern)
    if p2 then editor:SetSel(p1, p2) end
  else -- line numbers
    s1 = string.find(tag_pattern, ';')
    tag_pattern = string.sub(tag_pattern, 0, s1 - 1)
    local tag_line = tonumber(tag_pattern) - 1
    editor:GotoLine(tag_line)
  end
  local fline = editor.FirstVisibleLine
  local cline = editor:LineFromPosition(editor.CurrentPos)
  editor:LineScroll(0, cline - fline)
end
]]--

-- inserts text into the kill_ring
insert_into_kill_ring = function(txt)
  table.insert(kill_ring, 1, txt)
  if table.getn(kill_ring) > kill_ring.maxn then
    table.remove(kill_ring, kill_ring.maxn + 1)
  end
end

-- scrolls kill_ring backward or forward (default)
scroll_kill_ring = function(direction)
  if direction == 'reverse' then
    kill_ring.pos = kill_ring.pos - 1
    if kill_ring.pos < 1 then
      kill_ring.pos = table.getn(kill_ring)
    end
  else
    kill_ring.pos = kill_ring.pos + 1
    if kill_ring.pos > table.getn(kill_ring) then
      kill_ring.pos = 1
    end
  end
end

-- returns number to the left of the cursor
get_preceding_number = function()
  local pos = editor.CurrentPos
  local char = editor.CharAt[pos - 1]
  local txt = ''
  while tonumber( string.char(char) ) do
    txt = txt..string.char(char)
    pos = pos - 1
    char = editor.CharAt[pos - 1]
  end
  return tonumber(txt) or 1, string.len(txt)
end

-- returns selection or current line
get_sel_or_line = function()
  if editor:GetSelText() == '' then Editing.select_line() end
  return editor:GetSelText()
end
