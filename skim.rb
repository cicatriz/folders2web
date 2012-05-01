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
    if @out[-1] && @out[-1].index(text.strip)
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
  text.gsub!(/[•]/, "\n  * ")

  return "#{highlight}#{text}#{highlight} [[skimx://#{Citekey}##{page}|p. #{page}]]\n\n"
end

##########################################################################################

skimdoc = app('Skim').documents[0]
skimdoc.save(skimdoc)
Citekey = skimdoc.name.get[0..-5]
filename = skimdoc.file.get.to_s

# ensure that the PDF is named the same as the cite key (inspired by Cresencia)
bibdesk_publication = try { app("BibDesk").document.search({:for =>Citekey})[0] }

unless try { bibdesk_publication.cite_key.get.to_s == Citekey }
  fail "PDF filename doesn't match any citekeys in the BibDesk database. The name of a PDF file must be exactly " +
    "the same as the citekey in the database + the .PDF extension, for export to function properly. Aborting."
end

fname = "/tmp/#{Citekey}.txt"

skimdoc.save(skimdoc, {:as => "Notes as Text", :in => fname})
#skimdoc.save(skimdoc, {:as => "Skim Notes", :in => "/tmp/skimnotes-binary-pdf"})
# `/Applications/Skim.app/Contents/SharedSupport/skimnotes get -format text #{filename}`

# make sure the metadata page is written
ensure_refpage(Citekey)

# if no annotations, we're done
unless File.size(fname)  > 0
  growl "No clippings","Skim did not export any data. Either you have not made any highlights, or there is "+
    "an error (check the paths in settings.rb). Just creating the ref: page with metadata."
else
  # process clippings and images

  a = File.readlines(fname)

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
      text << line.gsub(/([a-zA-Z])\- ([a-zA-Z])/, '\1\2')  # just add the text (mend split words)
      alltext << line
    end
  end

  # calculate percentage of notes
  File.write("/tmp/skimnote-tmp", alltext)
  ntlines = `wc "/tmp/skimnote-tmp"`.split(" ")[1].to_f
  `rm "/tmp/skimnote-tmp"`
  `/usr/local/bin/pdftotext "#{filename}"`
  ftlines = `wc "#{PDF_path}/#{Citekey}.txt"`.split(" ")[1].to_f
  `rm "#{PDF_path}/#{Citekey}.txt"`

  @out << process(type, text, page)  # pick up the last annotation

  percentage_text = ftlines.to_i > 0 ? " (#{(ntlines/ftlines*100).to_i}%)" : ""

  outfinal = "h2. Highlights#{percentage_text}\n\n" + @out.join('')
  File.write("/tmp/skimtmp", outfinal)
  `/wiki/bin/dwpage.php -m 'Automatically extracted from Skim' commit /tmp/skimtmp 'clip:#{Citekey}'`

  if File.exists?("/tmp/skim-#{Citekey}-tmp")
    a = File.readlines("/tmp/skim-#{Citekey}-tmp")
    @out = "h2. Images\n\n"
    c = 0
    a.each do |line|
      f,pg = line.split(",")
      `mv "#{f.strip}" "/wiki/data/media/skim/#{Citekey}#{c.to_s}.png"`
      @out << "{{skim:#{Citekey}#{c.to_s}.png}}\n\n[[skimx://#{Citekey}##{pg.strip}|p. #{pg.strip}]]\n----\n\n"
      c += 1
    end
  #  `rm "/tmp/skim-#{Citekey}-tmp"`
    File.open("/tmp/skimtmp", "w") {|f| f << @out}
    `/wiki/bin/dwpage.php -m 'Automatically extracted from Skim' commit /tmp/skimtmp 'skimg:#{Citekey}'`
  end

  #make_newimports_page([Citekey])
end

# open ref page in browser
`open http://localhost/wiki/ref:#{Citekey}`

# update bibdesk fields
bibdesk_publication.fields["Read"].value.set("1")
bibdesk_publication.fields["Date-read"].value.set(Time.now.to_s)

# add to json cache and send to server if possible (if online)
add_to_jsonbib(Citekey)
try { scrobble(Citekey) }
