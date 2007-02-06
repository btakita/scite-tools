--[[
  Mitchell's html/commands.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.
  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Commands for the HTML "bundle"
]]--

-- platform specific options
local PLATFORM = PLATFORM or 'linux'
local FILE_IN, FILE_OUT, REDIRECT, PHP_CMD
if PLATFORM == 'linux' then
  FILE_IN  = '/tmp/scite_input'
  FILE_OUT = '/tmp/scite_output'
  REDIRECT = '" &> '
  PHP_CMD  = 'php -r "'
elseif PLATFORM == 'windows' then
  FILE_IN  = os.getenv('TEMP')..'\\scite_input.php'
  FILE_OUT = os.getenv('TEMP')..'\\scite_output.txt'
  REDIRECT = '" > '
  PHP_CMD  = 'php -r "'
end
-- end options

-- local functions
local php_command, get_sel_or_line

-- block comment HTML
function HTML.toggle_block_comment()
  local sep = ' '
  local sline = editor:LineFromPosition(editor.CurrentPos)
  local eline = editor:LineFromPosition(editor.Anchor)
  if sline ~= eline then -- multiline comment
    if sline > eline then sline, eline = eline, sline end
    local s = editor:PositionFromLine(sline)
    local e = editor.LineEndPosition[eline]
    editor:SetSel(s, e)
    sep = '\n'
  else
    editor:VCHome(); editor:LineEndExtend()
  end
  local txt = editor:GetSelText()
  local _, _, ws1, uncommented, ws2 = string.find(txt,
    '^(%s*)<!%-%-%s?(.-)%s?%-%->(%s*)$')
  if not uncommented then
    editor:ReplaceSel('<!--'..sep..txt..sep..'-->')
  else
    editor:ReplaceSel(ws1..uncommented..ws2)
  end
end

-- wraps the selection inside an html tag
function HTML.wrap_in_tag()
  Snippets.insert(
    "<${1:p}>$(SelectedText)</${1/^\\s*(\\S+)\\s*/$1/}>")
end

-- URL-encodes string
function HTML.encode_url()
  local txt = get_sel_or_line()
  editor:ReplaceSel(
    php_command('echo urlencode( fgets(STDIN) );', txt) )
end

-- decodes URL-encoded string
function HTML.decode_url()
  local txt = get_sel_or_line()
  editor:ReplaceSel(
    php_command('echo urldecode( fgets(STDIN) );', txt) )
end

-- convert all applicable characters to HTML entities
function HTML.encode_html_entities()
  local txt = get_sel_or_line()
  editor:ReplaceSel(
    php_command('echo htmlentities( fgets(STDIN) );', txt) )
end

-- convert all HTML entities to their applicable characters
function HTML.decode_html_entities()
  local txt = get_sel_or_line()
  editor:ReplaceSel(
    php_command('echo html_entity_decode( fgets(STDIN) );', txt) )
end

-- strip HTML and PHP tags from a string
function HTML.strip_tags()
  local txt = get_sel_or_line()
  editor:ReplaceSel(
    php_command('echo strip_tags( fgets(STDIN) );', txt) )
end

-- execute and return results of the php command
php_command = function(cmd, input)
  local f, out
  f = io.open(FILE_IN, 'w') f:write(input) f:close()
  os.execute(PHP_CMD..cmd..REDIRECT..FILE_OUT..' < '..FILE_IN)
  f = io.open(FILE_OUT) out = f:read('*all') f:close()
  return out
end

-- returns selection or current line
get_sel_or_line = function()
  if editor:GetSelText() == '' then Editing.select_line() end
  return editor:GetSelText()
end

-- HTML-specific key commands
if keys and type(keys) == 'table' then
  keys[SCLEX_HTML].cq  = { HTML.toggle_block_comment }
  keys[SCLEX_HTML].caw = { HTML.wrap_in_tag          }
end
