--[[
  Mitchell's ruby.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- The ruby module.
-- It provides utilities for editing Ruby code.
module('modules.ruby', package.seeall)

---
-- [Local table] Character matching.
-- @class table
-- @name char_matches
local char_matches = {
  ['('] = ')', ['['] = ']', ['{'] = '}',
  ["'"] = "'", ['"'] = '"', ['|'] = '|'
}

---
-- SciTE OnChar Lua extension function.
-- Matches characters specified in char_matches if the editor pane has focus.
-- This overrides modules.scite.editing's OnChar function.
function _G.OnChar(c)
  if char_matches[c] and editor.Focus then
    editor:InsertText( editor.CurrentPos, char_matches[c] )
  end
end

if type(_G.snippets) == 'table' then
  ---
  -- Container for Ruby-specific snippets.
  -- @class table
  -- @name snippets.ruby
  _G.snippets.ruby = {}
end

if type(_G.keys) == 'table' then
  ---
  -- Container for Ruby-specific key commands.
  -- @class table
  -- @name keys.ruby
  _G.keys[SCLEX_RUBY] = {}
end

require 'ruby/snippets'
require 'ruby/commands'
