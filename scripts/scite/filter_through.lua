--[[
  Mitchell's filter_through.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.

  Textmate-like "filter through" command for the SciTE "bundle"

  Linux-only, uses inputdialog function (custom binary only),
  text options instead of a dialog

  API (see functions for descriptions):
    - FilterThrough.filter
    - FilterThrough.help

  Syntax:
    [$InputOption] command [$OutputOption]

    Note: PREFIX ('$' in this case) can be set to anything you
    wish, however all examples below will assume PREFIX is '$'.
    if command is '$HELP', this file will be shown.

    InputOptions:
      $N[ONE] - no input
      $S[EL]  - selection (unnecessary with selected text)
      $D[OC]  - document (unnecessary with no selected text)

    OutputOptions:
      $I[NS]  - insert output at current cursor position
      $S[SEL] - replace selected text with output (unnecessary
                with selected text)
      $D[OC]  - replaces document with output (unnecessary with
                no selected text)
      $N[EWDOC]  - places output in a new document
      $T[OOLTIP] - shows output in a tooltip
      $P[RINT]   - prints output in SciTE output pane

  Filter_through tries to use the best options applicable when
  no options are set. By default, if text is selected, it will be
  used as the input with the output being its replacement. If no
  text is selected, the entire document becomes the input and is
  replaced by the output.

]]--

-- platform specific options
local PLATFORM = PLATFORM or 'linux'
local PREFIX = '$'
local FILE_IN, FILE_OUT, INPUT, REDIRECT
if PLATFORM == 'linux' then
  FILE_IN  = '/tmp/scite_input'
  FILE_OUT = '/tmp/scite_output'
  INPUT    = ' < '
  REDIRECT = ' &> '
elseif PLATFORM == 'windows' then
  print('Sorry, scite/filter_through.lua is only for Linux')
end
-- end options

FilterThrough = {}

function FilterThrough.filter(...)
  if PLATFORM ~= 'linux' then print('Linux only') return end
  local command = not arg[1] and
    inputdialog('Filter Through', 'Command:') or arg[1]
  if command then
    if command == PREFIX..'HELP' then
      FilterThrough.help()
      return
    end

    -- determine what the input is from and output is to
    local input, output
    local input_regexes = {
      none      = '^'..PREFIX..'NO?N?E?%s+(.+)$',
      selection = '^'..PREFIX..'SE?L?%s+(.+)$',
      document  = '^'..PREFIX..'DO?C?%s+(.+)$'
    }
    local output_regexes = {
      insert    = '^(.-)%s+'..PREFIX..'IN?S?',
      selection = '^(.-)%s+'..PREFIX..'SE?L?$',
      document  = '^(.-)%s+'..PREFIX..'DO?C?$',
      new_doc   = '^(.-)%s+'..PREFIX..'NE?W?D?O?C?$',
      tooltip   = '^(.-)%s+'..PREFIX..'TO?O?L?T?I?P?$',
      ['print'] = '^(.-)%s+'..PREFIX..'PR?I?N?T?'
    }
    for key, regex in pairs(input_regexes) do
      _, _, cmd = string.find(command, regex)
      if cmd then command, input = cmd, key break end
    end
    for key, regex in pairs(output_regexes) do
      _, _, cmd = string.find(command, regex)
      if cmd then command, output = cmd, key break end
    end
    if not input and editor:GetSelText() ~= '' then
      input = 'selection'
    end
    input  = input or 'document'
    output = output or input
    -- if not output then output = input end
    if output == 'none' then output = 'insert' end

    -- perform filter command
    local f, txt, out
    if input ~= 'none' then
      txt = input == 'selection' and editor:GetSelText() or
        editor:GetText()
      f = io.open(FILE_IN, 'w') f:write(txt) f:close()
      os.execute(command..INPUT..FILE_IN..REDIRECT..FILE_OUT)
    else
      os.execute(command..REDIRECT..FILE_OUT)
    end
    f = io.open(FILE_OUT) out = f:read('*all') f:close()
    if txt and string.sub(txt, -1) ~= '\n' and
      string.sub(out, -1) == '\n' then
      out = string.sub(out, 1, -2) -- chomp
    end

    -- output the results appropriately
    if output == 'insert' then
      editor:AddText(out)
    elseif output == 'selection' then
      editor:ReplaceSel(out)
    elseif output == 'document' then
      editor:SetText(out)
    elseif output == 'new_doc' then
      scite.Open('')
      editor:SetText(out)
    elseif output == 'tooltip' then
      editor:CallTipShow(editor.CurrentPos, out)
    elseif output == 'print' then
      print(out)
    end
  end
end

-- displays syntax help for FilterThrough.filter
function FilterThrough.help()
  local help = [[
  Filter Through Command Help

  Syntax:
    [$InputOption] command [$OutputOption]

    Note: PREFIX ('$' in this case) can be set to anything you
    wish, however all examples below will assume PREFIX is '$'.
    if command is '$HELP', this file will be shown.

    InputOptions:
      $N[ONE] - no input
      $S[EL]  - selection (unnecessary with selected text)
      $D[OC]  - document (unnecessary with no selected text)

    OutputOptions:
      $I[NS]  - insert output at current cursor position
      $S[SEL] - replace selected text with output (unnecessary
                with selected text)
      $D[OC]  - replaces document with output (unnecessary with
                no selected text)
      $N[EWDOC]  - places output in a new document
      $T[OOLTIP] - shows output in a tooltip
      $P[RINT]   - prints output in SciTE output pane

  Filter_through tries to use the best options applicable when
  no options are set. By default, if text is selected, it will be
  used as the input with the output being its replacement. If no
  text is selected, the entire document becomes the input and is
  replaced by the output.]]
  help = string.gsub(help, '%$', PREFIX)
  print(help)
end
