// SciTE - Scintilla based Text Editor
/** @file SciTEIO.cxx
 ** Manage input and output with the system.
 **/
// Copyright 1998-2003 by Neil Hodgson <neilh@scintilla.org>
// The License.txt file describes the conditions under which this software may be distributed.

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <fcntl.h>
#include <time.h>

#include "Platform.h"

#if PLAT_GTK

#include <unistd.h>
#include <gtk/gtk.h>

#endif

#if PLAT_WIN

#define _WIN32_WINNT  0x0400
#ifdef _MSC_VER
// windows.h, et al, use a lot of nameless struct/unions - can't fix it, so allow it
#pragma warning(disable: 4201)
#endif
#include <windows.h>
#ifdef _MSC_VER
// okay, that's done, don't allow it in our code
#pragma warning(default: 4201)
#endif
#include <commctrl.h>

// For chdir
#ifdef _MSC_VER
#include <direct.h>
#endif
#ifdef __BORLANDC__
#include <dir.h>
#endif

#endif

#include "SciTE.h"
#include "PropSet.h"
#include "Accessor.h"
#include "WindowAccessor.h"
#include "Scintilla.h"
#include "Extender.h"
#include "Utf8_16.h"
#include "FilePath.h"
#include "PropSetFile.h"
#include "SciTEBase.h"

#ifdef unix
const char propUserFileName[] = ".SciTEUser.properties";
#else
// Windows or VMS
const char propUserFileName[] = "SciTEUser.properties";
#endif
const char propGlobalFileName[] = "SciTEGlobal.properties";
const char propAbbrevFileName[] = "abbrev.properties";

#define PROPERTIES_EXTENSION	".properties"

static bool IsPropertiesFile(const FilePath &filename) {
	FilePath ext = filename.Extension();
	if (EqualCaseInsensitive(ext.AsInternal(), PROPERTIES_EXTENSION + 1))
		return true;
	return false;
}

void SciTEBase::SetFileName(FilePath openName, bool fixCase) {
	if (openName.AsInternal()[0] == '\"') {
		// openName is surrounded by double quotes
		char pathCopy[MAX_PATH + 1];
		strncpy(pathCopy, openName.AsInternal() + 1, MAX_PATH);
		pathCopy[MAX_PATH] = '\0';
		if (pathCopy[strlen(pathCopy) - 1] == '\"') {
			pathCopy[strlen(pathCopy) - 1] = '\0';
		}
		filePath.Set(pathCopy);
	} else {
		filePath.Set(openName);
	}

	// Break fullPath into directory and file name using working directory for relative paths
	if (!filePath.IsAbsolute()) {
		// Relative path. Since we ran AbsolutePath, we probably are here because fullPath is empty.
		filePath.SetDirectory(filePath.Directory());
	}

	if (fixCase) {
		filePath.FixName();
	}

	ReadLocalPropFile();

	props.Set("FilePath", filePath.AsFileSystem());
	props.Set("FileDir", filePath.Directory().AsFileSystem());
	props.Set("FileName", filePath.BaseName().AsFileSystem());
	props.Set("FileExt", filePath.Extension().AsFileSystem());
	props.Set("FileNameExt", FileNameExt().AsFileSystem());

	SetWindowName();
	if (buffers.buffers)
		buffers.buffers[buffers.Current()].Set(filePath);
	BuffersMenu();
}

// See if path exists.
// If path is not absolute, it is combined with dir.
// If resultPath is not NULL, it receives the absolute path if it exists.
bool SciTEBase::Exists(const char *dir, const char *path, FilePath *resultPath) {
	FilePath copy(path);
	if (!copy.IsAbsolute() && dir) {
		copy.SetDirectory(dir);
	}
	if (!copy.Exists())
		return false;
	if (resultPath) {
		resultPath->Set(copy.AbsolutePath());
	}
	return true;
}

void SciTEBase::CountLineEnds(int &linesCR, int &linesLF, int &linesCRLF) {
	linesCR = 0;
	linesLF = 0;
	linesCRLF = 0;
	int lengthDoc = LengthDocument();
	char chPrev = ' ';
	WindowAccessor acc(wEditor.GetID(), props);
	for (int i = 0; i < lengthDoc; i++) {
		char ch = acc[i];
		char chNext = acc.SafeGetCharAt(i + 1);
		if (ch == '\r') {
			if (chNext == '\n')
				linesCRLF++;
			else
				linesCR++;
		} else if (ch == '\n') {
			if (chPrev != '\r') {
				linesLF++;
			}
		}
		chPrev = ch;
	}
}

