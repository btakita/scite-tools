--[[
  Mitchell's keys.lua
  Copyright (c) 2006 Mitchell Foral. All rights reserved.
  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
  Documentation can be found in scripts/doc/keys_doc.txt

  Manages key commands in SciTE (custom binary only)

  Key commands are defined in a separate file: key_commands.lua
    located either in the same directory or in LUA_PATH

  API (see functions for descriptions):
    - Keys.clear_key_sequence
    - Keys.show_completions
  Note OnKey is part of the SciTE Lua Extension in custom binary
]]--

-- options
local PLATFORM = PLATFORM or 'linux'
local SCOPES_ENABLED = true
local CTRL  = 'c' -- or alternately 'ctrl'
local SHIFT = 's' -- or alternately 'shift'
local ALT   = 'a' -- or alternately 'alt'
local ADD   = ''  -- or alternately '+'
local KEYCHAIN_PROP = 'KeyChain'
-- end options

-- key constants
local KEYSYMS, SHIFTED
if PLATFORM == 'linux' then
  KEYSYMS = {          -- from <gdk/gdkkeysyms.h>
    [65288] = '\b',    -- backspace
    [65289] = '\t',    -- tab
    [65293] = '\n',    -- newline
    [65307] = 'esc',   -- escape
    [65535] = 'del',   -- delete
    [65360] = 'home',  -- home
    [65361] = 'left',  -- left
    [65362] = 'up',    -- up
    [65363] = 'right', -- right
    [65364] = 'down',  -- down
    [65365] = 'pup',   -- page up
    [65366] = 'pdown', -- page down
    [65367] = 'end',   -- end
    [65379] = 'ins',   -- insert
    [65470] = 'f1',    -- F1
    [65471] = 'f2',    -- F2
    [65472] = 'f3',    -- F3
    [65473] = 'f4',    -- F4
    [65474] = 'f5',    -- F5
    [65475] = 'f6',    -- F6
    [65476] = 'f7',    -- F7
    [65477] = 'f8',    -- F8
    [65478] = 'f9',    -- F9
    [65479] = 'f10',   -- F10
    [65480] = 'f11',   -- F11
    [65481] = 'f12',   -- F12
  }
elseif PLATFORM == 'windows' then
  KEYSYMS = {
    [8]   = '\b',    -- backspace
    [9]   = '\t',    -- tab
    [13]  = '\n',    -- newline
    [27]  = 'esc',   -- escape
    [32]  = ' ',     -- spacebar
    [33]  = 'pup',   -- page up
    [34]  = 'pdown', -- page down
    [35]  = 'end',   -- end
    [36]  = 'home',  -- home
    [37]  = 'left',  -- left
    [38]  = 'up',    -- up
    [39]  = 'right', -- right
    [40]  = 'down',  -- down
    [45]  = 'ins',   -- insert
    [46]  = 'del',   -- delete
    [91]  = 'win',   -- windows key
    [92]  = 'win',   -- windows key
    [93]  = 'menu',  -- menu key
    [112] = 'f1',    -- F1
    [113] = 'f2',    -- F2
    [114] = 'f3',    -- F3
    [115] = 'f4',    -- F4
    [116] = 'f5',    -- F5
    [117] = 'f6',    -- F6
    [118] = 'f7',    -- F7
    [119] = 'f8',    -- F8
    [120] = 'f9',    -- F9
    [121] = 'f10',   -- F10
    [122] = 'f11',   -- F11
    [123] = 'f12',   -- F12
    [186] = ';',     -- seimcolon
    [187] = '=',     -- equals
    [188] = ',',     -- comma
    [189] = '-',     -- hypen
    [190] = '.',     -- period
    [191] = '/',     -- forward slash
    [192] = '`',     -- accent
    [219] = '[',     -- left bracket
    [220] = '\\',    -- back slash
    [221] = ']',     -- right bracket
    [222] = '\'',    -- single quote
  }

  -- windows uses the same keycodes even if shift is pressed
  -- table lookup used if shift has been pressed
  SHIFTED = {
    [49]  = '!', [50]  = '@', [51]  = '#', [52]  = '$',
    [53]  = '%', [54]  = '^', [55]  = '&', [56]  = '*',
    [57]  = '(', [48]  = ')', [186] = ':', [187] = '+',
    [188] = '<', [189] = '_', [190] = '>', [191] = '?',
    [192] = '~', [219] = '{', [220] = '|', [221] = '}',
    [222] = '"',
  }
end

-- if LINUX ... is quicker than if PLATFORM == 'linux' ...
local LINUX = PLATFORM == 'linux' and true or false

Keys = {}

-- local variables
local keychain = {}

-- clears current key sequence/chain
function Keys.clear_key_sequence()
  keychain = {}
  props[KEYCHAIN_PROP] = ''
  scite.UpdateStatusBar()
end

