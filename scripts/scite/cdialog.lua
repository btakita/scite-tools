--[[
  Mitchell's cdialog.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Utilizes completion.rb for displaying a completion dialog for
  enabling user selection of a list of choices for the SciTE "bundle"

  Linux only

  API (see functions for descriptions):
    - CDialog.choose_key( options, title [, show_list] )
    - CDialog.choose_value( options, title [, show_list] )
    - CDialog.choose( options, title [, show_list] )
    - CDialog.switch_buffer
]]--

-- platform specific options
local PLATFORM = PLATFORM or 'linux'
local FILE_OUT, REDIRECT, RUBY_CMD
if PLATFORM == 'linux' then
  FILE_OUT = '/tmp/scite_output'
  REDIRECT = ' > '
  RUBY_CMD = 'ruby '
elseif PLATFORM == 'windows' then
  print('Sorry, scite/cdialog.lua is only for Linux')
end
-- end options

CDialog = {}

-- returns selected choice from string of options (delimited by
-- newlines); returns selection, nil if cancelled, or false if
-- empty string was selected
function CDialog.choose(option_list, title, ...)
  local show_list_opt = arg[1] == true and '-l ' or ''
  os.execute(RUBY_CMD..props['SciteDefaultHome']..
    '/scripts/utils/completion.rb -n '..title..' '..
    show_list_opt..' <<< "'..option_list..'"'..
    REDIRECT..FILE_OUT)
  local out
  f = io.open(FILE_OUT) out = f:read('*all') f:close()
  if out == '*cancelled*' then return nil end
  return out ~= '' and out or false
end

-- brings up a completion dialog for the keys in a table
-- returns selection or nil
function CDialog.choose_key(options, title, ...)
  local option_list = ''
  for opt,_ in pairs(options) do
    option_list = option_list..opt..'\n'
  end
  local show_list = arg[1] == true
  return CDialog.choose(option_list, title, show_list)
end

-- brings up a completion dialog for the values in a table
-- returns selection or nil
function CDialog.choose_value(options, title, ...)
  local option_list = ''
  for _,opt in pairs(options) do
    option_list = option_list..opt..'\n'
  end
  local show_list = arg[1] == true
  return CDialog.choose(option_list, title, show_list)
end

-- brings up completion dialog with list of current buffers,
-- switches to requested buffer
function CDialog.switch_buffer()
  buffers = {}
  buffer_list = scite.Buffers()
  buffer_list = string.gsub(buffer_list, ';', '\n')
  for buffer_name in string.gfind(buffer_list, '[^\n]+') do
    table.insert(buffers, buffer_name)
  end

  local buf = CDialog.choose(buffer_list, 'Switch Buffer', true)
  if buf == nil then return end -- cancelled dialog

  for idx, name in ipairs(buffers) do
    if name == buf or name == props['LastBuffer'] then
      props['LastBuffer'] = props['FileNameExt']
      scite.SwitchToBuffer(idx - 1)
      break
    end
  end
end
