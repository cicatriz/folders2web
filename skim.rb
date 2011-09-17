# encoding: UTF-8
$:.push(File.dirname($0))
require 'utility-functions'
require 'wiki-lib'
require 'appscript'
include Appscript



# grabs the name of the currently open Skim file, uses skimnotes to extract notes and highlights to a text file,
# and inserts this as a page, using the filename as a page name, in DokuWiki. intended to be turned into a service.

def process(type, text, page)
   if type == "Underline"
    if @out[-1].index(text.strip)
      @out << @out.pop.gsub(text.strip,"::::#{text.strip}::::")
    else
      type = "Underline-standalone"
    end
  end
  return type == "Underline" ? nil : format(type, text, page) 
end

def format(type, text, page)
  highlight = case type
    when "Text Note"
      "::"
    when "Underline-standalone"
      ":::"
    else
      ""
  end
  text.strip!
  if text.scan(/[•]/).size > 1
    text.gsub!(/[•]/, "\n  * ")
  end
    
  return "#{highlight}#{text}#{highlight} [[skimx://#{Citekey}##{page}|p. #{page}]]\n\n"
end

app('BibDesk').document.save
dt = app('Skim')
dt.save(dt.document)
docu = dt.document.name.get[0][0..-5]

`/Applications/Skim.app/Contents/SharedSupport/skimnotes get -format text #{dt.document.file.get[0].to_s}`
Citekey = docu
filename = dt.document.file.get[0].to_s
`/Applications/Skim.app/Contents/SharedSupport/skimnotes get -format text #{filename}`
a = File.readlines("#{PDF_path}/#{docu}.txt") 

page = nil
@out = Array.new

type = ''
text=''
alltext = ''

a.each do |line|
  if line =~ /^\* (Highlight|Text Note|Underline), page (.+?)$/
    if page != nil  # ie. don't execute the first time, only when there is a previous annotation in the system
      p = process(type, text, page)
      @out << p if p
    end
    page = $2.to_i
    type = $1
    text = ''
  else
    text << line  # just add the text 
    alltext << line
  end
end

# calculate percentage of notes
File.write("/tmp/skimnote-tmp", alltext)
ntlines = `wc "/tmp/skimnote-tmp"`.split(" ")[1].to_f
`rm "/tmp/skimnote-tmp"`
`/usr/local/bin/pdftotext "#{filename}"`
ftlines = `wc "#{PDF_path}/#{docu}.txt"`.split(" ")[1].to_f
`rm "#{PDF_path}/#{docu}.txt"`
percentage = ntlines/ftlines*100

#gwappend("#{docu}", @out.join(''), msg="Automatically extracted from Skim", "## Highlights", true)
#
# start new stuff
@out << process(type, text, page)  # pick up the last annotation
outfinal = "h2. Highlights (#{percentage.to_i}%)\n\n" + @out.join('')
File.write("/tmp/skimtmp", outfinal)
`/wiki/bin/dwpage.php -m 'Automatically extracted from Skim' commit /tmp/skimtmp 'clip:#{docu}'`

# end new stuff

if File.exists?("/tmp/skim-screenshots-tmp")
  @out = Array.new

  a = File.readlines("/tmp/skim-screenshots-tmp")

  c = 0
  a.each do |line|
    f,pg = line.split(",")
    `mv "#{f.strip}" "#{Wikimedia_path}/skim/#{Citekey}#{c.to_s}.png"`
    @out << "[[pics/skim/#{Citekey}#{c.to_s}.png]]\n\n[p. #{pg.strip}](skimx://#{Citekey}##{pg.strip})\n\n----\n\n"
    c += 1
  end
  `rm "/tmp/skim-screenshots-tmp"`
  `git --git-dir="#{Wikipages_path}/.git" --work-tree="#{Wikipages_path}" add pics/skim/*.png` 
  #gwpage("#{docu}", @out.join(""), msg="Automatically extracted from Skim")
  gwappend("#{docu}", @out.join(""), msg="Automatically extracted from Skim", "## Images")
end

#make_newimports_page([docu])
`open #{Wiki_url}#{docu}`
