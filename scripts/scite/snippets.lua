--[[
  Mitchell's snippets.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Documentation can be found in scripts/scite/snippets_doc.txt
]]--

---
-- Provides Textmate-like snippets for the scite module.
-- There are several option variables used:
--   PLATFORM: OS platform (linux or windows).
--   MARK_SNIPPET: The integer mark used to identify the line that
--     marks the end of a snippet.
--   SCOPES_ENABLED: Flag indicating whether scopes/styles can be
--     used for snippets.
--   FILE_IN: Location of the temporary file used as STDIN for
--     regex mirrors.
--   FILE_OUT: Location of the temporary file that will contain
--     output for regex mirrors.
--   REDIRECT: The command line symbol used for redirecting STDOUT
--     to a file.
--   RUBY_CMD: The command that executes the Ruby interpreter.
--   MARK_SNIPPET_COLOR: The Scintilla color used for the line
--     that marks the end of the snippet.
module('modules.scite.snippets', package.seeall)

-- options
local PLATFORM = _G.PLATFORM or 'linux'
local MARK_SNIPPET   = 4
local SCOPES_ENABLED = true
local FILE_IN, FILE_OUT, REDIRECT, RUBY_CMD, MARK_SNIPPET_COLOR
if PLATFORM == 'linux' then
  FILE_IN  = '/tmp/scite_input'
  FILE_OUT = '/tmp/scite_output'
  REDIRECT = ' &> '
  RUBY_CMD = 'ruby '
  MARK_SNIPPET_COLOR = tonumber("0x4D9999")
elseif PLATFORM == 'windows' then
  FILE_IN  = os.getenv('TEMP')..'\\scite_input.rb'
  FILE_OUT = os.getenv('TEMP')..'\\scite_output.txt'
  REDIRECT = ' > '
  RUBY_CMD = 'ruby '
  MARK_SNIPPET_COLOR = 5085593
end
local DEBUG = false
local RUN_TESTS = false
-- end options

---
-- Global container that holds all snippet definitions.
-- @class table
-- @name snippets
_G.snippets = {}

-- some default snippets
_G.snippets.none = {}
_G.snippets.none.file = "$(FileNameExt)"
_G.snippets.none.path = "$(FilePath)"
_G.snippets.none.tab  = "\${${1:1}:${2:default}}"
_G.snippets.none.key  = "['${1:}'] = { ${2:func}${3:, ${4:arg}} }"

---
-- [Local table] The current snippet.
-- @class table
-- @name snippet
local snippet = {}

---
-- [Local table] The stack of currently running snippets.
-- @class table
-- @name snippet_stack
local snippet_stack = {}

-- local functions
local next_snippet_item
local snippet_text, match_indention, join_lines, load_scopes
local escape, unescape, remove_escapes, _DEBUG

