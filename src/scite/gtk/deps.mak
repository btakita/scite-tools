ifdef USELPEGLEX
SCINTILLA=scintilla-st
else
SCINTILLA=scintilla
endif

DirectorExtension.o: DirectorExtension.cxx \
  ../../$(SCINTILLA)/include/Platform.h ../../$(SCINTILLA)/include/PropSet.h \
  ../../$(SCINTILLA)/include/SString.h ../../$(SCINTILLA)/include/Scintilla.h \
  ../../$(SCINTILLA)/include/Accessor.h ../src/Extender.h \
  DirectorExtension.h ../src/SciTE.h ../src/FilePath.h ../src/SciTEBase.h
SciTEGTK.o: SciTEGTK.cxx ../../$(SCINTILLA)/include/Platform.h \
  ../src/SciTE.h ../../$(SCINTILLA)/include/PropSet.h \
  ../../$(SCINTILLA)/include/SString.h ../../$(SCINTILLA)/include/Accessor.h \
  ../../$(SCINTILLA)/include/KeyWords.h ../../$(SCINTILLA)/include/Scintilla.h \
  ../../$(SCINTILLA)/include/ScintillaWidget.h ../src/Extender.h \
  ../src/FilePath.h ../src/SciTEBase.h ../src/SciTEKeys.h ../src/MultiplexExtension.h \
  ../src/LuaExtension.h DirectorExtension.h pixmapsGNOME.h SciIcon.h
Exporters.o: ../src/Exporters.cxx ../../$(SCINTILLA)/include/Platform.h \
  ../src/SciTE.h ../../$(SCINTILLA)/include/PropSet.h \
  ../../$(SCINTILLA)/include/SString.h ../../$(SCINTILLA)/include/Accessor.h \
  ../../$(SCINTILLA)/include/WindowAccessor.h \
  ../../$(SCINTILLA)/include/Scintilla.h ../src/Extender.h \
  ../src/FilePath.h ../src/SciTEBase.h
IFaceTable.o: ../src/IFaceTable.cxx ../src/IFaceTable.h
ifdef LUA51
LuaExtension51.o: ../src/LuaExtension51.cxx \
  ../../$(SCINTILLA)/include/Scintilla.h ../../$(SCINTILLA)/include/Accessor.h \
  ../src/Extender.h ../src/LuaExtension.h \
  ../../$(SCINTILLA)/include/SString.h ../src/SciTEKeys.h \
  ../src/IFaceTable.h ../lua/include/lua.h ../lua/include/lualib.h \
  ../lua/include/lauxlib.h ../../$(SCINTILLA)/include/Platform.h
else
LuaExtension.o: ../src/LuaExtension.cxx \
  ../../$(SCINTILLA)/include/Scintilla.h ../../$(SCINTILLA)/include/Accessor.h \
  ../src/Extender.h ../src/LuaExtension.h \
  ../../$(SCINTILLA)/include/SString.h ../src/SciTEKeys.h \
  ../src/IFaceTable.h ../lua/include/lua.h ../lua/include/lualib.h \
  ../lua/include/lauxlib.h ../../$(SCINTILLA)/include/Platform.h
endif
MultiplexExtension.o: ../src/MultiplexExtension.cxx \
  ../src/MultiplexExtension.h ../src/Extender.h \
  ../../$(SCINTILLA)/include/Scintilla.h
SciTEBase.o: ../src/SciTEBase.cxx ../../$(SCINTILLA)/include/Platform.h \
  ../src/SciTE.h ../../$(SCINTILLA)/include/PropSet.h \
  ../../$(SCINTILLA)/include/SString.h ../../$(SCINTILLA)/include/Accessor.h \
  ../../$(SCINTILLA)/include/WindowAccessor.h \
  ../../$(SCINTILLA)/include/KeyWords.h ../../$(SCINTILLA)/include/Scintilla.h \
  ../../$(SCINTILLA)/include/ScintillaWidget.h \
  ../../$(SCINTILLA)/include/SciLexer.h ../src/Extender.h ../src/FilePath.h ../src/SciTEBase.h
SciTEBuffers.o: ../src/SciTEBuffers.cxx \
  ../../$(SCINTILLA)/include/Platform.h ../src/SciTE.h \
  ../../$(SCINTILLA)/include/PropSet.h ../../$(SCINTILLA)/include/SString.h \
  ../../$(SCINTILLA)/include/Accessor.h \
  ../../$(SCINTILLA)/include/WindowAccessor.h \
  ../../$(SCINTILLA)/include/Scintilla.h ../../$(SCINTILLA)/include/SciLexer.h \
  ../src/Extender.h ../src/FilePath.h ../src/SciTEBase.h
SciTEIO.o: ../src/SciTEIO.cxx ../../$(SCINTILLA)/include/Platform.h \
  ../src/SciTE.h ../../$(SCINTILLA)/include/PropSet.h \
  ../../$(SCINTILLA)/include/SString.h ../../$(SCINTILLA)/include/Accessor.h \
  ../../$(SCINTILLA)/include/WindowAccessor.h \
  ../../$(SCINTILLA)/include/Scintilla.h ../src/Extender.h ../src/Utf8_16.h \
  ../src/FilePath.h ../src/SciTEBase.h
SciTEProps.o: ../src/SciTEProps.cxx ../../$(SCINTILLA)/include/Platform.h \
  ../src/SciTE.h ../../$(SCINTILLA)/include/PropSet.h \
  ../../$(SCINTILLA)/include/SString.h ../../$(SCINTILLA)/include/Accessor.h \
  ../../$(SCINTILLA)/include/Scintilla.h ../../$(SCINTILLA)/include/SciLexer.h \
  ../src/Extender.h ../src/FilePath.h ../src/SciTEBase.h
Utf8_16.o: ../src/Utf8_16.cxx ../src/Utf8_16.h
