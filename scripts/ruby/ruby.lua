--[[
  Mitchell's ruby.lua
  Copyright (c) 2006 Mitchell Foral. All rights reserved.
  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Ruby "bundle" loader
]]--

-- for matching enclosures
local char_matches = {
  ['('] = ')', ['['] = ']', ['{'] = '}',
  ["'"] = "'", ['"'] = '"', ['|'] = '|'
}

function OnChar(c)
  if char_matches[c] then -- match enclosure chars
    editor:InsertText( editor.CurrentPos, char_matches[c] )
  end
end

Ruby = {}
if type(keys) == 'table' then keys[SCLEX_RUBY] = {} end

require 'ruby/snippets'
require 'ruby/commands'
