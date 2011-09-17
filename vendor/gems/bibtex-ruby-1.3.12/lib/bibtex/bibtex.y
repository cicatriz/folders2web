#--
# BibTeX-Ruby
# Copyright (C) 2010-2011  Sylvester Keil <http://sylvester.keil.or.at>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++
#
# A BibTeX grammar for the parser generator +racc+
#

# -*- racc -*-

class BibTeX::Parser

token AT COMMA COMMENT CONTENT ERROR EQ LBRACE META_CONTENT
      NAME NUMBER PREAMBLE RBRACE SHARP STRING STRING_LITERAL

expect 0

rule

  bibliography : /* empty */                       { result = BibTeX::Bibliography.new(@options) }
               | objects                           { result = val[0] }

  objects : object                                 { result = BibTeX::Bibliography.new(@options) << val[0] }
          | objects object                         { result << val[1] }

  object : AT at_object                            { result = val[1] }
         | META_CONTENT                            { result = BibTeX::MetaContent.new(val[0]) }
         | ERROR                                   { result = BibTeX::Error.new(val[0]) }

  at_object : comment                              { result = val[0] }
            | string                               { result = val[0] }
            | preamble                             { result = val[0] }
            | entry                                { result = val[0] }

  comment : COMMENT LBRACE content RBRACE          { result = BibTeX::Comment.new(val[2]) }
  
  content : /* empty */                            { result = '' }
          | CONTENT                                { result = val[0] }
  
  preamble : PREAMBLE LBRACE string_value RBRACE   { result = BibTeX::Preamble.new(val[2]) }

  string : STRING LBRACE string_assignment RBRACE  { result = BibTeX::String.new(val[2][0],val[2][1]); }

  string_assignment : NAME EQ string_value         { result = [val[0].downcase.to_sym, val[2]] }

  string_value : string_literal                    { result = [val[0]] }
               | string_value SHARP string_literal { result << val[2] }

  string_literal : NAME                            { result = val[0].downcase.to_sym }
                 | LBRACE content RBRACE           { result = val[1] }
                 | STRING_LITERAL                  { result = val[0] }

  entry : entry_head assignments RBRACE            { result = val[0] << val[1] }
        | entry_head assignments COMMA RBRACE      { result = val[0] << val[1] }
        | entry_head RBRACE                        { result = val[0] }

  entry_head : NAME LBRACE key COMMA               { result = BibTeX::Entry.new(:type => val[0].downcase.to_sym, :key => val[2]) }

  key : NAME                                       { result = val[0] }
      | NUMBER                                     { result = val[0] }
      | NUMBER NAME                                { result = val[0,2].join }

  assignments : assignment                         { result = val[0] }
              | assignments COMMA assignment       { result.merge!(val[2]) }

  assignment : NAME EQ value                       { result = { val[0].downcase.to_sym => val[2] } }

  value : string_value                             { result = val[0] }
        | NUMBER                                   { result = val[0] }

end

---- header
require 'bibtex/lexer'

---- inner

  attr_reader :lexer, :options
  
	DEFAULTS = { :include => [:errors], :debug => ENV['DEBUG'] == true }.freeze
	
  def initialize(options = {})
		@options = DEFAULTS.merge(options)
    @lexer = Lexer.new(@options)
  end

  def parse(input)
    @yydebug = debug?   
    @lexer.analyse(input)
    
    do_parse
		#yyparse(@lexer,:each)
  end
  
  def next_token
    @lexer.next_token
  end
  
  def debug?
    @options[:debug] == true
  end
    
  def on_error(tid, val, vstack)
    Log.error("Failed to parse BibTeX on value %s (%s) %s" % [val.inspect, token_to_str(tid) || '?', vstack.inspect])
    #raise(ParseError, "Failed to parse BibTeX on value %s (%s) %s" % [val.inspect, token_to_str(tid) || '?', vstack.inspect])
  end

# -*- racc -*-