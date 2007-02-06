--[[
  Mitchell's php/commands.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.
  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Commands for the PHP "bundle"
]]--

-- platform-specific options
local PLATFORM = PLATFORM or 'linux'
local FILE_OUT, REDIRECT, PHP_EXE
if PLATFORM == 'linux' then
  FILE_OUT = '/tmp/scite_output'
  REDIRECT = ' &> '
  PHP_EXE  = 'php-cgi -f '
elseif PLATFORM == 'windows' then
  FILE_OUT = os.getenv('TEMP')..'\\scite_output.txt'
  REDIRECT = ' > '
  PHP_EXE  = 'C:/php/php.exe -f '
end
-- end options

-- displays arguments of function to the left of the cursor
function Functions.show_args()
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
    os.execute(PHP_EXE..'"'..props['SciteDefaultHome']..
      '/scripts/php/completion/phpcc.ShowTooltip.php" '..
      func..REDIRECT..FILE_OUT)
    local f = io.open(FILE_OUT)
    local tooltip = f:read('*all')
    f:close()
    editor:CallTipShow(editor.CurrentPos, tooltip)
  end
end

-- PHP-specific key commands
if type(keys) == 'table' then
  if not keys[SCLEX_HTML] then keys[SCLEX_HTML] = {} end
  keys[SCLEX_HTML].ac = {
    f = {
      l = { Functions.show,      'function' },
      a = { Functions.show_args, 'function' }
    }
  }
end
