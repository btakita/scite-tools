--[[
  Mitchell's php/commands.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- Commands for the php module.
-- There are several option variables used:
--   PLATFORM: OS platform (linux or windows).
--   FILE_IN: Location of the temporary file used as STDIN for
--     various operations.
--   FILE_OUT: Location of the temporary file that will contain
--     output for various operations.
--   REDIRECT: The command line symbol used for redirecting STDOUT
--     to a file.
--   PHP_CMD: The command that executes the PHP interpreter.
module('modules.php.commands', package.seeall)

-- options
local PLATFORM = PLATFORM or 'linux'
local FILE_OUT, REDIRECT, PHP_CMD
if PLATFORM == 'linux' then
  FILE_OUT = '/tmp/scite_output'
  REDIRECT = ' &> '
  PHP_CMD  = 'php-cgi -f '
elseif PLATFORM == 'windows' then
  FILE_OUT = os.getenv('TEMP')..'\\scite_output.txt'
  REDIRECT = ' > '
  PHP_CMD  = 'C:/php/php.exe -f '
end
-- end options

---
-- If possible, display the arguments of the function to the left
-- of the caret.
-- This function first tries to find the function in question in
-- the current source file. If it is not there, this function
-- performs a lookup in completion/.
-- This overrides the standard module.scite.functions's show_args
-- function.
function modules.scite.functions.show_args()
  local pos = editor.CurrentPos
  if editor.CharAt[pos - 1] == string.byte('(') then
    pos = pos - 1
  end
  local func_start = editor:WordStartPosition(pos)
  local func = editor:textrange(func_start, pos)
  local s, e = editor:findtext('function '..func)
  if s and e then
    local line = editor:GetLine( editor:LineFromPosition(s) )
    local _, _, params = string.find(line, '(%(.+%))')
    if params == nil then params = 'No params' end
    editor:CallTipShow(editor.CurrentPos, params)
  else -- not in current source file, lookup php function
    os.execute(PHP_CMD..'"'..props['SciteDefaultHome']..
      '/scripts/php/completion/phpcc.ShowTooltip.php" '..
      func..REDIRECT..FILE_OUT)
    local f = io.open(FILE_OUT)
    local tooltip = f:read('*all')
    f:close()
    editor:CallTipShow(editor.CurrentPos, tooltip)
  end
end

-- PHP-specific key commands
local keys = _G.keys
if type(keys) == 'table' then
  local m_functions = modules.scite.functions
  if not keys[SCLEX_HTML] then keys[SCLEX_HTML] = {} end
  keys[SCLEX_HTML].ac = {
    f = {
      l = { m_functions.show,      'function' },
      a = { m_functions.show_args, 'function' }
    }
  }
end
