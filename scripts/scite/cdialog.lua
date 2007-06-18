--[[
  Mitchell's cdialog.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- (Linux only) Completion dialog utilities for the scite module.
-- This module requires utils/completion.rb.
-- There are several option variables used:
--   PLATFORM: OS platform (linux or windows).
--   FILE_OUT: Location of the temporary file that will contain
--     output for various operations.
--   REDIRECT: The command line symbol used for redirecting STDOUT
--     to a file.
--   RUBY_CMD: The command that executes the Ruby interpreter.
module('modules.scite.cdialog', package.seeall)

-- platform specific options
local PLATFORM = _G.PLATFORM or 'linux'
local FILE_OUT, REDIRECT, RUBY_CMD
if PLATFORM == 'linux' then
  FILE_OUT = '/tmp/scite_output'
  REDIRECT = ' > '
  RUBY_CMD = 'ruby '
elseif PLATFORM == 'windows' then
  print('Sorry, scite/cdialog.lua is only for Linux')
end
-- end options

---
-- Displays list or dropdown dialog of choices from a string of
-- options (delimited by newlines). This is generally called by
-- the choose_key or choose_value functions because passing a
-- table of options can be more intuitive.
-- @param option_list String of options delimited by newlines.
-- @param title The title of the completion dialog.
-- @param show_list_opt Boolean flag indicating whether the entire
--   list of options is shown as opposed to a dropdown selection.
-- @return Selection, nil if cancelled, or false if empty string
--   was selected.
-- @see choose_key
-- @see choose_value
function choose(option_list, title, show_list_opt)
  local show_list_opt = show_list and '-l ' or ''
  os.execute(RUBY_CMD..props['SciteDefaultHome']..
    '/scripts/utils/completion.rb -n "'..title..'" '..
    show_list_opt..' <<< "'..option_list..'"'..
    REDIRECT..FILE_OUT)
  local out
  f = io.open(FILE_OUT) out = f:read('*all') f:close()
  if out == '*cancelled*' then return nil end
  return out ~= '' and out or false
end

---
-- Shows a completion dialog with choices provided by the keys
-- in a given table of options.
-- @param options Table of options with keys being the choices.
-- @param title The title of the completion dialog.
-- @param show_list Boolean flag indicating whether the entire
--   list of options is shown as opposed to a dropdown selection.
-- @return Choice selected or nil.
function choose_key(options, title, show_list)
  local option_list = ''
  for opt,_ in pairs(options) do
    option_list = option_list..opt..'\n'
  end
  return choose(option_list, title, show_list)
end

---
-- Shows a completion dialog with choices provided by the values
-- in a given table of options.
-- @param options Table of options with values being the choices.
-- @param title The title of the completion dialog.
-- @param show_list Boolean flag indicating whether the entire
--   list of options is shown as opposed to a dropdown selection.
-- @return Choice selected or nil.
function choose_value(options, title, show_list)
  local option_list = ''
  for _,opt in pairs(options) do
    option_list = option_list..opt..'\n'
  end
  return choose(option_list, title, show_list)
end

---
-- Displays a completion dialog with a list of current open SciTE
-- buffers and switches to the requested buffer.
function switch_buffer()
  buffers = {}
  for i = 0, tonumber( props['buffers'] ) do
    local path = scite.BufferPath(i)
    if path == '' then break end
    table.insert(buffers, path)
  end
  buffer_list = table.concat(buffers, '\n')

  local buf = choose(buffer_list, 'Switch Buffer', true)
  if buf == nil then return end -- cancelled dialog

  for idx, name in ipairs(buffers) do
    if name == buf or name == props['LastBuffer'] then
      props['LastBuffer'] = props['FileNameExt']
      scite.SwitchToBuffer(idx - 1)
      break
    end
  end
end
