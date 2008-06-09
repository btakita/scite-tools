--[[
  Mitchell's html/commands.lua
  Copyright (c) 2006-2008 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- Commands for the html module.
-- There are several option variables used:
--   PLATFORM: OS platform (linux or windows).
--   FILE_IN: Location of the temporary file used as STDIN for various
--     operations.
--   FILE_OUT: Location of the temporary file that will contain output for
--     various operations.
--   REDIRECT: The command line symbol used for redirecting STDOUT to a file.
--   PHP_CMD: The command that executes the PHP interpreter.
module('modules.html.commands', package.seeall)

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

---
-- Toggle block comment function for HTML.
-- If a single line is being block commented, it is done so on the same line.
-- If multiple lines are being block commented, the start of the comment is
-- placed on a new line before the first selected line and the end of the
-- comment is placed on a new line after the last selected line.
function toggle_block_comment()
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
  local ws1, uncommented, ws2 = txt:match('^(%s*)<!%-%-%s?(.-)%s?%-%->(%s*)$')
  if not uncommented then
    editor:ReplaceSel('<!--'..sep..txt..sep..'-->')
  else
    editor:ReplaceSel(ws1..uncommented..ws2)
  end
end

---
-- Wraps the selected text inside a snippet that expands to an HTML tag.
function wrap_in_tag()
  modules.scite.snippets.insert(
    "<${1:p}>$(SelectedText)</${1/^\\s*(\\S+)\\s*/$1/}>")
end

---
-- Uses PHP to replace the selection or the contents of the current line with
-- its URL-encoded equivalent.
-- @see php_command.
function encode_url()
  local txt = get_sel_or_line()
  editor:ReplaceSel( php_command('echo urlencode( fgets(STDIN) );', txt) )
end

---
-- Uses PHP to replace the URL-encoded selection or the contents of the current
-- line with its URL-decoded equivalent.
-- @see php_command.
function decode_url()
  local txt = get_sel_or_line()
  editor:ReplaceSel( php_command('echo urldecode( fgets(STDIN) );', txt) )
end

---
-- Uses PHP to replace special characters in the selection or the contents of
-- the current line with their HTML entities.
-- @see php_command.
function encode_html_entities()
  local txt = get_sel_or_line()
  editor:ReplaceSel( php_command('echo htmlentities( fgets(STDIN) );', txt) )
end

---
-- Uses PHP to replace HTML entities in the selection or the contents of the
-- current line with their ASCII equivalents.
-- @see php_command.
function decode_html_entities()
  local txt = get_sel_or_line()
  editor:ReplaceSel( php_command('echo html_entity_decode( fgets(STDIN) );', txt) )
end

---
-- Use PHP to strip HTML and PHP tags from the selection or the contents of the
-- current line and replace the text.
-- @see php_command.
function strip_tags()
  local txt = get_sel_or_line()
  editor:ReplaceSel( php_command('echo strip_tags( fgets(STDIN) );', txt) )
end

---
-- [Local function] Execute PHP and return the result printed to STDOUT.
-- @param cmd The PHP code to execute.
-- @param input The text provided as STDIN for cmd.
php_command = function(cmd, input)
  local f, out
  f = io.open(FILE_IN, 'w') f:write(input) f:close()
  os.execute(PHP_CMD..cmd..REDIRECT..FILE_OUT..' < '..FILE_IN)
  f = io.open(FILE_OUT) out = f:read('*all') f:close()
  return out
end

---
-- [Local function] Returns the current selection or the contents of the
-- current line.
get_sel_or_line = function()
  if editor:GetSelText() == '' then Editing.select_line() end
  return editor:GetSelText()
end

-- HTML-specific key commands
local keys = _G.keys
if keys and type(keys) == 'table' then
  keys[SCLEX_HTML].cq  = { toggle_block_comment }
  keys[SCLEX_HTML].caw = { wrap_in_tag          }
end