static bool isEncodingChar(char ch) {
	return (ch == '_') || (ch == '-') || (ch == '.') ||
	       (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') ||
	       (ch >= '0' && ch <= '9');
}

static bool isSpaceChar(char ch) {
	return (ch == ' ') || (ch == '\t');
}

static SString ExtractLine(const char *buf, size_t length) {
	unsigned int endl = 0;
	if (length > 0) {
		while ((endl < length) && (buf[endl] != '\r') && (buf[endl] != '\n')) {
			endl++;
		}
		if (((endl + 1) < length) && (buf[endl] == '\r') && (buf[endl+1] == '\n')) {
			endl++;
		}
		if (endl < length) {
			endl++;
		}
	}
	return SString(buf, 0, endl);
}

static const char codingCookie[] = "coding";

static UniMode CookieValue(const SString &s) {
	int posCoding = s.search(codingCookie);
	if (posCoding >= 0) {
		posCoding += static_cast<int>(strlen(codingCookie));
		if ((s[posCoding] == ':') || (s[posCoding] == '=')) {
			posCoding++;
			if ((s[posCoding] == '\"') || (s[posCoding] == '\'')) {
				posCoding++;
			}
			while ((posCoding < static_cast<int>(s.length())) &&
			        (isSpaceChar(s[posCoding]))) {
				posCoding++;
			}
			size_t endCoding = static_cast<size_t>(posCoding);
			while ((endCoding < s.length()) &&
			        (isEncodingChar(s[endCoding]))) {
				endCoding++;
			}
			SString code(s.c_str(), posCoding, endCoding);
			code.lowercase();
			if (code == "utf-8") {
				return uniCookie;
			}
		}
	}
	return uni8Bit;
}

static UniMode CodingCookieValue(const char *buf, size_t length) {
	SString l1 = ExtractLine(buf, length);
	UniMode unicodeMode = CookieValue(l1);
	if (unicodeMode == uni8Bit) {
		SString l2 = ExtractLine(buf + l1.length(), length - l1.length());
		unicodeMode = CookieValue(l2);
	}
	return unicodeMode;
}

void SciTEBase::DiscoverEOLSetting() {
	int linesCR;
	int linesLF;
	int linesCRLF;
	SetEol();
	CountLineEnds(linesCR, linesLF, linesCRLF);
	if (((linesLF >= linesCR) && (linesLF > linesCRLF)) || ((linesLF > linesCR) && (linesLF >= linesCRLF)))
		SendEditor(SCI_SETEOLMODE, SC_EOL_LF);
	else if (((linesCR >= linesLF) && (linesCR > linesCRLF)) || ((linesCR > linesLF) && (linesCR >= linesCRLF)))
		SendEditor(SCI_SETEOLMODE, SC_EOL_CR);
	else if (((linesCRLF >= linesLF) && (linesCRLF > linesCR)) || ((linesCRLF > linesLF) && (linesCRLF >= linesCR)))
		SendEditor(SCI_SETEOLMODE, SC_EOL_CRLF);
}

// Look inside the first line for a #! clue regarding the language
SString SciTEBase::DiscoverLanguage(const char *buf, size_t length) {
	SString languageOverride = "";
	SString l1 = ExtractLine(buf, length);
	if (l1.startswith("<?xml")) {
		languageOverride = "xml";
	} else if (l1.startswith("#!")) {
		l1 = l1.substr(2);
		l1.substitute('\\', ' ');
		l1.substitute('/', ' ');
		l1.substitute("\t", " ");
		l1.substitute("  ", " ");
		l1.substitute("  ", " ");
		l1.substitute("  ", " ");
		l1.remove("\r");
		l1.remove("\n");
		if (l1.startswith(" ")) {
			l1 = l1.substr(1);
		}
		l1.substitute(' ', '\0');
		const char *word = l1.c_str();
		while (*word) {
			SString propShBang("shbang.");
			propShBang.append(word);
			SString langShBang = props.GetExpanded(propShBang.c_str());
			if (langShBang.length()) {
				languageOverride = langShBang;
			}
			word += strlen(word) + 1;
		}
	}
	if (languageOverride.length()) {
		languageOverride.insert(0, "x.");
	}
	return languageOverride;
}

void SciTEBase::DiscoverIndentSetting() {
	int lengthDoc = LengthDocument();
	WindowAccessor acc(wEditor.GetID(), props);
	bool newline = true;
	int indent = 0; // current line indentation
	int tabSizes[9] = { 0, 0, 0, 0, 0, 0, 0, 0, 0 }; // number of lines with corresponding indentation (index 0 - tab)
	int prevIndent = 0; // previous line indentation
	int prevTabSize = -1; // previous line tab size
	for (int i = 0; i < lengthDoc; i++) {
		char ch = acc[i];
		if (ch == '\r' || ch == '\n') {
			indent = 0;
			newline = true;
		} else if (newline && ch == ' ') {
			indent++;
		} else if (newline) {
			if (indent) {
				if (indent == prevIndent && prevTabSize != -1) {
					tabSizes[prevTabSize]++;
				} else if (indent > prevIndent && prevIndent != -1) {
					if (indent - prevIndent <= 8) {
						prevTabSize = indent - prevIndent;
						tabSizes[prevTabSize]++;
					} else {
						prevTabSize = -1;
					}
				}
				prevIndent = indent;
			} else if (ch == '\t') {
				tabSizes[0]++;
				prevIndent = -1;
			} else {
				prevIndent = 0;
			}
			newline = false;
		}
	}
	// maximum non-zero indent
	int topTabSize = -1;
	for (int j = 0; j <= 8; j++) {
		if (tabSizes[j] && (topTabSize == -1 || tabSizes[j] > tabSizes[topTabSize])) {
			topTabSize = j;
		}
	}
	// set indentation
	if (topTabSize == 0) {
		SendEditor(SCI_SETUSETABS, 1);
	} else if (topTabSize != -1) {
		SendEditor(SCI_SETUSETABS, 0);
		SendEditor(SCI_SETINDENT, topTabSize);
	}
}

void SciTEBase::OpenFile(int fileSize, bool suppressMessage) {
	Utf8_16_Read convert;

	FILE *fp = filePath.Open(fileRead);
	if (fp) {
		CurrentBuffer()->SetTimeFromFile();
		SendEditor(SCI_BEGINUNDOACTION);	// Group together clear and insert
		SendEditor(SCI_CLEARALL);
		char data[blockSize];
		size_t lenFile = fread(data, 1, sizeof(data), fp);
		UniMode codingCookie = CodingCookieValue(data, lenFile);
		SendEditor(SCI_ALLOCATE, fileSize + 1000);
		SString languageOverride;
		bool firstBlock = true;
		while (lenFile > 0) {
			lenFile = convert.convert(data, lenFile);
			char *dataBlock = convert.getNewBuf();
			if ((firstBlock) && (language == "")) {
				languageOverride = DiscoverLanguage(dataBlock, lenFile);
			}
			firstBlock = false;
			SendEditorString(SCI_ADDTEXT, lenFile, dataBlock);
			lenFile = fread(data, 1, sizeof(data), fp);
		}
		fclose(fp);
		SendEditor(SCI_ENDUNDOACTION);
		if (languageOverride.length()) {
			CurrentBuffer()->overrideExtension = languageOverride;
			ReadProperties();
			SetIndentSettings();
		}
		CurrentBuffer()->unicodeMode = static_cast<UniMode>(
		            static_cast<int>(convert.getEncoding()));
		// Check the first two lines for coding cookies
		if (CurrentBuffer()->unicodeMode == uni8Bit) {
			CurrentBuffer()->unicodeMode = codingCookie;
		}
		if (CurrentBuffer()->unicodeMode != uni8Bit) {
			// Override the code page if Unicode
			codePage = SC_CP_UTF8;
		} else {
			codePage = props.GetInt("code.page");
		}
		SendEditor(SCI_SETCODEPAGE, codePage);

		if (props.GetInt("eol.auto")) {
			DiscoverEOLSetting();
		}

		if (props.GetInt("indent.auto")) {
			DiscoverIndentSetting();
		}

	} else if (!suppressMessage) {
		SString msg = LocaliseMessage("Could not open file '^0'.", filePath.AsFileSystem());
		WindowMessageBox(wSciTE, msg, MB_OK | MB_ICONWARNING);
	}
	SendEditor(SCI_SETUNDOCOLLECTION, 1);
	// Flick focus to the output window and back to
	// ensure palette realised correctly.
	WindowSetFocus(wOutput);
	WindowSetFocus(wEditor);
	SendEditor(SCI_SETSAVEPOINT);
	if (props.GetInt("fold.on.open") > 0) {
		FoldAll();
	}
	SendEditor(SCI_GOTOPOS, 0);
	Redraw();
}

bool SciTEBase::PreOpenCheck(const char *) {
	return false;
}

bool SciTEBase::Open(FilePath file, OpenFlags of) {
	InitialiseBuffers();

#ifdef __vms
	file = file.VMSToUnixStyle();
#endif
	FilePath absPath = file.AbsolutePath();
	int index = buffers.GetDocumentByName(absPath);
	if (index >= 0) {
		SetDocumentAt(index);
		DeleteFileStackMenu();
		SetFileStackMenu();
		if (!(of & ofForceLoad)) // Just rotate into view
			return true;
	}
	// See if we can have a buffer for the file to open
	if (!CanMakeRoom(!(of & ofNoSaveIfDirty))) {
		return false;
	}

	int size = absPath.GetFileLength();
	if (size > 0) {
		// Real file, not empty buffer
		int maxSize = props.GetInt("max.file.size");
		if (maxSize > 0 && size > maxSize) {
			SString sSize(size), sMaxSize(maxSize);
			SString msg = LocaliseMessage("File '^0' is ^1 bytes long,\n"
			        "larger than the ^2 bytes limit set in the properties.\n"
			        "Do you still want to open it?",
			        absPath.AsFileSystem(), sSize.c_str(), sMaxSize.c_str());
			int answer = WindowMessageBox(wSciTE, msg, MB_YESNO | MB_ICONWARNING);
			if (answer != IDYES) {
				return false;
			}
		}
	}

	if (buffers.size == buffers.length) {
		AddFileToStack(filePath, GetSelection(), GetCurrentScrollPosition());
		ClearDocument();
		if (extender)
			extender->InitBuffer(buffers.Current());
	} else {
		if (index < 0 || !(of & ofForceLoad)) { // No new buffer, already opened
			New();
		}
	}

	//Platform::DebugPrintf("Opening %s\n", file);
	SetFileName(absPath);
	CurrentBuffer()->overrideExtension = "";
	ReadProperties();
	SetIndentSettings();
	UpdateBuffersCurrent();
	SizeSubWindows();

	if (!filePath.IsUntitled()) {
		SendEditor(SCI_SETREADONLY, 0);
		SendEditor(SCI_CANCEL);
		if (of & ofPreserveUndo) {
			SendEditor(SCI_BEGINUNDOACTION);
		} else {
			SendEditor(SCI_SETUNDOCOLLECTION, 0);
		}

		OpenFile(size, of & ofQuiet);

		if (of & ofPreserveUndo) {
			SendEditor(SCI_ENDUNDOACTION);
		} else {
			SendEditor(SCI_EMPTYUNDOBUFFER);
		}
		isReadOnly = props.GetInt("read.only");
		SendEditor(SCI_SETREADONLY, isReadOnly);
	}
	RemoveFileFromStack(filePath);
	DeleteFileStackMenu();
	SetFileStackMenu();
	SetWindowName();
	if (lineNumbers && lineNumbersExpand)
		SetLineNumberWidth();
	UpdateStatusBar(true);
	if (extender)
		extender->OnOpen(filePath.AsFileSystem());
	return true;
}

// Returns true if editor should get the focus
bool SciTEBase::OpenSelected() {
	char selectedFilename[MAX_PATH];
	char cTag[200];
	unsigned long lineNumber = 0;

	SString selName = SelectionFilename();
	strncpy(selectedFilename, selName.c_str(), MAX_PATH);
	selectedFilename[MAX_PATH - 1] = '\0';
	if (selectedFilename[0] == '\0') {
		WarnUser(warnWrongFile);
		return false;	// No selection
	}
	SString fileNameForExtension = ExtensionFileName();
	SString openSuffix = props.GetNewExpand("open.suffix.", fileNameForExtension.c_str());
	strcat(selectedFilename, openSuffix.c_str());

	if (EqualCaseInsensitive(selectedFilename, FileNameExt().AsInternal()) || EqualCaseInsensitive(selectedFilename, filePath.AsInternal())) {
		WarnUser(warnWrongFile);
		return true;	// Do not open if it is the current file!
	}

	cTag[0] = '\0';
	if (IsPropertiesFile(filePath) &&
	        strchr(selectedFilename, '.') == 0 &&
	        strlen(selectedFilename) + strlen(PROPERTIES_EXTENSION) < MAX_PATH) {
		// We are in a properties file and try to open a file without extension,
		// we suppose we want to open an imported .properties file
		// So we append the correct extension to open the included file.
		// Maybe we should check if the filename is preceded by "import"...
		strcat(selectedFilename, PROPERTIES_EXTENSION);
	} else {
		// Check if we have a line number (error message or grep result)
		// A bit of duplicate work with DecodeMessage, but we don't know
		// here the format of the line, so we do guess work.
		// Can't do much for space separated line numbers anyway...
		char *endPath = strchr(selectedFilename, '(');
		if (endPath) {	// Visual Studio error message: F:\scite\src\SciTEBase.h(312):	bool Exists(
			lineNumber = atol(endPath + 1);
		} else {
			endPath = strchr(selectedFilename + 2, ':');	// Skip Windows' drive separator
			if (endPath) {	// grep -n line, perhaps gcc too: F:\scite\src\SciTEBase.h:312:	bool Exists(
				lineNumber = atol(endPath + 1);
			}
		}
		if (lineNumber > 0) {
			*endPath = '\0';
		}

#if PLAT_WIN
		if (strncmp(selectedFilename, "http:", 5) == 0 ||
		        strncmp(selectedFilename, "https:", 6) == 0 ||
		        strncmp(selectedFilename, "ftp:", 4) == 0 ||
		        strncmp(selectedFilename, "ftps:", 5) == 0 ||
		        strncmp(selectedFilename, "news:", 5) == 0 ||
		        strncmp(selectedFilename, "mailto:", 7) == 0) {
			SString cmd = selectedFilename;
			AddCommand(cmd, "", jobShell);
			return false;	// Job is done
		}
#endif

		// Support the ctags format

		if (lineNumber == 0) {
			GetCTag(cTag, sizeof(cTag));
		}
	}

	FilePath path;
	// Don't load the path of the current file if the selected
	// filename is an absolute pathname
	if (!FilePath(selectedFilename).IsAbsolute()) {
		path = filePath.Directory();
		// If not there, look in openpath
		if (!Exists(path.AsInternal(), selectedFilename, NULL)) {
			SString openPath = props.GetNewExpand(
			            "openpath.", fileNameForExtension.c_str());
			while (openPath.length()) {
				SString tryPath(openPath);
				int sepIndex = tryPath.search(listSepString);
				if (sepIndex > 0) {
					tryPath.remove(sepIndex, 0);
					openPath.remove(0, sepIndex + 1);
				} else {
					openPath.clear();
				}
				if (Exists(tryPath.c_str(), selectedFilename, NULL)) {
					path.Set(tryPath.c_str());
					break;
				}
			}
		}
	}
	FilePath pathReturned;
	if (Exists(path.AsInternal(), selectedFilename, &pathReturned)) {
		if (Open(pathReturned)) {
			if (lineNumber > 0) {
				SendEditor(SCI_GOTOLINE, lineNumber - 1);
			} else if (cTag[0] != '\0') {
				if (atol(cTag) > 0) {
					SendEditor(SCI_GOTOLINE, atol(cTag) - 1);
				} else {
					findWhat = cTag;
					FindNext(false);
				}
			}
			return true;
		}
	} else {
		WarnUser(warnWrongFile);
	}
	return false;
}

void SciTEBase::Revert() {
	RecentFile rf = GetFilePosition();
	OpenFile(filePath.GetFileLength(), false);
	DisplayAround(rf);
}

void SciTEBase::CheckReload() {
	if (props.GetInt("load.on.activate")) {
		// Make a copy of fullPath as otherwise it gets aliased in Open
		time_t newModTime = filePath.ModifiedTime();
		//Platform::DebugPrintf("Times are %d %d\n", CurrentBuffer()->fileModTime, newModTime);
		if (newModTime > CurrentBuffer()->fileModTime) {
			RecentFile rf = GetFilePosition();
			OpenFlags of = props.GetInt("reload.preserves.undo") ? ofPreserveUndo : ofNone;
			if (CurrentBuffer()->isDirty || props.GetInt("are.you.sure.on.reload") != 0) {
				if ((0 == dialogsOnScreen) && (newModTime != CurrentBuffer()->fileModLastAsk)) {
					SString msg;
					if (CurrentBuffer()->isDirty) {
						msg = LocaliseMessage(
						          "The file '^0' has been modified. Should it be reloaded?",
						          filePath.AsFileSystem());
					} else {
						msg = LocaliseMessage(
						          "The file '^0' has been modified outside SciTE. Should it be reloaded?",
						          FileNameExt().AsFileSystem());
					}
					int decision = WindowMessageBox(wSciTE, msg, MB_YESNO);
					if (decision == IDYES) {
						Open(filePath, static_cast<OpenFlags>(of | ofForceLoad));
						DisplayAround(rf);
					}
					CurrentBuffer()->fileModLastAsk = newModTime;
				}
			} else {
				Open(filePath, static_cast<OpenFlags>(of | ofForceLoad));
				DisplayAround(rf);
			}
		}
	}
}

void SciTEBase::Activate(bool activeApp) {
	if (activeApp) {
		CheckReload();
	} else {
		if (props.GetInt("save.on.deactivate")) {
			SaveTitledBuffers();
		}
	}
}

FilePath SciTEBase::SaveName(const char *ext) {
	SString savePath = filePath.AsInternal();
	if (ext) {
		int dot = savePath.length() - 1;
		while ((dot >= 0) && (savePath[dot] != '.')) {
			dot--;
		}
		if (dot >= 0) {
			int keepExt = props.GetInt("export.keep.ext");
			if (keepExt == 0) {
				savePath.remove(dot, 0);
			} else if (keepExt == 2) {
				savePath.change(dot, '_');
			}
		}
		savePath.append(ext);
	}
	//~ fprintf(stderr, "SaveName <%s> <%s> <%s>\n", filePath.AsInternal(), savePath.c_str(), ext);
	return FilePath(savePath.c_str());
}

int SciTEBase::SaveIfUnsure(bool forceQuestion) {
	if ((CurrentBuffer()->isDirty) && (LengthDocument() || !filePath.IsUntitled() || forceQuestion)) {
		if (props.GetInt("are.you.sure", 1) ||
		        filePath.IsUntitled() ||
		        forceQuestion) {
			SString msg;
			if (!filePath.IsUntitled()) {
				msg = LocaliseMessage("Save changes to '^0'?", filePath.AsFileSystem());
			} else {
				msg = LocaliseMessage("Save changes to (Untitled)?");
			}
			int decision = WindowMessageBox(wSciTE, msg, MB_YESNOCANCEL | MB_ICONQUESTION);
			if (decision == IDYES) {
				if (!Save())
					decision = IDCANCEL;
			}
			return decision;
		} else {
			if (!Save())
				return IDCANCEL;
		}
	}
	return IDYES;
}

int SciTEBase::SaveIfUnsureAll(bool forceQuestion) {
	if (SaveAllBuffers(forceQuestion) == IDCANCEL) {
		return IDCANCEL;
	}
	if (props.GetInt("save.recent")) {
		for (int i = 0; i < buffers.length; ++i) {
			Buffer buff = buffers.buffers[i];
			AddFileToStack(buff, buff.selection, buff.scrollPosition);
		}
		SaveRecentStack();
	}
	if (props.GetInt("buffers") && props.GetInt("save.session"))
		SaveSession("");

	// Definitely going to exit now, so delete all documents
	// Set editor back to initial document
	SendEditor(SCI_SETDOCPOINTER, 0, buffers.buffers[0].doc);
	// Release all the extra documents
	for (int j = 0; j < buffers.size; j++) {
		if (buffers.buffers[j].doc)
			SendEditor(SCI_RELEASEDOCUMENT, 0, buffers.buffers[j].doc);
	}
	// Initial document will be deleted when editor deleted
	return IDYES;
}

int SciTEBase::SaveIfUnsureForBuilt() {
	if (props.GetInt("save.all.for.build")) {
		return SaveAllBuffers(false, !props.GetInt("are.you.sure.for.build"));
	}
	if (CurrentBuffer()->isDirty) {
		if (props.GetInt("are.you.sure.for.build"))
			return SaveIfUnsure(true);

		Save();
	}
	return IDYES;
}

void SciTEBase::StripTrailingSpaces() {
	int maxLines = SendEditor(SCI_GETLINECOUNT);
	for (int line = 0; line < maxLines; line++) {
		int lineStart = SendEditor(SCI_POSITIONFROMLINE, line);
		int lineEnd = SendEditor(SCI_GETLINEENDPOSITION, line);
		int i = lineEnd - 1;
		char ch = static_cast<char>(SendEditor(SCI_GETCHARAT, i));
		while ((i >= lineStart) && ((ch == ' ') || (ch == '\t'))) {
			i--;
			ch = static_cast<char>(SendEditor(SCI_GETCHARAT, i));
		}
		if (i < (lineEnd - 1)) {
			SendEditor(SCI_SETTARGETSTART, i + 1);
			SendEditor(SCI_SETTARGETEND, lineEnd);
			SendEditorString(SCI_REPLACETARGET, 0, "");
		}
	}
}

void SciTEBase::EnsureFinalNewLine() {
	int maxLines = SendEditor(SCI_GETLINECOUNT);
	bool appendNewLine = maxLines == 1;
	int endDocument = SendEditor(SCI_POSITIONFROMLINE, maxLines);
	if (maxLines > 1) {
		appendNewLine = endDocument > SendEditor(SCI_POSITIONFROMLINE, maxLines - 1);
	}
	if (appendNewLine) {
		const char *eol = "\n";
		switch (SendEditor(SCI_GETEOLMODE)) {
		case SC_EOL_CRLF:
			eol = "\r\n";
			break;
		case SC_EOL_CR:
			eol = "\r";
			break;
		}
		SendEditorString(SCI_INSERTTEXT, endDocument, eol);
	}
}

/**
 * Writes the buffer to the given filename.
 */
bool SciTEBase::SaveBuffer(FilePath saveName) {
	bool retVal = false;
	// Perform clean ups on text before saving
	SendEditor(SCI_BEGINUNDOACTION);
	if (props.GetInt("strip.trailing.spaces"))
		StripTrailingSpaces();
	if (props.GetInt("ensure.final.line.end"))
		EnsureFinalNewLine();
	if (props.GetInt("ensure.consistent.line.ends"))
		SendEditor(SCI_CONVERTEOLS, SendEditor(SCI_GETEOLMODE));

	if (extender)
		extender->OnBeforeSave(saveName.AsFileSystem());

	SendEditor(SCI_ENDUNDOACTION);

	Utf8_16_Write convert;
	if (CurrentBuffer()->unicodeMode != uniCookie) {	// Save file with cookie without BOM.
		convert.setEncoding(static_cast<Utf8_16::encodingType>(
		            static_cast<int>(CurrentBuffer()->unicodeMode)));
	}

	FILE *fp = saveName.Open(fileWrite);
	if (fp) {
		convert.setfile(fp);
		char data[blockSize + 1];
		int lengthDoc = LengthDocument();
		retVal = true;
		int grabSize;
		for (int i = 0; i < lengthDoc; i += grabSize) {
			grabSize = lengthDoc - i;
			if (grabSize > blockSize)
				grabSize = blockSize;
			// Round down so only whole characters retrieved.
			grabSize = SendEditor(SCI_POSITIONBEFORE, i + grabSize + 1) - i;
			GetRange(wEditor, i, i + grabSize, data);
			size_t written = convert.fwrite(data, grabSize);
			if (written == 0) {
				retVal = false;
				break;
			}
		}
		convert.fclose();

		if (extender)
			extender->OnSave(saveName.AsFileSystem());
	}
	UpdateStatusBar(true);
	return retVal;
}

void SciTEBase::ReloadProperties() {
	ReadGlobalPropFile();
	SetImportMenu();
	ReadLocalPropFile();
	ReadAbbrevPropFile();
	ReadProperties();
	SetWindowName();
	BuffersMenu();
	Redraw();
}

// Returns false if cancelled or failed to save
bool SciTEBase::Save() {
	if (!filePath.IsUntitled()) {
		if (props.GetInt("save.deletes.first")) {
			filePath.Remove();
		}

		if (SaveBuffer(filePath)) {
			CurrentBuffer()->SetTimeFromFile();
			SendEditor(SCI_SETSAVEPOINT);
			if (IsPropertiesFile(filePath)) {
				ReloadProperties();
			}
		} else {
			SString msg = LocaliseMessage(
			            "Could not save file '^0'. Save under a different name?", filePath.AsFileSystem());
			int decision = WindowMessageBox(wSciTE, msg, MB_YESNO | MB_ICONWARNING);
			if (decision == IDYES) {
				return SaveAsDialog();
			}
			return false;
		}
		return true;
	} else {
		return SaveAsDialog();
	}
}

void SciTEBase::SaveAs(const char *file) {
	SetFileName(file);
	Save();
	ReadProperties();
	SendEditor(SCI_CLEARDOCUMENTSTYLE);
	SendEditor(SCI_COLOURISE, 0, -1);
	Redraw();
	SetWindowName();
	BuffersMenu();
}

bool SciTEBase::IsStdinBlocked() {
	return false; /* always default to blocked */
}

void SciTEBase::OpenFromStdin(bool UseOutputPane) {
	Utf8_16_Read convert;
	char data[blockSize];

	/* if stdin is blocked, do not execute this method */
	if (IsStdinBlocked())
		return;

	Open("");
	if (UseOutputPane) {
		SendOutput(SCI_CLEARALL);
	} else {
		SendEditor(SCI_BEGINUNDOACTION);	// Group together clear and insert
		SendEditor(SCI_CLEARALL);
	}
	size_t lenFile = fread(data, 1, sizeof(data), stdin);
	UniMode codingCookie = CodingCookieValue(data, lenFile);
	while (lenFile > 0) {
		lenFile = convert.convert(data, lenFile);
		if (UseOutputPane) {
			SendOutputString(SCI_ADDTEXT, lenFile, convert.getNewBuf());
		} else {
			SendEditorString(SCI_ADDTEXT, lenFile, convert.getNewBuf());
		}
		lenFile = fread(data, 1, sizeof(data), stdin);
	}
	if (UseOutputPane) {
		if (props.GetInt("split.vertical") == 0) {
			heightOutput = 2000;
		} else {
			heightOutput = 500;
		}
		SizeSubWindows();
	} else {
		SendEditor(SCI_ENDUNDOACTION);
	}
	CurrentBuffer()->unicodeMode = static_cast<UniMode>(
	            static_cast<int>(convert.getEncoding()));
	// Check the first two lines for coding cookies
	if (CurrentBuffer()->unicodeMode == uni8Bit) {
		CurrentBuffer()->unicodeMode = codingCookie;
	}
	if (CurrentBuffer()->unicodeMode != uni8Bit) {
		// Override the code page if Unicode
		codePage = SC_CP_UTF8;
	} else {
		codePage = props.GetInt("code.page");
	}
	if (UseOutputPane) {
		SendOutput(SCI_SETSEL, 0, 0);
	} else {
		SendEditor(SCI_SETCODEPAGE, codePage);

		// Zero all the style bytes
		SendEditor(SCI_CLEARDOCUMENTSTYLE);

		CurrentBuffer()->overrideExtension = "x.txt";
		ReadProperties();
		SetIndentSettings();
		SendEditor(SCI_COLOURISE, 0, -1);
		Redraw();

		SendEditor(SCI_SETSEL, 0, 0);
	}
}

void SciTEBase::OpenFilesFromStdin() {
	char data[blockSize];
	char *pNL;

	/* if stdin is blocked, do not execute this method */
	if (IsStdinBlocked())
		return;

	while (fgets(data, sizeof(data) - 1, stdin)) {
		if ((pNL = strchr(data, '\n')) != NULL)
			* pNL = '\0';
		Open(data, ofQuiet);
	}
	if (buffers.length == 0)
		Open("");
}

class BufferedFile {
	FILE *fp;
	bool readAll;
	bool exhausted;
	enum {bufLen = 64 * 1024};
	char buffer[bufLen];
	size_t pos;
	size_t valid;
	void EnsureData() {
		if (pos >= valid) {
			if (readAll) {
				exhausted = true;
			} else {
				valid = fread(buffer, 1, bufLen, fp);
				if (valid < bufLen) {
					readAll = true;
				}
				pos = 0;
			}
		}
	}
public:
	BufferedFile(FilePath fPath) {
		fp = fPath.Open(fileRead);
		readAll = false;
		exhausted = fp == NULL;
		pos = 0;
		valid = 0;
	}
	~BufferedFile() {
		if (fp) {
			fclose(fp);
		}
		fp = NULL;
	}
	bool Exhausted() {
		return exhausted;
	}
	int NextByte() {
		EnsureData();
		if (pos >= valid) {
			return 0;
		}
		return buffer[pos++];
	}
	bool BufferContainsNull() {
		EnsureData();
		for (size_t i = 0;i < valid;i++) {
			if (buffer[i] == '\0')
				return true;
		}
		return false;
	}
};

class FileReader {
	BufferedFile *bf;
	int lineNum;
	bool lastWasCR;
	enum {bufLen = 1000};
	char lineToCompare[bufLen+1];
	char lineToShow[bufLen+1];
	bool caseSensitive;
public:

	FileReader(FilePath fPath, bool caseSensitive_) {
		bf = new BufferedFile(fPath);
		lineNum = 0;
		lastWasCR = false;
		caseSensitive = caseSensitive_;
	}
	~FileReader() {
		delete bf;
		bf = NULL;
	}
	char *Next() {
		if (bf->Exhausted()) {
			return NULL;
		}
		int i = 0;
		while (!bf->Exhausted()) {
			int ch = bf->NextByte();
			if (i == 0 && lastWasCR && ch == '\n') {
				lastWasCR = false;
				ch = 0;
			} else if (ch == '\r' || ch == '\n') {
				lastWasCR = ch == '\r';
				break;
			} else if (i < bufLen) {
				lineToShow[i++] = static_cast<char>(ch);
			}
		}
		lineToShow[i] = '\0';
		lineNum++;
		strcpy(lineToCompare, lineToShow);
		if (!caseSensitive) {
			for (int j = 0; j < i; j++) {
				if (lineToCompare[j] >= 'A' && lineToCompare[j] <= 'Z') {
					lineToCompare[j] = static_cast<char>(lineToCompare[j] - 'A' + 'a');
				}
			}
		}
		return lineToCompare;
	}
	int LineNumber() {
		return lineNum;
	}
	const char *Original() {
		return lineToShow;
	}
	bool BufferContainsNull() {
		return bf->BufferContainsNull();
	}
};

static bool IsWordCharacter(int ch) {
	return (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')  || (ch >= '0' && ch <= '9')  || (ch == '_');
}

void SciTEBase::GrepRecursive(GrepFlags gf, FilePath baseDir, const char *searchString, const char *fileTypes) {
	FilePathSet directories;
	FilePathSet files;
	baseDir.List(directories, files);
	size_t searchLength = strlen(searchString);
	SString os;
	for (size_t i = 0; i < files.Length(); i ++) {
		FilePath fPath = files.At(i);
		if (fPath.Matches(fileTypes)) {
			//OutputAppendStringSynchronised(i->AsFileSystem());
			//OutputAppendStringSynchronised("\n");
			FileReader fr(fPath, gf & grepMatchCase);
			if ((gf & grepBinary) || !fr.BufferContainsNull()) {
				while (char *line = fr.Next()) {
					char *match = strstr(line, searchString);
					if (match) {
						if (gf & grepWholeWord) {
							char *lineEnd = line + strlen(line);
							while (match) {
								if (((match == line) || !IsWordCharacter(match[-1])) &&
								        ((match + searchLength == (lineEnd)) || !IsWordCharacter(match[searchLength]))) {
									break;
								}
								match = strstr(match + 1, searchString);
							}
						}
						if (match) {
							os.append(fPath.AsFileSystem());
							os.append(":");
							SString lNumber(fr.LineNumber());
							os.append(lNumber.c_str());
							os.append(":");
							os.append(fr.Original());
							os.append("\n");
						}
					}
				}
			}
		}
	}
	if (os.length()) {
		if (gf & grepStdOut) {
			fwrite(os.c_str(), os.length(), 1, stdout);
		} else {
			OutputAppendStringSynchronised(os.c_str());
		}
	}
	for (size_t j = 0; j < directories.Length(); j++) {
		FilePath fPath = directories.At(j);
		if ((gf & grepDot) || (fPath.Name().AsInternal()[0] != '.')) {
			GrepRecursive(gf, fPath, searchString, fileTypes);
		}
	}
}

void SciTEBase::InternalGrep(GrepFlags gf, const char *directory, const char *fileTypes, const char *search) {
	int originalEnd = 0;
	ElapsedTime commandTime;
	if (!(gf & grepStdOut)) {
		SString os;
		os.append(">Internal search for \"");
		os.append(search);
		os.append("\" in \"");
		os.append(fileTypes);
		os.append("\"\n");
		OutputAppendStringSynchronised(os.c_str());
		MakeOutputVisible();
		originalEnd = SendOutputEx(SCI_GETCURRENTPOS, 0, 0, false);
	}
	SString searchString(search);
	if (!(gf & grepMatchCase)) {
		searchString.lowercase();
	}
	GrepRecursive(gf, FilePath(directory), searchString.c_str(), fileTypes);
	if (!(gf & grepStdOut)) {
		SString sExitMessage(">");
		if (timeCommands) {
			sExitMessage += "    Time: ";
			sExitMessage += SString(commandTime.Duration(), 3);
		}
		sExitMessage += "\n";
		OutputAppendStringSynchronised(sExitMessage.c_str());
		if (props.GetInt("output.scroll", 1) == 1 && returnOutputToCommand)
			SendOutputEx(SCI_GOTOPOS, originalEnd, 0, false);
	}
}

