--[[
  Mitchell's mlines.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- Multiple line editing for the scite module.
-- There are several option variables used:
--   PLATFORM: OS platform (linux or windows).
--   MARK_MLINE: The integer mark used to identify an MLine marked line.
--   MARK_MLINE_COLOR: The Scintilla color used for an MLine marked line.
module('modules.scite.mlines', package.seeall)

-- options
local PLATFORM = _G.PLATFORM or 'linux'
local MARK_MLINE = 2
local MARK_MLINE_COLOR
if PLATFORM == 'linux' then
  MARK_MLINE_COLOR = tonumber("0x4D994D")
elseif PLATFORM == 'windows' then
  MARK_MLINE_COLOR = 5085517
end
-- end options

---
-- [Local table] Contains all MLine marked lines with the column index to edit
-- with respect to for each specific line.
-- @class table
-- @name mlines
local mlines = {}

local mlines_count = 0
local mlines_most_recent

---
-- Adds an mline marker to the current line and stores the line number and
-- column position of the caret in the mlines table.
function add()
  editor:MarkerSetBack(MARK_MLINE, MARK_MLINE_COLOR)
  local column = editor.Column[editor.CurrentPos]
  local line = editor:LineFromPosition(editor.CurrentPos)
  local new_marker = editor:MarkerAdd(line, MARK_MLINE)
  mlines[line] = { marker = new_marker, start_col = column }
  mlines_most_recent = line
  mlines_count = mlines_count + 1
end

---
-- Adds mline markers to all lines from the most recently added line to the
-- current line.
-- The mlines table is updated as in add(), but all column positions are the
-- same as the current column caret position.
function add_multiple()
  if mlines_count > 0 then
    local line = editor:LineFromPosition(editor.CurrentPos)
    local column = editor.Column[editor.CurrentPos]
    local start_line, end_line
    if mlines_most_recent < line then
      start_line, end_line = mlines_most_recent, line
    else
      start_line, end_line = line, mlines_most_recent
    end
    for curr_line = start_line, end_line do
      local new_mark = editor:MarkerAdd(curr_line, MARK_MLINE)
      mlines[curr_line] = { marker = new_mark, start_col = column }
    end
    mlines_count = mlines_count + (end_line - start_line)
    mlines_most_recent = line
  end
end

---
-- Clears all mline markers and the mlines table.
function clear()
  editor:MarkerDeleteAll(MARK_MLINE)
  mlines = {}
  mlines_count = 0
  mlines_most_recent = nil
end

---
-- Applies changes made in the current line relative to the caret column
-- position stored initially to all lines with mline markers in relation to
-- their initial column positions.
function update()
  local curr_line = editor:LineFromPosition(editor.CurrentPos)
  local curr_col  = editor.Column[editor.CurrentPos]
  if mlines[curr_line] then
    local row_pos   = editor:PositionFromLine(curr_line)
    local start_pos = row_pos + mlines[curr_line].start_col
    local end_pos   = row_pos + curr_col
    local delta     = end_pos - start_pos
    local txt       = ''
    if delta > 0 then txt = editor:textrange(start_pos, end_pos) end
    for line_num, item in pairs(mlines) do
      if line_num ~= curr_line then
        local next_pos = editor:PositionFromLine(line_num) +
          item.start_col
        if delta < 0 then
          editor.CurrentPos, editor.Anchor = next_pos, next_pos
          for i = 1, math.abs(delta) do editor:DeleteBack() end
          item.start_col = editor.Column[editor.CurrentPos]
        else
          editor:InsertText(next_pos, txt)
          item.start_col = item.start_col + string.len(txt)
        end
      end
    end
    if delta < 0 then
      local pos = editor:PositionFromLine(curr_line) + curr_col
      editor.CurrentPos, editor.Anchor = pos, pos
    end
    mlines[curr_line].start_col = curr_col
  end
end