---
-- Begins expansion of a snippet.
-- @param snippet_arg Optional snippet to expand. If none is
--   specified, the snippet is determined from the trigger word
--   to the left of the caret, the lexer, and scope.
function insert(snippet_arg)
  local orig_pos, new_pos, tname
  props['SelectedText'] = editor:GetSelText()
  if not snippet_arg then
    orig_pos = editor.CurrentPos editor:WordLeftExtend()
    new_pos  = editor.CurrentPos
    tname    = editor:GetSelText()
    scope    = editor.StyleAt[orig_pos]
  else
    if editor.CurrentPos > editor.Anchor then
      editor.CurrentPos, editor.Anchor = editor.Anchor, editor.CurrentPos
    end
    orig_pos, new_pos = editor.CurrentPos, editor.CurrentPos
  end

  local tpl
  if tname then
    _DEBUG('tname: '..tname..', scope: '..scope)
    if SCOPES_ENABLED then
      pcall( function() tpl = _G.snippets[scope][tname] end )
      if not tpl then
        pcall( function() tpl = _G.snippets.none[tname] end )
      end
    else
      pcall( function() tpl = _G.snippets[tname] end )
    end
  else
    tpl = snippet_arg
  end

  editor:BeginUndoAction()
  if tpl then
    tpl = escape(tpl)
    _DEBUG('tpl escaped:\n'..tpl)

    -- first replace SciTE variables
    local regex = '%$%((.-)%)'
    tpl = string.gsub(tpl, regex,
      function(variable) return props[variable] end)

    -- then execute any shell code
    local regex = '`(.-)`'
    tpl = string.gsub(tpl, regex,
      function(code)
        os.execute(code..REDIRECT..FILE_OUT)
        local f = io.open(FILE_OUT)
        local out = f:read('*all')
        f:close()
        if string.sub(out, -1) == '\n' then
          return string.sub(out, 1, -2) -- chomp
        end
      end)

    -- if another snippet is currently running, push it onto
    -- the stack
    if snippet.index then
      table.insert(snippet_stack, snippet)
    end

    snippet = {}
    snippet.index     = 0
    snippet.start_pos = editor.CurrentPos
    snippet.cursor    = nil
    snippet.seltext   = props['SelectedText']

    -- now make a table of placeholders and tab stops
    local regex, regex2 = '($%b{})', '^%${(%d+):.*}$'
    local s, _, item = string.find(tpl, regex)
    while item do
      local _, _, num = string.find(item, regex2)
      if num then
        snippet[ tonumber(num) ] = unescape(item)
      end
      local i = s + 1
      s, _, item = string.find(tpl, regex, i)
    end

    tpl = unescape(tpl)
    _DEBUG('tpl unescaped:\n'..tpl)

    -- insert the snippet and set a mark defining the end of
    -- the snippet
    editor:ReplaceSel(tpl)
    editor:NewLine()
    local line = editor:LineFromPosition(editor.CurrentPos)
    snippet.end_marker = editor:MarkerAdd(line, MARK_SNIPPET)
    editor:MarkerSetBack(MARK_SNIPPET, MARK_SNIPPET_COLOR)
    _DEBUG('snippet:')
    if DEBUG then table.foreach(snippet, print) end

    -- finally indent all lines inserted
    editor.CurrentPos = new_pos
    local count, i = -1, -1
    repeat
      count = count + 1
      i = string.find(tpl, '\n', i + 1)
    until i == nil
    match_indention( editor:LineFromPosition(orig_pos), count )
  else
    editor:SetSel(orig_pos, orig_pos)
  end
  editor:EndUndoAction()

  next_snippet_item()
end

