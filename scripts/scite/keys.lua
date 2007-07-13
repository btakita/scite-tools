--[[
  Mitchell's keys.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Documentation can be found in scripts/doc/keys_doc.txt
]]--

---
-- Manages key commands in SciTE.
-- Key commands are defined in a separate key_commands.lua file that is located
-- in the same directory or package.path.
-- There are several option variables used:
--   PLATFORM: OS platform (linux or windows)
--   SCOPES_ENABLED: Flag indicating whether scopes/styles can be used for key
--     commands.
--   CTRL: The string representing the Control key.
--   SHIFT: The string representing the Shift key.
--   ALT: The string representing the Alt key.
--   ADD: The string representing used to join together a sequence of Control,
--     Shift, or Alt modifier keys.
--   KEYCHAIN_PROP: The SciTE property that will be updated each time the
--     keychain is modified.
module('modules.scite.keys', package.seeall)

-- options
local PLATFORM = _G.PLATFORM or 'linux'
local SCOPES_ENABLED = true
local CTRL  = 'c' -- or alternately 'ctrl'
local SHIFT = 's' -- or alternately 'shift'
local ALT   = 'a' -- or alternately 'alt'
local ADD   = ''  -- or alternately '+'
local KEYCHAIN_PROP = 'KeyChain'
-- end options

---
-- [Local table] Lookup table for key values higher than 255.
-- If a key value given to OnKey is higher than 255, this table is used to
-- return a string representation of the key if it exists.
-- @class table
-- @name KEYSYMS
local KEYSYMS

---
-- [Local table] (Windows only) Lookup table for characters when the Shift key
-- is pressed.
-- Windows uses the same keycodes even if shift is pressed. So if it is, use
-- the keycode and table to lookup the actual character printed.
local SHIFTED

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
    [186] = ';',     -- semicolon
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
  SHIFTED = {
    [49]  = '!', [50]  = '@', [51]  = '#', [52]  = '$', [53]  = '%',
    [54]  = '^', [55]  = '&', [56]  = '*', [57]  = '(', [48]  = ')',
    [186] = ':', [187] = '+', [188] = '<', [189] = '_', [190] = '>',
    [191] = '?', [192] = '~', [219] = '{', [220] = '|', [221] = '}',
    [222] = '"',
  }
end

-- if LINUX ... is quicker than if PLATFORM == 'linux' ...
local LINUX = PLATFORM == 'linux' and true or false

--- [Local table] The current key sequence.
-- @class table
-- @name keychain
local keychain = {}

-- local functions
local try_get_cmd1, try_get_cmd2, try_get_cmd3, try_get_cmd

---
-- Clears the current key sequence.
function clear_key_sequence()
  keychain = {}
  props[KEYCHAIN_PROP] = ''
  scite.UpdateStatusBar()
end

---
-- Determines the possible completions for the current key sequence and prints
-- them out. (Only prints key combinations, not command names.)
function show_completions()
  if #keychain == 0 then return end
  active_table = _G.keys
  if keychain.lexer then active_table = active_table[keychain.lexer] end
  if keychain.scope then active_table = active_table[keychain.scope] end
  for _,key_seq in ipairs(keychain) do active_table = active_table[key_seq] end
  local completion_str = ''
  for key_seq in pairs(active_table) do
    completion_str = completion_str..key_seq..'\t'
  end
  print("Completions for '"..props[KEYCHAIN_PROP].."':")
  print(completion_str)
  print("'".._G.keys.clear_sequence.."' to cancel")
end

---
-- SciTE OnKey Lua extension function.
-- It is called every time a key is pressed and determines which commands to
-- execute or which new key in a chain to enter based on the current key
-- sequence, lexer, and scope.
-- @return OnKey returns what the commands it executes return. If nothing is
--   returned, OnKey returns true by default. A true return value will tell
--   SciTE not to handle the key afterwords.
function _G.OnKey(code, shift, control, alt)
  local key_seq = ''
  if control then key_seq = key_seq..CTRL..ADD end
  if shift   then key_seq = key_seq..SHIFT..ADD end
  if alt     then key_seq = key_seq..ALT..ADD end
  --print(code, string.char(code))
  if LINUX then
    if code < 256 then
      key_seq = key_seq..string.char(code):lower()
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
      key_seq = key_seq..string.char(code):lower()
    else
      return
    end
  end

  if key_seq == _G.keys.clear_sequence then
    if #keychain > 0 then clear_key_sequence() return true end
  elseif key_seq == _G.keys.show_completions then
    if #keychain > 0 then show_completions() return true end
  end

  local lexer = editor.Lexer
  local scope = editor.StyleAt[editor.CurrentPos]
  local ret, func, arg
  -- print(key_seq, 'Lexer: '..lexer, 'Scope: '..scope)

  keychain[#keychain + 1] = key_seq
  if SCOPES_ENABLED then
    ret, func, arg = pcall(try_get_cmd1, key_seq, lexer, scope)
    if func == -1 then keychain.lexer, keychain.scope = lexer, scope end
  end
  if not ret and func ~= -1 then
    ret, func, arg = pcall(try_get_cmd2, key_seq, lexer)
    if func == -1 then keychain.lexer = lexer end
  end
  if not ret and func ~= -1 then
    ret, func, arg = pcall(try_get_cmd3, key_seq)
  end

  if ret then
    clear_key_sequence()
    if type(func) == 'function' then
      local ret, retval = pcall(func, arg)
      if ret then
        if type(retval) == 'boolean' then return retval end
      else print(retval) end -- error
    elseif type(func) == 'number' then
      scite.MenuCommand(func)
    end
    return true
  else
    -- Clear key sequence because it's not part of a chain.
    -- (try_get_cmd throws error number -1.)
    if func ~= -1 then
      local size = #keychain - 1
      clear_key_sequence()
      if size > 0 then -- previously in a chain
        props[KEYCHAIN_PROP] = 'Invalid Sequence'
        scite.UpdateStatusBar()
        return true
      end
    else return true end
  end
end

-- Note the following functions are called inside pcall so error handling or
-- checking if keys exist etc. is not necessary.

---
-- [Local function] Tries to get a key command based on the lexer and current
-- scope.
try_get_cmd1 = function(key_seq, lexer, scope)
  return try_get_cmd( _G.keys[lexer][scope], key_seq )
end

---
-- [Local function] Tries to get a key command based on the lexer.
try_get_cmd2 = function(key_seq, lexer)
  return try_get_cmd( _G.keys[lexer], key_seq )
end

---
-- [Local function] Tries to get a global key command.
try_get_cmd3 = function(key_seq)
  return try_get_cmd(_G.keys, key_seq)
end

---
-- [Local function] Helper function to get commands with the current keychain.
-- If the current item in the keychain is part of a chain, throw an error value
-- of -1. This way, pcall will return false and -1, where the -1 can easily and
-- efficiently be checked rather than using a string error message.
try_get_cmd = function(active_table)
  local str_seq = ''
  for _, key_seq in ipairs(keychain) do
    str_seq = str_seq..key_seq..' '
    active_table = active_table[key_seq]
  end
  if not active_table[1] then
    props['KeyChain'] = str_seq
    scite.UpdateStatusBar()
    error(-1, 0)
  end
  return active_table[1], active_table[2]
end

--- Global container that holds all key commands.
-- @class table
-- @name keys
_G.keys = {}

require 'scite/key_commands'
