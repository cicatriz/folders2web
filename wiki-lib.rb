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

  if  !File.exists?("#{Wikipages_path}/#{citekey}.#{Wiki_ext}") || override
    dt = app('Bibdesk')
    find = dt.document.search({:for => citekey})
    if find == []
      growl("File not found", "Cannot find citation #{ARGV[0]} in BibDesk")
      exit
    end
    bib = BibTeX.parse(find[0].BibTeX_string.get.to_s)
    bib.parse_names
    item = bib[citekey.to_sym]
    citation = CiteProc.process(item.to_citeproc, :style => :apa)
    javascript = "javascript:var MyFrame='<frameset cols=\\'*,*\\'><frame src=\\'/edit/#{citekey}\\'><frame src=\\'/#{citekey}\\'></frameset>';with(document) {    write(MyFrame);};return false;"
    javascript = "#"

    text = "<table>
    <tr>
      <td>Citation</td>
      <td rowspan=\"2\">#{cb(citation)}</td>
      <td><a href=\"#{javascript}\">Sidewiki</a></td>
    </tr>
    <tr>
      <td><a href=\"bibdesk://#{citekey}\">BibDesk</a></td>
      <td><a href=\"skimx://#{citekey}\">PDF</a></td>
    </tr>
    </table>\n\n"
    
    #text = "# #{cb(item[:title])}\n\n#{citation}\n\n<hidden BibTex>\n  #{item.to_s}\n</hidden>\n\n{{page>notes:#{citekey}}}\n\nh2. Links here\n{{backlinks>.}}\n\n{{page>clip:#{citekey}}}\n\n{{page>kindle:#{citekey}}}\n\n{{page>skimg:#{citekey}}}"

    gwpage("#{citekey}", text, 'Automatically generated from Bibdesk')
  end
end

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
