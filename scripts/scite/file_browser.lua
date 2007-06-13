--[[
  Mitchell's file_browser.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Filesystem browser for the SciTE "bundle"

  This file browser uses a tree-view like structure with
  indentation instead of the +'s and -'s.

  root/
    directory/
      file1.txt
    file2.txt
    file3.txt

  API (see functions for descriptions):
    - FileBrowser.create
    - FileBrowser.action
    - FileBrowser.show_file_details
]]--

-- platform-specific options
local PLATFORM = _G.PLATFORM or 'linux'
local LS_CMD, LSD_CMD, REDIRECT1, FILE_OUT, ROOT, LINE_END
local LS_CMD2, REDIRECT2, DIR_SEP
if PLATFORM == 'linux' then
  LS_CMD    = 'ls -1p '
  LSD_CMD   = 'ls -dhl '
  REDIRECT1 = ' 1> '
  REDIRECT2 = ' 2>&1 '
  FILE_OUT  = '/tmp/scite_output'
  ROOT      = '/'
  LINE_END  = '\n'
  DIR_SEP   = '/'
elseif PLATFORM == 'windows' then
  LS_CMD    = 'dir /A:D /B '
  LS_CMD2   = 'dir /A:-D /B '
  LSD_CMD   = 'dir /A /Q '
  REDIRECT1 = ' 1> '
  REDIRECT2 = ' 2>&1 '
  FILE_OUT  = os.getenv('TEMP')..'\\scite_output.txt'
  ROOT      = 'C:\\'
  LINE_END  = '\r\n'
  DIR_SEP    = '\\'
end
-- end options

-- local functions
local get_line, get_sel_or_line, get_dir_contents, get_abs_path
local is_dir, dir_is_open, open_dir, close_dir

FileBrowser = {}

-- displays directory structure of either the (absolute path)
-- directory stated on the current line or the root directory
function FileBrowser.create()
  local root_dir = get_sel_or_line()
  if root_dir ~= '' then
    if string.sub( root_dir, string.len(root_dir) ) ~= DIR_SEP then
      root_dir = root_dir..DIR_SEP
    end
    ROOT = root_dir
  end
  editor:SetText( 'File Browser - '..ROOT..LINE_END..LINE_END..
    get_dir_contents(ROOT) )
  editor:GotoLine(2)
end

-- if the item on the current line is a closed directory,
-- open it and list its contents (indented)
-- if the item is an open directory, close it, removing its
-- contents from the screen
-- if the item is a file, open it in SciTE
function FileBrowser.action()
  if editor:GetLine(0) ~= 'File Browser - '..ROOT..LINE_END then
    return
  end

  local pos = editor.CurrentPos
  local _, _, item = string.find( get_line(), '^%s*(.+)$' )
  if not item then return end

  local line_num = editor:LineFromPosition(editor.CurrentPos)
  local abs_path = get_abs_path(item, line_num)
  if is_dir(item) then
    if dir_is_open(line_num) then
      close_dir(abs_path, line_num)
    else
      open_dir(abs_path, line_num)
    end
    editor:SetSel(pos, pos)
  else
    editor:SetSel(pos, pos)
    scite.Open( string.sub(abs_path, 2, -2) )
  end
end

