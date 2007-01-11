#!/usr/bin/ruby
=begin
  Generate Ruby API from RDOC html files [for SciTE]
    by Mitchell

  Params:
    gen_ruby_api [output_file [classes]]

  each [class] is of the form 'Class' or 'Class:library' where
  library is the library to 'require' when using Class
  (e.g. Enumerable:enumerator)
  Wildcards can be used (e.g. CGI::*:cgi)

  How it works:
    Opens each 'class'.html file in current RDOC directory and
    parses out each method along with args. It then 'requires'
    the library in libraries (if necessary) to generate a list of
    class methods and instance methods. Each method extracted from
    the RDOCs is checked against each method list for a match to
    determine the method's type. A struct is created and added to
    the master_index. After all RDOCs have been parsed, iterate
    over master_index writing each method to output_file according
    to api_fmt string.

  api_fmt string formatting options:
    %c class, %n function name, %a function args %t method type
=end

# -------------------- #
klasses = %w(Array Dir Enumerable File Hash IO Object Pathname Regexp String)
libraries = %w( )
api_fmt = "%c.%n%aMethod Type: %t\n"
# -------------------- #

output_file = ARGV[0] or 'ruby.api' # :string

# create klasses array and libraries table from cmdline params
if ARGV.size > 1
  klasses.clear
  libraries.clear
  ARGV[1..-1].each do |arg|
    if arg =~ /^([\w:*]+):(\w+)$/
      klasses << $1
      libraries << $2
    else
      klasses << arg
    end
  end
end

class String
  # clean up function parameters (e.g. (a,b ) => (a, b))
  def clean_params!
    self.gsub!(/\(\s*(.+?)\s*\)/) do |match|
      p = $1.split(',').each { |var| var.strip! }.join(', ')
      "(#{p})"
    end
  end

  # clean up block parameters (e.g. |a,b| => |a, b|)
  def clean_block!
    self.gsub!(/\{\s*\|\s*(.*?)\s*\|\s*(\S+)\s*\}/) do |match|
      t = $2
      b = $1.split(',').each { |var| var.strip! }.join(', ')
      "{ |#{b}| #{t} }\\n"
    end
  end

  # removes class from method definition (e.g. str.scan => scan)
  def remove_class!() self.gsub!(/^[^\(]+\./, '') end
end

def type_and_prefix(name, class_name)
  if class_name.index('::')
    klass = Object
    class_name.split('::').each { |part| klass = klass.const_get(part) }
  else
    klass = Object.const_get(class_name)
  end
  c_methods = klass.public_methods
  i_methods = klass.public_instance_methods
  if i_methods.include? name
    type = 'instance'
    prfx = class_name.downcase
  elsif c_methods.include? name
    type = 'class'
    prfx = class_name
  else
    type = 'unknown'
    prfx = class_name.downcase
  end
  return type, prfx
end

meth_sign_regex = /<a.+?class="method-signature".+?>(.+?)<\/a>/im
meth_name_regex = /<span class="method-name">(.+?)<\/span>/im
meth_args_regex = /<span class="method-args">(.+?)<\/span>/im
RubyMethod      = Struct.new(:name, :args, :class, :method_type)
master_index    = Array.new

# load required libraries
libraries.each { |lib| require lib }

# check for wildcard classes and expand
klasses.each do |class_name|
  next unless class_name.index('::*')
  klass = Object
  class_name.split('::').each do |part|
    break if part == '*'
    klass = klass.const_get(part)
  end
  klasses << klass.to_s
  klass.constants.each do |const|
    if klass.const_get(const).is_a?(Class) or
      klass.const_get(const).is_a?(Module)
      klasses << klass.to_s + '::' + const.to_s
    end
  end
  klasses.delete(class_name)
end

require 'cgi'

# generate API for each class
klasses.each do |klass|
  rdoc_file = klass.gsub('::', '/') + '.html'
  unless FileTest.exist? rdoc_file
    puts rdoc_file + ' does not exist'
    next
  end

  data = IO.read(rdoc_file)

  methods = data.scan(meth_sign_regex).flatten
  methods.each do |meth|
    meth.gsub!('&amp;', '&') # escape XHTML for block parameter
    if meth.index('method-args')
      # newer RDOC (method-name, method-args)
      name = meth.scan(meth_name_regex).to_s
      name.remove_class!
      if name =~ /[^\w_?! ]/ # no operator methods
        puts "dropped #{klass}.#{name}"
        next
      end
      args = meth.scan(meth_args_regex).to_s
      args.clean_params!
      args.clean_block!
      args = CGI.unescapeHTML(args)
      name.squeeze!(' '); name.strip!
      args.squeeze!(' '); args.strip!
      # determine method type and add to master list
      type, prfx = type_and_prefix(name, klass)
      master_index << RubyMethod.new(name, args, prfx, type)
    else
      # older RDOC (method-name w/ args too)
      meth_list = meth.scan(meth_name_regex).to_s
      meth_list.split("\n").each do |meth|
        meth.gsub!(/&.+;.+<br\s\/>\s*$/, '') # remove '-> [Class]'
        meth.gsub!(/=>.+$/, '')  # remove '=> [Class]'
        meth.gsub!('<br />', '') # remove html breaks for overloaded funcs
        meth.clean_params!
        meth.clean_block!
        meth.remove_class!
        meth.squeeze!(' '); meth.strip!
        unless meth.index('(') # deal with empty param list
          meth.index('{') ? meth.gsub!(/^([^\{]+)\s\{/, '\1() {') : \
                            meth.concat('()')
        end
        name = meth.scan(/^[^\(]+/).to_s
        if name =~ /[^\w_?! ]/ # no operator methods
          puts "dropped #{klass}.#{name}"
          next
        end
        args = meth.scan(/\(.+$/).to_s
        args.gsub!(') {', '){') # for SciTE api formatting
        args = CGI.unescapeHTML(args)
        # determine method type and add to master list
        type, prfx = type_and_prefix(name, klass)
        master_index << RubyMethod.new(name, args, prfx, type)
      end
    end
  end
end

exit if master_index.empty?

f = File.new(output_file, 'w')
master_index.uniq!
master_index.sort! { |a, b| (a.class + a.name) <=> (b.class + b.name) }
master_index.each do |meth|
  line = api_fmt.gsub('%c', meth.class).
                 gsub('%n', meth.name).
                 gsub('%a', meth.args).
                 gsub('%t', meth.method_type)
  f.write line
end
f.close
