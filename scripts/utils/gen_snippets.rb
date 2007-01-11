#!/usr/bin/ruby

require 'readline'
require 'enumerator'

# Note: the following constants are found in scintilla.iface

RB = [
  :DEFAULT, :ERROR, :COMMENTLINE, :POD, :NUMBER, :WORD, :STRING,
  :CHARACTER, :CLASSNAME, :DEFNAME, :OPERATOR, :IDENTIFIER,
  :REGEX, :GLOBAL, :SYMBOL, :MODULE_NAME, :INSTANCE_VAR,
  :CLASS_VAR, :BACKTICKS, :DATASECTION, :HERE_DELIM, :HERE_Q,
  :HERE_QQ, :HERE_QX, :STRING_Q, :STRING_QQ, :STRING_QX,
  :STRING_QR, :STRING_QW, :WORD_DEMOTED, :STDIN, :STDOUT,
  :STDERR, :UPPER_BOUND
]

PY = [
  :DEFAULT, :COMMENTLINE, :NUMBER, :STRING, :CHARACTER, :WORD,
  :TRIPLE, :TRIPLEDOUBLE, :CLASSNAME, :DEFNAME, :OPERATOR,
  :IDENTIFIER, :COMMENTBLOCK, :STRINGEOL, :WORD2, :DECORATOR
]

CPP = [
  :DEFAULT, :COMMENT, :COMMENTLINE, :COMMENTDOC, :NUMBER, :WORD,
  :STRING, :CHARACTER, :UUID, :PREPROCESSOR, :OPERATOR,
  :IDENTIFIER, :STRINGEOL, :VERBATIM, :REGEX, :COMMENTLINEDOC,
  :WORD2, :COMMENTDOCKEYWORD, :COMMENTDOCKEYWORDERROR,
  :GLOBALCLASS
]

ML = [
  :DEFAULT, :TAG, :TAGUNKNOWN, :ATTRIBUTE, :ATTRIBUTEUNKNOWN,
  :NUMBER, :DOUBLESTRING, :SINGLESTRING, :OTHER, :COMMENT,
  :ENTITY, :TAGEND, :XMLSTART, :XMLEND, :SCRIPT, :ASP, :ASPAT,
  :CDATA, :QUESTION, :VALUE
]

PHP = [
  :DEFAULT, :HSTRING, :SIMPLESTRING, :WORD, :NUMBER, :VARIABLE,
  :COMMENT, :COMMENTLINE, :HSTRING_VARIABLE, :OPERATOR
]

PROP = [
  :DEFAULT, :COMMENT, :SECTION, :ASSIGNMENT, :DEFVAL, :KEY
]

LUA = [
  :DEFAULT, :COMMENT, :COMMENTLINE, :COMMENTDOC, :NUMBER, :WORD,
  :STRING, :CHARACTER, :LITERALSTRING, :PREPROCESSOR, :OPERATOR,
  :IDENTIFIER, :STRINGEOL, :WORD2, :WORD3, :WORD4, :WORD5,
  :WORD6, :WORD7, :WORD8
]

CSS = [
  :DEFAULT, :TAG, :CLASS, :PSEUDOCLASS, :UNKNOWN_PSEUDOCLASS,
  :OPERATOR, :IDENTIFIER, :UNKNOWN_IDENTIFIER, :VALUE, :COMMENT,
  :ID, :IMPORTANT, :DIRECTIVE, :DOUBLESTRING, :SINGLESTRING,
  :IDENTIFIER2, :ATTRIBUTE
]

YAML = [
  :DEFAULT, :COMMENT, :IDENTIFIER, :KEYWORD, :NUMBER, :REFERENCE,
  :DOCUMENT, :TEXT, :ERROR
]

SHELL = [
  :DEFAULT, :ERROR, :COMMENTLINE, :NUMBER, :WORD, :STRING,
  :CHARACTER, :OPERATOR, :IDENTIFIER, :SCALAR, :PARAM,
  :BACKTICKS, :HERE_DELIM, :HERE_Q
]

