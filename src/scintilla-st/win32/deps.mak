PlatWin.o: PlatWin.cxx ../include/Platform.h PlatformRes.h \
  ../src/UniConversion.h ../src/XPM.h
ScintillaWin.o: ScintillaWin.cxx ../include/Platform.h \
  ../include/Scintilla.h ../include/SString.h ../src/ContractionState.h \
  ../src/SVector.h ../src/CellBuffer.h ../src/CallTip.h ../src/KeyMap.h \
  ../src/Indicator.h ../src/XPM.h ../src/LineMarker.h ../src/Style.h \
  ../src/AutoComplete.h ../src/ViewStyle.h ../src/CharClassify.h ../src/Document.h \
  ../src/Editor.h ../src/ScintillaBase.h ../src/UniConversion.h
AutoComplete.o: ../src/AutoComplete.cxx ../include/Platform.h \
  ../include/PropSet.h ../include/SString.h ../src/AutoComplete.h
CallTip.o: ../src/CallTip.cxx ../include/Platform.h \
  ../include/Scintilla.h ../src/CallTip.h
CellBuffer.o: ../src/CellBuffer.cxx ../include/Platform.h \
  ../include/Scintilla.h ../src/SVector.h ../src/CellBuffer.h
CharClassify.o: ../src/CharClassify.cxx ../src/CharClassify.h
ContractionState.o: ../src/ContractionState.cxx ../include/Platform.h \
  ../src/ContractionState.h
Document.o: ../src/Document.cxx ../include/Platform.h \
  ../include/Scintilla.h ../src/SVector.h ../src/CellBuffer.h \
 ../src/CharClassify.h  ../src/Document.h ../src/RESearch.h
DocumentAccessor.o: ../src/DocumentAccessor.cxx ../include/Platform.h \
  ../include/PropSet.h ../include/SString.h ../src/SVector.h \
  ../include/Accessor.h ../src/DocumentAccessor.h ../src/CellBuffer.h \
  ../include/Scintilla.h ../src/CharClassify.h ../src/Document.h
Editor.o: ../src/Editor.cxx ../include/Platform.h ../include/Scintilla.h \
  ../src/ContractionState.h ../src/SVector.h ../src/CellBuffer.h \
  ../src/KeyMap.h ../src/Indicator.h ../src/XPM.h ../src/LineMarker.h \
  ../src/Style.h ../src/ViewStyle.h ../src/CharClassify.h ../src/Document.h ../src/Editor.h
ExternalLexer.o: ../src/ExternalLexer.cxx ../include/Platform.h \
  ../include/SciLexer.h ../include/PropSet.h ../include/SString.h \
  ../include/Accessor.h ../src/DocumentAccessor.h ../include/KeyWords.h \
  ../src/ExternalLexer.h
Indicator.o: ../src/Indicator.cxx ../include/Platform.h \
  ../include/Scintilla.h ../src/Indicator.h
KeyMap.o: ../src/KeyMap.cxx ../include/Platform.h ../include/Scintilla.h \
  ../src/KeyMap.h
KeyWords.o: ../src/KeyWords.cxx ../include/Platform.h \
  ../include/PropSet.h ../include/SString.h ../include/Accessor.h \
  ../include/KeyWords.h ../include/Scintilla.h ../include/SciLexer.h
LexLPeg.o: ../src/LexLPeg.cxx ../include/Platform.h ../include/Accessor.h \
  ../src/StyleContext.h ../include/PropSet.h ../include/SString.h \
  ../include/KeyWords.h ../include/SciLexer.h
LineMarker.o: ../src/LineMarker.cxx ../include/Platform.h \
  ../include/Scintilla.h ../src/XPM.h ../src/LineMarker.h
PropSet.o: ../src/PropSet.cxx ../include/Platform.h ../include/PropSet.h \
  ../include/SString.h
RESearch.o: ../src/RESearch.cxx ../src/RESearch.h
ScintillaBase.o: ../src/ScintillaBase.cxx ../include/Platform.h \
  ../include/Scintilla.h ../include/PropSet.h ../include/SString.h \
  ../src/ContractionState.h ../src/SVector.h ../src/CellBuffer.h \
  ../src/CallTip.h ../src/KeyMap.h ../src/Indicator.h ../src/XPM.h \
  ../src/LineMarker.h ../src/Style.h ../src/ViewStyle.h \
  ../src/AutoComplete.h ../src/CharClassify.h ../src/Document.h ../src/Editor.h \
  ../src/ScintillaBase.h
Style.o: ../src/Style.cxx ../include/Platform.h ../include/Scintilla.h \
  ../src/Style.h
StyleContext.o: ../src/StyleContext.cxx ../include/Platform.h \
  ../include/PropSet.h ../include/SString.h ../include/Accessor.h \
  ../src/StyleContext.h
UniConversion.o: ../src/UniConversion.cxx ../src/UniConversion.h
ViewStyle.o: ../src/ViewStyle.cxx ../include/Platform.h \
  ../include/Scintilla.h ../src/Indicator.h ../src/XPM.h \
  ../src/LineMarker.h ../src/Style.h ../src/ViewStyle.h
WindowAccessor.o: ../src/WindowAccessor.cxx ../include/Platform.h \
  ../include/PropSet.h ../include/SString.h ../include/Accessor.h \
  ../include/WindowAccessor.h ../include/Scintilla.h
XPM.o: ../src/XPM.cxx ../include/Platform.h ../src/XPM.h
