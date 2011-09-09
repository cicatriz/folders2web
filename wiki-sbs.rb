# encoding: UTF-8

# Add a text field 
$:.push(File.dirname($0))
require 'rubygems'
require 'utility-functions'
require 'appscript'
include Appscript

# asks for the name of a page, and presents it side-by-side with the existing page, in editing mode if it's a wiki page

dt=app('Google Chrome')

page = wikipage_selector("Choose page to view side-by-side with the current page")
exit unless page

cururl = dt.windows[1].get.tabs[dt.windows[1].get.active_tab_index.get].get.URL.get

p cururl

if cururl.index("localhost")
  cururl = cururl.split("/")[0..-2].join('/') + '/edit/' + cururl.split("/")[-1]
else
  
  # uses Instapaper to nicely format the article text, for fitting into a split-screen window
  cururl = "http://www.instapaper.com/text?u=\"+encodeURIComponent(\"#{cururl}\")+\""
end

newurl = "http://localhost:4567/#{page.gsub(" ","-")}"

js = "var MyFrame=\"<frameset cols=\'*,*\'><frame src=\'#{cururl}\'><frame src=\'#{newurl}?do=edit&vecdo=print\'></frameset>\";with(document) {    write(MyFrame);};return false;"
puts js
dt.windows[1].get.tabs[dt.windows[1].get.active_tab_index.get].get.execute(:javascript => js)
