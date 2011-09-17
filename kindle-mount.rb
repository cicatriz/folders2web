#!/usr/bin/ruby
# encoding: UTF-8

$:.push(File.dirname($0))
require 'utility-functions'
require 'wiki-lib'
require 'appscript'
include Appscript

`/usr/local/bin/growlnotify -m "Starting import of Kindle highlights"`

app("BibDesk").document.save
a = File.open("/Volumes/Kindle/documents/My\ Clippings.txt")
#filename = ( ARGV[0] ? ARGV[0] : "$RESEACHR_HOME/My Clippings.txt")
#a = File.open(filename)
annotations = Hash.new

def format(text,label, loc)
  highlight = (label == 2 ? "::" : "")
  return "#{highlight}#{text.strip}#{highlight} **(loc: #{loc})**\n\n"
end


while !a.eof?   # until we've gone through the whole file, line by line
  title = a.readline.strip
  meta = a.readline.strip
  loc, added = meta.split(" | ")
  loc = loc.gsub("- Highlight", "").strip
  content = ''
  while 1
    c = a.readline
    break if c[0..9] == "=========="     # end of record
    content << c
  end

  content.strip!

  label = loc.index("- Note") ? 2 : 0  # colors it blue if it is a note, rather than highlight

  annotations[title] = {:clippings => Array.new} unless annotations[title]

  loc = loc.gsub("- Note", "").gsub("Loc. ", "")
  annotations[title][:clippings] << {:text => content, :label => label, :loc => loc}
end

c = 0
new_imports = Array.new
annotations.each do |title, article|
  next unless title =~ /\[\@?(.+?)\] \((.+?)\)$/
  citekey = $1
  puts $1
  app("BibDesk").document.search({:for =>citekey})[0].fields["Read"].value.set("1")
  new_imports << citekey
  c += 1
  out = ""

  article[:clippings].each do |clip|
    out << format(clip[:text], clip[:label],clip[:loc])
  end

  #gwpage(citekey, out, "Automatically extracted from Kindle")
  
  ensure_refpage(citekey)
  gwappend(citekey, out, "Automatically extracted from Kindle", "## Highlights")
end

make_newimports_page(new_imports)
`/usr/local/bin/growlnotify -t "Kindle import complete" -m "Imported #{c} publication(s)"`
