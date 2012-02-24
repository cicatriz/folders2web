# encoding: UTF-8
$:.push(File.dirname($0))
#require 'rubygems'
require 'utility-functions'
require 'bibtex'
require 'citeproc'
require 'appscript'
include Appscript


# clean braces
def cb(text)
  # clean braces
  text.gsub(/[\{|\}]/,'')
end

# ensure that main refpage exists for a given citekey, taking info from BibDesk (needs to be running,
# maybe replace with taking info from Bibtex file eventually)
def ensure_refpage(citekey,override=false)
  if  true#!File.exists?("/wiki/data/pages/ref/#{citekey}.txt") || override
    dt = app('Bibdesk')
    find = dt.document.search({:for => citekey})
    if find == []
      growl("File not found", "Cannot find citation #{citekey} in BibDesk, the citekey in BibDesk needs to be the same as the name of the PDF.")
      exit
    end
    bib = BibTeX.parse(find[0].BibTeX_string.get.to_s)
    bib.parse_names
    item = bib[citekey.to_sym]
    p item
    citation = CiteProc.process(item.to_citeproc, :style => :apa)
    p item.class
    javascript = "javascript:var MyFrame='<frameset cols=\\'*,*\\'><frame src=\\'/wiki/notes:#{citekey}?do=edit&vecdo=print\\'><frame src=\\'/wiki/clip:#{citekey}?vecdo=print\\'></frameset>';with(document) {    write(MyFrame);};return false;\""
    citation = "^ Citation |#{cb(citation)}  ^ <html><a href=\"#{javascript}\">Sidewiki</a></html>^\n^[[bibdeskx://#{citekey}|BibDesk]] | ::: ^  [[skimx://#{citekey}|PDF]] ^ "
    text = "h1. #{cb(item[:title])}\n\n#{citation}\n\n<hidden BibTex>\n  #{item.to_s}\n</hidden>\n\n{{page>notes:#{citekey}}}\n\nh2. Links here\n{{backlinks>.}}\n\n{{page>clip:#{citekey}}}\n\n{{page>kindle:#{citekey}}}\n\n{{page>skimg:#{citekey}}}"
    dwpage("ref:#{citekey}", text, 'Automatically generated from Bibdesk')

    submit_citation(citekey, item.to_s)
  end
end

# ensure that main refpage exists for a given citekey, taking info from BibDesk (needs to be running,
# maybe replace with taking info from Bibtex file eventually)
# jdef ensure_refpage(citekey,override=false)
# j
# j  if  !File.exists?("#{Wikipages_path}/#{citekey}.#{Wiki_ext}") || override
# j    dt = app('Bibdesk')
# j    find = dt.document.search({:for => citekey})
# j    if find == []
# j      growl("File not found", "Cannot find citation #{ARGV[0]} in BibDesk")
# j      exit
# j    end
# j    bib = BibTeX.parse(find[0].BibTeX_string.get.to_s)
# j    bib.parse_names
# j    item = bib[citekey.to_sym]
# j    citation = CiteProc.process(item.to_citeproc, :style => :apa)
# j    javascript = "javascript:var MyFrame='<frameset cols=\\'*,*\\'><frame src=\\'/edit/#{citekey}\\'><frame src=\\'/#{citekey}\\'></frameset>';with(document) {    write(MyFrame);};return false;"
# j    javascript = "#"
# j
# j    text = "<table>
# j    <tr>
# j      <td>Citation</td>
# j      <td rowspan=\"2\">#{cb(citation)}</td>
# j      <td><a href=\"#{javascript}\">Sidewiki</a></td>
# j    </tr>
# j    <tr>
# j      <td><a href=\"bibdesk://#{citekey}\">BibDesk</a></td>
# j      <td><a href=\"skimx://#{citekey}\">PDF</a></td>
# j    </tr>
# j    </table>\n\n"
# j    
# j    #text = "# #{cb(item[:title])}\n\n#{citation}\n\n<hidden BibTex>\n  #{item.to_s}\n</hidden>\n\n{{page>notes:#{citekey}}}\n\nh2. Links here\n{{backlinks>.}}\n\n{{page>clip:#{citekey}}}\n\n{{page>kindle:#{citekey}}}\n\n{{page>skimg:#{citekey}}}"
# j
# j    gwpage("#{citekey}", text, 'Automatically generated from Bibdesk')
# j  end
# jend

def make_newimports_page(ary)
  # b = BibTeX.open("/Volumes/Home/stian/Dropbox/Archive/Bibliography.bib")
  # b.parse_names
  # 
  # out = "h1. Recently imported items\n\n^Note name ^ Note text ^\n"
  # ary.each do |citekey|
  #   item = b[citekey.to_sym]
  #   cit = CiteProc.process item.to_citeproc, :style => :apa
  #   out << "| [[:ref:#{item.key}]] | #{cit}|\n"
  # end
  # 
  # File.open('/wiki/data/pages/bib/recent_imports.txt', 'w') {|f| f << out}  
end
