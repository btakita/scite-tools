Mitchell's SciTE Tools

Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

SciTE-tools homepage: http://caladbolg.net/scite.php
Send email to: mitchell<att>caladbolg<dott>net

All Lua and Ruby scripts are copyrighted by Mitchell Foral.
Permission is granted to use, copy, modify, and distribute
these files provided credit is given to Mitchell.

Check CHANGELOG.txt for recent updates

Repository Structure
--------------------

Source Code:

  / contains my Lua startup script and custom properties files
    that constitute a darker-theme for the Lexers I use:
      Bash, C/C++, CSS, default, HTML/XML, Java, Lua, Perl, PHP,
      Python, Ruby, and YAML.

  src/ contains customized Scintilla/SciTE code (as of v1.72)
    Linux and Windows customizations:
      AutoCSeparator is '|', not '?'
      Calltip colors match dark color scheme
      Added OnKey, scite.MenuCommand, scite.UpdateStatusBar,
        scite.Buffers, scite.SwitchToBuffer, and
        scite.GetClipboardText Lua Extension functions
      Max of 100 commands on the Tools menu (instead of 50)
      Literal newlines ('\n') can be used in api files
      Lua 5.0 or Lua 5.1 as the extension language
    Linux only customizations:
      inputdialog() Lua Extension function

  scripts/ contains a multitude of Lua scripts (or modules as
    sometimes referred to in the documentation) in "bundles".

  All of these files should go into the SciteDefaultHome
  directory, generally located:
    Linux   - /usr/share/scite
    Windows - c:\Program Files\SciTE\

Binaries:
  Platform-specific custom binaries are located here:
    http://code.google.com/p/scite-tools/downloads/list
  Download the newest appropriate archive, unpack it, and move
  its contents into the SciteDefaultHome directory mentioned
  above. (Binaries with '51' in their name use Lua 5.1 as the
  extension language.)

Usage Notes
-----------

IMPORTANT:
  I run SciTE in Linux, so if you are running in Windows and use
  extension.lua, you must change the PLATFORM variable in it to
  'windows'. This will ensure all platform-specific operations will
  be executed correctly. Also some of these functions rely on the
  Ruby programming language. Get it at http://ruby-lang.org

  Be sure to take a look at all scripts/*.lua files and change any
  platform-specific options that apply to your platform (if
  necessary). If you are using extension.lua, you do not have to
  reset any PLATFORM variables, as they are inherited from
  extension.lua

  By default, the repository assumes you are running the custom
  SciTE binary (see note about Binaries above). Some of the modules
  (including the key command manager) rely on the additional Lua
  Extension functions provided by the custom binary as well.

  Oh, and if you are using the custom binary and key commands are
  not working as you would expect, check key_commands.lua (in 
  scripts/scite/) and make sure the ALTERNATIVE_KEYS flag is set
  to false. I generally forget to reset the flag when I commit.

Additional Lua Extension Functions:
  OnKey([int] keyval, [bool] control, [bool] shift, [bool] alt)
    Upon a keypress in SciTE, this function will be called if
    available. The control, shift, and alt parameters are the
    modifiers to keyval. Typically string.char(keyval) will
    return the character associated with the key pressed, but
    this is not always the case in Windows. I have found no
    workaround yet.
  scite.MenuCommand([int] SCI_CONST)
    The list of SCI_CONSTs available is in SciTE.h. The number is
    required as the constant names are unavailable. This function
    calls the corresponding SciTE menu command (new, open, etc.)
  scite.UpdateStatusBar([bool] bUpdateSlowData=false)
    Updates SciTE's statusbar text. Set bUpdateSlowData to true
    if you want to update "slow" data like file permissions,
    current time, etc.
  scite.Buffers()
    Returns a list of the filenames of currently open buffers
    delimited by ';'s.
  scite.SwitchToBuffer([int] index)
    Switches to buffer specified by index
  scite.GetClipboardText()
    Returns the contents of the clipboard

  Note that scite.Buffers returns an ordered list of open buffers
  so you know which buffer is which when calling SwitchToBuffer.

Compiling SciTE with Lua 5.1
  Lua 5.1 support is still in testing phase. I have experienced
  no abnormalities with my scripts, but that doesn't mean bugs
  do not exist. Despite some of the big changes in Lua 5.1 dealing
  with changes in the language, most of the compatibility options
  have been turned on.
  Compatibilities:
    - table.getn still works, but the '#' operator should be used
    - Lua 5.0's varargs are still available
    - Lua 5.0's math.mod is still available, as well as 5.1's
      math.fmod
    - Lua 5.0's string.gfind is still available, as well as 5.1's
      string.gmatch
    - [C API] Lua 5.0's luaL_openlib behavior is still available
  Changes:
    - table.setn was deprecated
    - loadlib was moved into the package table (package.loadlib)
    - Lua 5.0's long string nesting throws an error

  In order to compile with Lua 5.1 (Lua 5.0 is used by default),
  build SciTE normally, but enabling the LUA51 flag.
    e.g. in Linux: 'make LUA51=1'
         in windows: 'nmake -f scite.mak LUA51=1'
  Note: I have not enabled this option in the mingw makefile for
  win32 because I have no means to test it. Patches are welcome.

  For clarity, the executables have been renamed SciTE51 and
  SciTE51.exe and do not overwrite existing SciTE and SciTE.exe
  binaries.

Linux Version Notes:
  Because I don't have any experience with Windows resource files,
  the inputdialog() Lua function only works in Linux.
  Syntax:
    result = inputdialog(title, label [, default_text])
  Description:
    The user is prompted to enter text into an input dialog, and
    that text is returned by the function.

Additional Documentation:
  Documentation for snippets usage is in scripts/snippets_doc.txt.
  Documentation for keys.lua usage is in scripts/key_doc.txt.
  Each of my Lua modules has documentation for every function
