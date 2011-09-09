# encoding: UTF-8
$:.push(File.dirname($0))
require 'wiki-lib'
require 'appscript'
require 'utility-functions'
include Appscript

# opens selected citations from BibDesk in a web browser, creating metadata pages if they don't already exist

dt = app('BibDesk')
d = dt.document.selection.get[0]
ary = Array.new
d.each do |dd|
  docu = dd.cite_key.get
  ary << docu unless File.exists?("#{Wikipages_path}/#{docu}.#{Wiki_ext}")
  #ensure_refpage(docu)
end
`open #{Wiki_url}#{d[0].cite_key.get}`