-- prints possible keychain completions
function Keys.show_completions()
  if table.getn(keychain) == 0 then return end
  active_table = keys
  for _,key_seq in ipairs(keychain) do
    active_table = active_table[key_seq]
  end
  completion_str = ''
  for key_seq,_ in pairs(active_table) do
    completion_str = completion_str..key_seq..'\t'
  end
  print("Completions for '"..props[KEYCHAIN_PROP].."':")
  print(completion_str)
  print("'"..keys.clear_sequence.."' to cancel")
end

-- local functions
local try_get_cmd1, try_get_cmd2, try_get_cmd3, try_get_cmd

-- called every time a key is pressed; if true is returned,
-- the key is not handled at all by SciTE afterwards (thus
-- Alt+key sequences can be overridden)
function OnKey(code, shift, control, alt)
  local key_seq = ''
  if control then key_seq = key_seq..CTRL..ADD end
  if shift   then key_seq = key_seq..SHIFT..ADD end
  if alt     then key_seq = key_seq..ALT..ADD end
  --print(code, string.char(code))
  if LINUX then
    if code < 256 then
      key_seq = key_seq..string.lower( string.char(code) )
    else
      if not KEYSYMS[code] then return end
      key_seq = key_seq..KEYSYMS[code]
    end
  else
    if shift and SHIFTED[code] then
      key_seq = key_seq..SHIFTED[code]
    elseif KEYSYMS[code] then
      key_seq = key_seq..KEYSYMS[code]
    elseif code > 47 then -- printable chars start at 48 (0)
      key_seq = key_seq..string.lower( string.char(code) )
    else
      return
    end
  end

  if key_seq == keys.clear_sequence then
    if table.getn(keychain) > 0 then
      Keys.clear_key_sequence()
      return true
    end
  elseif key_seq == keys.show_completions then
    if table.getn(keychain) > 0 then
      Keys.show_completions()
      return true
    end
  end

  local lexer = editor.Lexer
  local scope = editor.StyleAt[editor.CurrentPos]
  local ret, func, arg
  -- print(key_seq, 'Lexer: '..lexer, 'Scope: '..scope)

  table.insert(keychain, key_seq)
  if SCOPES_ENABLED then
    ret, func, arg = pcall(try_get_cmd1, key_seq, lexer, scope)
  end
  if not ret and
    (func and string.sub(func, -5) ~= 'chain' or true) then
    ret, func, arg = pcall(try_get_cmd2, key_seq, lexer)
  end
  if not ret and string.sub(func, -5) ~= 'chain' then
    ret, func, arg = pcall(try_get_cmd3, key_seq)
  end

  if ret then
    Keys.clear_key_sequence()
    if type(func) == 'function' then
      _, ret = pcall(func, arg)
      if type(ret) == 'boolean' then return ret end
    elseif type(func) == 'number' then
      scite.MenuCommand(func)
    end
    return true
  else
    -- clear key sequence because it's not part of a chain
    -- (try_get_cmd throws error 'Part of chain')
    if string.sub(func, -5) ~= 'chain' then
      local size = table.getn(keychain) - 1
      Keys.clear_key_sequence()
      if size > 0 then -- previously in a chain
        props[KEYCHAIN_PROP] = 'Invalid Sequence'
        scite.UpdateStatusBar()
        return true
      end
    else return true end
  end
end

-- note the following functions are called inside pcall so error
-- handling or checking if keys exist etc. is not necessary

-- tries to get key command based on lexer, scope
try_get_cmd1 = function(key_seq, lexer, scope)
  return try_get_cmd( keys[lexer][scope], key_seq )
end

-- tries to get key command based on lexer
try_get_cmd2 = function(key_seq, lexer)
  return try_get_cmd( keys[lexer], key_seq )
end

-- tries to get global key command
try_get_cmd3 = function(key_seq)
  return try_get_cmd(keys, key_seq)
end

-- helper function to get commands via keychain
try_get_cmd = function(active_table)
  local str_seq = ''
  for _,key_seq in ipairs(keychain) do
    str_seq = str_seq..key_seq..' '
    active_table = active_table[key_seq]
  end
  if not active_table[1] then
    props['KeyChain'] = str_seq
    scite.UpdateStatusBar()
    error('Part of chain')
  end
  return active_table[1], active_table[2]
end

keys = {}
require 'scite/key_commands'

--[[
OLD CODE NOT UTILIZING KEYCHAIN

try_get_cmd1 = function(key_seq, lexer, scope)
  return keys[lexer][scope][key_seq][1],
    keys[lexer][scope][key_seq][2]
end

try_get_cmd2 = function(key_seq, lexer)
  return keys[lexer][key_seq][1], keys[lexer][key_seq][2]
end

try_get_cmd3 = function(key_seq)
  return keys[key_seq][1], keys[key_seq][2]
end
]]--