PERL = [
  :DEFAULT, :ERROR, :COMMENTLINE, :POD, :NUMBER, :WORD,
  :STRING, :CHARACTER, :PUNCTUATION, :PREPROCESSOR,
  :OPERATOR, :IDENTIFIER, :SCALAR, :ARRAY, :HASH, :SYMBOLTABLE,
  :VARIABLE_INDEXER, :REGEX, :REGSUBST, :LONGQUOTE, :BACKTICKS,
  :DATASECTION, :HERE_DELIM, :HERE_Q, :HERE_QQ, :HERE_QX,
  :STRING_Q, :STRING_QQ, :STRING_QX, :STRING_QR, :STRING_QW,
  :POD_VERB
]

LEXERS = {
  :RUBY   => { :prefix => 'SCE_RB_',    :scopes => RB    },
  :PYTHON => { :prefix => 'SCE_P_',     :scopes => PY    },
  :CPP    => { :prefix => 'SCE_C_',     :scopes => CPP   },
  :JAVA   => { :prefix => 'SCE_C_',     :scopes => CPP   },
  :HTML   => { :prefix => 'SCE_H_',     :scopes => ML    },
  :XML    => { :prefix => 'SCE_H_',     :scopes => ML    },
  :PHP    => { :prefix => 'SCE_HPHP_',  :scopes => PHP   },
  :PROPS  => { :prefix => 'SCE_PROPS_', :scopes => PROP  },
  :LUA    => { :prefix => 'SCE_LUA_',   :scopes => LUA   },
  :CSS    => { :prefix => 'SCE_CSS_',   :scopes => CSS   },
  :YAML   => { :prefix => 'SCE_YAML_',  :scopes => YAML  },
  :SHELL  => { :prefix => 'SCE_SH_',    :scopes => SHELL }
  #:PERL   => { :prefix => 'SCE_PL_',    :scopes => PERL  }
}

puts "-- Don't forget to declare the snippets table!"
puts "local snippets = {}"

def readline(prompt) return Readline::readline(prompt, true) end

while trigger = readline('Snippet Trigger: ')

  # display all languages for user to select
  puts "Languages available"
  langs = LEXERS.keys.map { |item| item.to_s }
  langs = langs.sort.map { |item| item.center(10) }
  langs.each_slice(6) { |items| puts items.join }

  lang, scope, snippet = [String.new] * 3
  lang = readline('Language: ').strip.upcase.to_sym \
    until LEXERS[lang]

  # display all scopes for user to select
  puts "Scopes available"
  scopes = LEXERS[lang][:scopes].map { |item| item.to_s }
  scopes << 'NONE'
  scopes = scopes.sort.map { |item| item.center(18) }
  scopes.each_slice(4) { |items| puts items.join }

  scope = readline('Scope: ').strip.upcase.to_sym \
    until LEXERS[lang][:scopes].include?(scope) or
    scope == :NONE

  if PLATFORM =~ /linux/
    puts "Snippet Expansion (^D to finish):"
    until (line_in = gets).nil? do snippet << line_in end
  else
    puts "Snippet Expansion (Empty line to finish, " +
      "'\\' escapes empty lines):"
    until (line_in = gets) == "\n" do snippet << line_in end
    snippet.gsub!("\\\n", "\n") # unescape empty lines
  end
  snippet.chomp!
  if snippet.split("\n").size == 1
    snippet.gsub!('\\', '\\\\\\\\')
    snippet.gsub!('"', '\"')
  end

  scope = scope.to_s
  scope_const = scope == 'NONE' ? \
    "'#{scope.downcase}'" : LEXERS[lang][:prefix] + scope
  puts "-----"
  puts "snippets[#{scope_const}] = {} -- if not defined already"
  puts "snippets[#{scope_const}]['#{trigger}'] = " +
    ( snippet.split("\n").size == 1 ? \
      "\"#{snippet}\"" : "\n[[#{snippet}]]" )
  puts "-----"

end