-- retrieve details on a file and display them in a calltip
function FileBrowser.show_file_details()
  if editor:GetLine(0) ~= 'File Browser - '..ROOT..LINE_END then
    return
  end

  local pos = editor.CurrentPos
  local _, _, item = string.find( get_line(), '^%s*(.+)$' )
  if not item then return end
  editor:SetSel(pos, pos)

  local line_num = editor:LineFromPosition(editor.CurrentPos)
  local abs_path = get_abs_path(item, line_num)
  os.execute(LSD_CMD..abs_path..REDIRECT1..FILE_OUT..REDIRECT2)

  local f = io.open(FILE_OUT)
  local out
  if PLATFORM == 'linux' then
    out = f:read('*all')
    local _, _, perms, num_dirs, owner, group, size, mod_date =
      string.find(out, '^(%S-)%s(%d-)%s(%S-)%s(%S-)'..
        '%s(%S-)%s([%d-]-%s[%d:]-)%s.+$')
    out = item..'\n'..
          'Perms:\t'..perms..'\n'..
          '#Dirs:\t'..num_dirs..'\n'..
          'Owner:\t'..owner..'\n'..
          'Group:\t'..group..'\n'..
          'Size:\t'..size..'\n'..
          'Date:\t'..mod_date
  elseif PLATFORM == 'windows' then
    for line in f:lines() do
      if string.find(line, '^%d') then
        local _, _, mod_date, size, owner = string.find(line,
          '^([%d/]+%s%s[%d:]+%s[AP]M)%s+([%d,]+)'..
          '%s([%w\\%.]+)%s.+$')
        if mod_date and size and owner then
          out = item..'\n'..
                'Owner:\t'..owner..'\n'..
                'Size:\t'..size..'\n'..
                'Date:\t'..mod_date
        else
          out = item..'\nCan\'t stat directory'
        end
        break
      end
    end
  end
  f:close()

  editor:CallTipShow(editor.CurrentPos, out)
end

-- returns text on current line
get_line = function()
  editor:Home() editor:LineEndExtend()
  return editor:GetSelText()
end

-- returns selection or text on current line
get_sel_or_line = function()
  if editor:GetSelText() == '' then return get_line() end
  return editor:GetSelText()
end

-- returns contents of a directory
get_dir_contents = function(abs_path)
  os.execute(LS_CMD..abs_path..REDIRECT1..FILE_OUT..REDIRECT2)
  local f = io.open(FILE_OUT)
  local out = ''
  if PLATFORM == 'linux' then
    out = f:read('*all')
  elseif PLATFORM == 'windows' then
    for line in f:lines() do -- these are directories
      local _, _, item = string.find(line, '^(.+)$')
      out = out..item..DIR_SEP..LINE_END
    end
    f:close()
    os.execute(LS_CMD2..abs_path..REDIRECT1..FILE_OUT..REDIRECT2)
    f = io.open(FILE_OUT)
    out = out..f:read('*all') -- these are files
  end
  f:close()
  return out
end

-- returns absolute path of a given file or directory by finding
-- changes in indentation
get_abs_path = function(item, line_num)
  local indentation = editor.LineIndentation[line_num]
  if indentation == 0 then return '"'..ROOT..item..'"' end
  local abs_path = item
  local target_indent = indentation - editor.Indent
  local regex = '^%s*(.+)$'
  for i = line_num, 2, -1 do -- ignore "File Browser - ROOT\n\n"
    if editor.LineIndentation[i] == target_indent then
      local _, _, part = string.find( editor:GetLine(i), regex )
      abs_path = part..abs_path
      target_indent = target_indent - editor.Indent
      if target_indent < 0 then break end
    end
  end
  abs_path = string.gsub(abs_path, LINE_END, '')
  return '"'..ROOT..abs_path..'"'
end

-- returns whether the item in question is a directory or not
is_dir = function(item)
  return string.sub( item, string.len(item) ) == DIR_SEP
end

-- returns whether the directory is open or not
dir_is_open = function(line_num)
  local indentation = editor.LineIndentation[line_num]
  return editor.LineIndentation[line_num + 1] > indentation
end

-- opens directory and displays its contents
open_dir = function(abs_path, line_num)
  local contents = get_dir_contents(abs_path)
  local pos = editor:PositionFromLine(line_num + 1)
  local indentation = editor.LineIndentation[line_num]
  if string.len(contents) > 0 then
    editor:InsertText(pos, contents)
    editor:SetSel( pos, pos + string.len(contents) )
    for i = 0, indentation / editor.Indent do editor:Tab() end
  end
end

-- closes directory, hiding its contents
close_dir = function(abs_path, line_num)
  local indentation = editor.LineIndentation[line_num]
  local last_line
  for i = line_num + 1, editor.LineCount - 1 do
    if editor.LineIndentation[i] <= indentation then
      last_line = i - 1
      break
    end
  end
  local start_pos, end_pos
  start_pos = editor.LineEndPosition[line_num]
  end_pos   = editor.LineEndPosition[last_line]
  editor:remove(start_pos, end_pos)
end