---
-- [Local function] Mirror or transform most recently modified
-- field in the current snippet and move on to the next field.
next_snippet_item = function()
  if not snippet.index then return end
  local tpl_start, tpl_end, tpl_text = snippet_text()

  -- if something went wrong and the snippet has been
  -- 'messed up' (e.g. by undo/redo commands)
  if not tpl_text then
    --_DEBUG('no end marker...cancelling')
    cancel_current()
    return
  end

  -- first mirror and/or transform
  editor:BeginUndoAction()
  if snippet.index > 0 then
    if snippet.cursor then
      editor:SetSel(snippet.cursor, editor.CurrentPos)
    else
      editor:WordLeftExtend()
    end
    local last_item = editor:GetSelText()
    _DEBUG('last_item:\n'..last_item)

    editor:SetSel(tpl_start, tpl_end)
    tpl_text = escape(tpl_text)
    _DEBUG('tpl_text escaped:\n'..tpl_text)

    -- regex mirror
    regex = '%${'..snippet.index..'/(.-)/(.-)/([iomxneus]*)}'
    tpl_text = string.gsub(tpl_text, regex,
      function(pattern, replacement, options)
        local script = [[
          li  = %q(last_item)
          rep = %q(replacement)
          li  =~ /pattern/options
          if data = $~
            rep.gsub!(/\#\{(.+?)\}/) do
              expr = $1.gsub(/\$(\d\d?)/, 'data[\1]')
              eval expr
            end
            puts rep.gsub(/\$(\d\d?)/) { data[$1.to_i] }
          end
        ]]
        pattern     = unescape(pattern)
        replacement = unescape(replacement)
        script = string.gsub(script, 'last_item', last_item)
        script = string.gsub(script, 'pattern', pattern)
        script = string.gsub(script, 'options', options)
        script = string.gsub(script, 'replacement', replacement)
        _DEBUG('script:\n'..script)

        local f, out
        -- write the script
        f = io.open(FILE_IN, 'w') f:write(script) f:close()

        -- check the syntax
        os.execute(RUBY_CMD..'-cw '..FILE_IN..REDIRECT..FILE_OUT)
        f = io.open(FILE_OUT) out = f:read('*all') f:close()
        if string.sub(out, 8, 9) ~= 'OK' then return out end

        -- execute the script
        os.execute(RUBY_CMD..FILE_IN..REDIRECT..FILE_OUT)
        f = io.open(FILE_OUT) out = f:read('*all') f:close()
        _DEBUG('regex out:\n'..out)

        if string.sub(out, -1) == '\n' then
          out = string.sub(out, 1, -2) -- chomp
        end
        return out
      end)
    _DEBUG('patterns replaced:\n'..tpl_text)

    -- plain text mirror
    local mirror = '%${'..snippet.index..'}'
    tpl_text = string.gsub(tpl_text, mirror, last_item)
    _DEBUG('mirrors replaced:\n'..tpl_text)
  else
    tpl_text = escape(tpl_text)
    _DEBUG('tpl_text escaped:\n'..tpl_text)
  end
  editor:EndUndoAction()

  editor:SetSel(tpl_start, tpl_end)

  -- now find next snippet item or finish
  editor:BeginUndoAction()
  snippet.index = snippet.index + 1
  if snippet[snippet.index] then
    _DEBUG('next index: '..snippet.index)
    local s, _ = string.find(tpl_text, '${'..snippet.index..':')
    local _, _, next_item = string.find(tpl_text, '($%b{})', s)
    tpl_text = unescape(tpl_text)
    _DEBUG('tpl_text unescaped:\n'..tpl_text)
    editor:ReplaceSel(tpl_text)
    if s and next_item then
      next_item = unescape(next_item)
      _DEBUG('next_item:\n'..next_item)
      local s, e = editor:findtext(next_item, 0, tpl_start)
      if s and e then
        editor:SetSel(s, e)
        snippet.cursor = s
        local regex = '^%${'..snippet.index..':(.*)}$'
        local _, _, default = string.find(next_item, regex)
        editor:ReplaceSel(default)
        editor:SetSel( s, s + string.len(default) )
      else
        _DEBUG('search failed:\n'..next_item)
        next_snippet_item()
      end
    else
      _DEBUG('no item for '..snippet.index)
      next_snippet_item()
    end
  else -- finished
    _DEBUG('snippet finishing...')
    tpl_text = string.gsub(tpl_text, '${0}', '$CURSOR', 1)
    tpl_text = unescape(tpl_text)
    _DEBUG('tpl_text unescaped:\n'..tpl_text)
    tpl_text = remove_escapes(tpl_text)
    _DEBUG('tpl_text escapes removed:\n'..tpl_text)
    editor:ReplaceSel(tpl_text)
    local _, tpl_end, _ = snippet_text()
    if tpl_end then
      -- compensate for extra char in CR+LF line endings
      if editor.EOLMode == 0 then tpl_end = tpl_end - 1 end
      editor:SetSel(tpl_end, tpl_end)
      join_lines()
    end

    local s, e = editor:findtext('$CURSOR', 4, tpl_start)
    if s and e then
      editor:SetSel(s, e)
      editor:ReplaceSel()
    else
      editor:SetSel(tpl_end, tpl_end) -- at snippet end marker
    end
    editor:MarkerDeleteHandle(snippet.end_marker)
    snippet = {}

    -- restore previous running snippet (if any)
    if table.getn(snippet_stack) > 0 then
      snippet = table.remove(snippet_stack)
    end
  end
  editor:EndUndoAction()
end

---
-- Cancels active snippet, reverting to the state before the
-- snippet was activated.
function cancel_current()
  if not snippet.index then return end
  local tpl_start, tpl_end, _ = snippet_text()
  if tpl_start and tpl_end then
    editor:SetSel(tpl_start, tpl_end)
    editor:ReplaceSel() join_lines()
  end
  if snippet.seltext then
    editor:AddText(snippet.seltext)
    editor.Anchor = editor.Anchor - string.len(snippet.seltext)
  end
  editor:MarkerDeleteHandle(snippet.end_marker)
  snippet = {}

  -- restore previous running snippet (if any)
  if table.getn(snippet_stack) > 0 then
    snippet = table.remove(snippet_stack)
  end
end

---
-- List available snippet triggers as an autocompletion list.
-- Global snippets and snippets in the current lexer and scope
-- are used.
function list()
  local list, list_str = {}, ''

  function add_snippets(tpls)
    for k,_ in pairs(tpls) do table.insert(list, k) end
  end

  if SCOPES_ENABLED then
    if snippets.none then
      add_snippets( snippets.none )
    end
    local scope = editor.StyleAt[editor.CurrentPos]
    if snippets[scope] then
      add_snippets( snippets[scope] )
    end
  else
    add_snippets(snippets)
  end

  table.sort(list)
  local sep = string.char(editor.AutoCSeparator)
  for _,v in pairs(list) do list_str = list_str..v..sep end
  list_str = string.sub(list_str, 1, -2) -- chop
  editor:AutoCShow(0, list_str)
end

---
-- Show the scope/style at the current caret position as a calltip.
function show_scope()
  if not SCOPES_ENABLED then print('Scopes disabled') return end
  local lexer = editor.Lexer
  local scope = editor.StyleAt[editor.CurrentPos]
  local text = 'Lexer: '..lexer..'\nScope: '..scope
  editor:CallTipShow(editor.CurrentPos, text)
end

---
-- Display an inputdialog prompting a temporary snippet to insert.
function insert_temporary()
  if PLATFORM ~= 'linux' then print('Linux only') return end
  local text = inputdialog('Insert Temporary Snippet', 'Text:')
  if text then insert(text) end
end

---
-- [Local function] Gets the text of the snippet.
-- This is the text bounded by the start of the trigger word to
-- the end snippet marker on the line after the snippet's end.
snippet_text = function()
  local s = snippet.start_pos
  local e = editor:PositionFromLine(
    editor:MarkerLineFromHandle(snippet.end_marker) ) - 1
  if e < s then return nil, nil, nil end -- error
  return s, e, editor:textrange(s, e)
end

---
-- [Local function] Replace escaped snippet characters with their
-- octal equivalents.
escape = function(text)
  return string.gsub(text, '\\([$/}`])',
    function(char)
      return string.format( "\\%03d", string.byte(char) )
    end)
end

---
-- [Local function] Replace octal snippet characters with their
-- escaped equivalents.
unescape = function(text)
  return string.gsub(text, '\\(%d%d%d)',
    function(value)
      return '\\'..string.char(value)
    end)
end

---
-- [Local function] Remove escaping forward-slashes from escaped
-- snippet characters.
-- At this point, they are no longer necessary.
remove_escapes = function(text)
  return string.gsub(text, '\\([$/}`])', '%1')
end

---
-- [Local function] When snippets are inserted, match their
-- indentation level with their surroundings.
match_indention = function(ref_line, num_lines)
  if num_lines == 0 then return end
  local isize = editor.Indent
  local ibase = editor.LineIndentation[ref_line]
  local inum  = ibase / isize -- num of indents needed to match
  local line = ref_line + 1
  for i = 0, num_lines - 1 do
    local linei = editor.LineIndentation[line + i]
    editor.LineIndentation[line + i] = linei + isize * inum
  end
end

---
-- [Local function] Joins current line with the line below it,
-- eliminating whitespace.
-- This is used to remove the empty line containing the end of
-- snippet marker.
join_lines = function()
  editor:LineDown() editor:VCHome()
  if editor.Column[editor.CurrentPos] == 0 then
    editor:VCHome()
  end
  editor:HomeExtend()
  if string.len( editor:GetSelText() ) > 0 then
    editor:DeleteBack()
  end
  editor:DeleteBack()
end

---
-- [Local function] Called for printing debug text if DEBUG flag
-- is set.
-- @param text Debug text to print.
_DEBUG = function(text) if DEBUG then print('---\n'..text) end end

-- run tests
if RUN_TESTS then
  function next_item() next_snippet_item() end
  LUA_PATH = LUA_PATH or props['SciteDefaultHome']..'/scripts/'
  require 'utils/test_snippets'
end
