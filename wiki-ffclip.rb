# encoding: UTF-8
$:.push(File.dirname($0))
require 'rubygems'
require 'utility-functions'
require 'pp'
require 'appscript'
include Appscript

#dt=app('Firefox')
#title = dt.windows[1].get.tabs[dt.windows[1].get.active_tab_index.get].get.title.get

# asks for a page name, and appends selected text on current page to that wiki page, with proper citation
pagetmp = wikipage_selector("Which wikipage do you want to add text to?",true, "
xb.type = checkbox
xb.label = only insert link to this page
xb.tooltip = Otherwise, it will take the currently selected text and insert
fb.type = textbox
fb.default = Title
fb.label = Link title\n"
)


exit if pagetmp["cancel"] == 1
onlylink = true if pagetmp['xb'] == "1"
pagename = pagetmp['cb'].strip
pagepath = Wikipages_path + "/" + clean_pagename(pagename) + "." + Wiki_ext
pagepath.gsub!(":","/")

# format properly if citation

insert = (onlylink ? "  *" : utf8safe(pbpaste) )

if File.exists?(pagepath)
  f = File.read(pagepath) 
  growltext = "Selected text added to #{pagename}"
  if f.index("id=clippings")
    hr = "\n"
  else
    hr = "\n\n----\n\n"
  end
else
  f = "h1. "+ capitalize_word(pagename) + "\n\n"
  hr = ""
  growltext = "Selected text added to newly created #{pagename}"
end
filetext = f + hr + insert.gsub("\n","\n\n").gsub("\n\n\n","\n\n") 

gwpage(pagename, filetext)
growl("Text added", growltext)
