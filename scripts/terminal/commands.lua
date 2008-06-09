--[[
  Mitchell's terminal/commands.lua
  Copyright (c) 2006-2008 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- Commands for the terminal module.
module('modules.terminal.commands', package.seeall)

-- access to server and client objects
local m_terminal = modules.terminal

local prompt = '> '

---
-- Starts the terminal server on a specified port.
-- Then it creates server and client objects.
-- @param port The port to start the terminal server on.
function start(port)
  local server = socket.tcp()
  if not server:bind('localhost', port) then
    print('Cannot create TCP server on port '..port)
    return
  end
  server:listen()
  server:settimeout(5)
  os.execute('ruby '..props['SciteDefaultHome']..
    '/scripts/utils/shell.rb&')
  local client = server:accept()
  if not client then
    print('Failed to connect to terminal server on port '..port)
    server:close()
    return
  end
  client:settimeout(0.1)
  m_terminal.server = server
  m_terminal.client = client
  props['Macro'] = 'Terminal: '..port
  scite.UpdateStatusBar()
  editor:AddText(prompt)
end

---
-- Shuts down the terminal server and closes sockets.
function close()
  send('exit')
  os.execute('sleep 1')
  m_terminal.client:close()
  m_terminal.client = nil
  m_terminal.server:close()
  m_terminal.server = nil
  props['Macro'] = ''
  scite.UpdateStatusBar()
end

---
-- Sends text to the terminal server as input.
-- @param txt The text input to send to the terminal server. If none specified,
--   the current selection or the contents of the current line is used as
--   input.
function send(txt)
  if not txt then txt = editor:GetSelText() end
  if txt == '' then
    txt = editor:GetLine( editor:LineFromPosition(editor.CurrentPos) )
  end
  txt = txt:gsub('^'..prompt, '')
  m_terminal.client:send(txt..'\n')
end

---
-- Receives and returns terminal server ouput.
function receive()
  local output = ''
  local line = m_terminal.client:receive('*l')
  while line do
    output = output..line..'\n'
    line = m_terminal.client:receive('*l')
  end
  return output
end

---
-- Prints text to the current buffer on a new line.
-- This is generally called when data is received from the terminal server to
-- be displayed.
-- @param txt The text to print to the current buffer.
function print(txt)
  editor:LineEndExtend()
  editor:NewLine()
  editor:AddText(txt)
  editor:ScrollCaret()
  editor:AddText(prompt)
end

-- Terminal-specific key commands
if type(keys) == 'table' then
  keys.cg = { start, 3003 }
  keys.cq = { close }
  keys['s\n'] = { function() send() print( receive() ) end }
end
