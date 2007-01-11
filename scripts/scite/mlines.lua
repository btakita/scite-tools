--[[
  Mitchell's mlines.lua
  Copyright (c) 2006 Mitchell Foral. All rights reserved.
  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Multiple line editing for the SciTE "bundle"

  API (see functions for descriptions):
    - MLines.add
    - MLines.add_multiple
    - MLines.clear
    - MLines.update
]]--

-- options
local MARK_MLINE = 2
local mlines = {}
local mlines_count = 0
local mlines_most_recent
local PLATFORM = PLATFORM or 'linux'
local MARK_MLINE_COLOR
if PLATFORM == 'linux' then
  MARK_MLINE_COLOR = tonumber("0x4D994D")
elseif PLATFORM == 'windows' then
  MARK_MLINE_COLOR = 5085517
end
-- end options

MLines = {}

-- adds mline marker on current line
function MLines.add()
  editor:MarkerSetBack(MARK_MLINE, MARK_MLINE_COLOR)
  local column = editor.Column[editor.CurrentPos]
  local line = editor:LineFromPosition(editor.CurrentPos)
  local new_marker = editor:MarkerAdd(line, MARK_MLINE)
  mlines[line] = { marker = new_marker, start_col = column }
  mlines_most_recent = line
  mlines_count = mlines_count + 1
end

-- adds set of mline markers between most recently added line
-- and current line (using current column on current line)
function MLines.add_multiple()
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

-- clears all mline markers
function MLines.clear()
  editor:MarkerDeleteAll(MARK_MLINE)
  mlines = {}
  mlines_count = 0
  mlines_most_recent = nil
end

-- applies changes in current line to all lines being edited
function MLines.update()
  local curr_line = editor:LineFromPosition(editor.CurrentPos)
  local curr_col  = editor.Column[editor.CurrentPos]
  if mlines[curr_line] then
    local row_pos   = editor:PositionFromLine(curr_line)
    local start_pos = row_pos + mlines[curr_line].start_col
    local end_pos   = row_pos + curr_col
    local delta     = end_pos - start_pos
    local txt       = ''
    if delta > 0 then
      txt = editor:textrange(start_pos, end_pos)
    end
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
