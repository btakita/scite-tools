--[[
  Mitchell's scite.lua
  Copyright (c) 2006 Mitchell Foral. All rights reserved.
  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  SciTE "bundle" loader
]]--

local PLATFORM = PLATFORM or 'linux'

require 'scite/editing'
require 'scite/file_browser'
require 'scite/functions'
require 'scite/mlines'
require 'scite/snippets'
--require 'scite/styler'
if PLATFORM == 'linux' then
  require 'scite/cdialog'
  require 'scite/filter_through'
  require 'scite/macros'
end
require 'scite/keys' -- important to load last

SciTE = {}

function SciTE.open_module(name)
  scite.Open( props['SciteDefaultHome']..'/scripts/'..name )
end
