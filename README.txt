Mitchell's SciTE Tools

Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

SciTE-tools homepage: http://caladbolg.net/scite.php
Send email to: mitchell<att>caladbolg<dott>net

All Lua and Ruby scripts are copyrighted by Mitchell Foral.
Permission is granted to use, copy, modify, and distribute
these files provided credit is given to Mitchell.

Check CHANGELOG.txt for recent updates

Repository Structure:
  / contains my Lua startup script and custom properties files.
  scripts/ contains a multitude of Lua scripts as modules.
  src/ contains customized Scintilla/SciTE code (as of v1.74).

Installation:
  All of these files should go into the SciteDefaultHome
  directory, typically located:
    Linux   - /usr/share/scite
    Windows - c:\Program Files\SciTE\
  Note in Linux if you change the directory, you must also change
  the SYSCONF_PATH in src/scite/gtk/makefile and recompile.

  Binaries:
    Platform-specific, custom binaries are located here:
      http://code.google.com/p/scite-tools/downloads/list
    Download the newest appropriate archive, unpack it, and move
    its contents into the SciteDefaultHome directory mentioned
    above.

Customizations:
  scintilla/
    * AutoCSeparator is '|', not '?'.
    * Calltip colors match dark color scheme.
    * Removed some default key commands:
      Ctrl+L, Ctrl+Shift+L, Ctrl+T, Ctrl+Shift+T, Ctrl+D,
      Ctrl+U, Ctrl+Shift+U.
  scite/
    * Added new Lua Extension functions:
      - scite.BufferPath([int] index)
        Returns the name of the buffer specified by index.
      - scite.SwitchToBuffer([int] index)
        Switches to the buffer specified by index.
      - scite.GetClipboardText()
        Returns the contents of the clipboard.
      - inputdialog(title, label [, default_text])
        [Linux only] Prompts the user to enter text into a dialog
        and returns it.
    * Implemented Lua Extension functions:
      - OnMacro(cmd, msg)
        cmd is either 'macro:startrecord', 'macro:record', or
        'macro:stoprecord' and msg is a ';' separated list of
        args that can be passed to scite.SendEditor.
    * Max of 100 commands on the Tools menu (instead of 50).
    * Literal newlines ('\n') can be used in api files.
    * 'caret.fore' property also applies to output pane.

Usage Notes:
  I run SciTE in Linux, so if you are running in Windows and use
  extension.lua, you must change the PLATFORM variable in it to
  'windows'. This will ensure all platform-specific operations will
  be executed correctly. If you are not using extension.lua, define
  a global PLATFORM variable with 'windows' as its value.

  Generally all platform-specific options are set properly for your
  platform based on PLATFORM, which does not need to be redefined
  in every script because its local value is inherited from the
  global value, but if unexpected problems occur, be sure to
  re-check those options.

  Some Lua scripts (in particular snippets.lua) utilize the Ruby
  programming language. If it is not installed on your system, you
  can get it from http://ruby-lang.org.

  If key commands are not working expected, check key_commands.lua
  (in scripts/scite/) and make sure the ALTERNATIVE_KEYS flag is
  set to false. I occasionally forget to reset the flag when I
  commit.

Additional Documentation:
  * Snippets and key commands documentation can be found in
    scripts/doc/.
  * Each of the Lua modules has inline documentation for every
    function and the LuaDocs can be found at:
    - http://caladbolg.net/scite/luadoc/scripts/index.html
