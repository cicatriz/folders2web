$:.push(File.dirname($0))
require 'utility-functions'
require 'bibtex'
require 'citeproc'
require 'erb'

=begin 
b = BibTeX.parse(File.read(Bibliography))
b.parse_names

all_kw = Hash.new
item_viewed = Hash.new

b.each do |item|
  if item.respond_to? :key
    item_viewed[item] = false
  end

  if item.respond_to? :keywords
    item.keywords.split(";").each do |a|
      a.strip!
      all_kw[a] = Array.new unless all_kw[a]
      all_kw[a] << item
      item_viewed[item] = true
    end
  end
end
=end

def last_edit(key)

# file format: title.time.txt.gz

  file_times = []

  if f=File.last_added("#{Wiki_path}/data/attic/ref/#{key}.*.txt.gz")
    file_times << f.split('/')[-1].split('.')[1]
  end
  if f=File.last_added("#{Wiki_path}/data/attic/clips/#{key}.*.txt.gz")
    file_times << f.split('/')[-1].split('.')[1]
  end
  if f=File.last_added("#{Wiki_path}/data/attic/notes/#{key}.*.txt.gz")
    file_times << f.split('/')[-1].split('.')[1]
  end
  if f=File.last_added("#{Wiki_path}/data/attic/skimg/#{key}.*.txt.gz")
    file_times << f.split('/')[-1].split('.')[1]
  end

  last_time = Time.at(file_times.max.to_i)
end

def page_edits()
  n = 20
  files = Dir["#{Wiki_path}/data/attic/*.txt.gz"]
  #files = files.sort_by {|f| f.split('/')[-1].split('.')[1]}.reverse[0..n]

  # find all changes in the past week
  week_ago = Time.now.to_i - 60*60*24*7

  versions = Hash.new
  files.each do |f|
    pagename = f.split('/')[-1].split('.')[0]
    if versions[pagename].nil?
      versions[pagename] = []
    end

    versions[pagename] << f
  end

  changes = Hash.new

  # get change counts for each file version
  versions.each_key do |pagename|
    changes[pagename] = Hash.new
    edittime = 0
    versions[pagename].each_with_index do |f, i|
      lastedittime = edittime
      edittime = f.split('/')[-1].split('.')[1]
      unzipped = "#{Wiki_path}/temp/#{pagename}.#{edittime}.txt"
      unless File.exists?(unzipped)
        `gzcat #{f} > #{unzipped}`
      end

      next if edittime.to_i < week_ago
      if i==0
        changes[pagename][edittime] = `wc -l #{unzipped}`.strip.to_i
      else
        last_unzipped = "#{Wiki_path}/temp/#{pagename}.#{lastedittime}.txt"
        changes[pagename][edittime] = `diff -U 0 #{unzipped} #{last_unzipped} | grep -v ^@ | wc -l`.strip.to_i - 2
      end
    end
  end

  # clear keywords with no new changes
  changes.delete_if { |k,v| v=={} }
  changes.delete_if { |k,v| v.values.max <= 0 }
  changes.sort_by { |k,v| v.keys.last }
  changes_by_day = Hash.new

  changes.sort_by { |k,v| v.keys.last }.reverse.each do |page|
    pagename = page[0]
    changes_by_day[pagename] = [0]*7
    changes[pagename].each do |time, changes|
      day = (time.to_i - week_ago)/(60*60*24)
      changes_by_day[pagename][day] += changes
    end
  end


=begin
  # diff each pair
  # group by day

  pages = []

  files.each do |f|
    path = "#{f.split('.')[0..-4].join('.')}.*.txt.gz"
    versions = Dir[path].select {|f| test ?f, f}.sort_by{|f| File.mtime f}
    `gzcat #{f} > temp/#{f}`
    rawf = f.split('.')[0..-2].join('.')
    changes = `wc -l #{rawf}`.strip.to_i
    if versions.length >= 2
      new = versions.pop
      old = versions.pop
      `gzcat #{old} > temp/`
      rawold = old.split('.')[0..-2].join('.')
      # need to gunzip!
      changes = `diff -U 0 #{rawf} #{rawold} | grep ^@ | wc -l`.strip.to_i
      p rawold
      #`rm #{rawold}`
    end
    p rawf
    #`rm #{rawf}`

    pages << { file: f, changes: changes }
  end
  
  return pages
=end
  return changes_by_day
end

def keyword_edits(all_kw, item_viewed)
  days_for_recent = 31*24*60*60

  keywords = {}

  all_kw.each do |keyword, pubs|
    articles = []
    recent_articles = []
    last_edit_by_kw = 0

    pubs.each do |item|
      if File.exists?("#{Wiki_path}/data/pages/ref/#{item.key}.txt")
        articles << item
        last_edit = last_edit(item.key)
        if last_edit + days_for_recent > Time.now
          recent_articles << item
        end
        last_edit_by_kw = [last_edit.to_i, last_edit_by_kw].max
      end
    end

    keywords[keyword] = { articles: articles, recent_articles: recent_articles, last_edit: last_edit_by_kw }
  end

  unclassified = []
  recent_unclassified = []

  item_viewed.each do |item, viewed|
    if not viewed and File.exists?("#{Wiki_path}/data/pages/ref/#{item.key}.txt")
      unclassified << item
      if last_edit(item.key) + days_for_recent > Time.now
        recent_unclassified << item
      end
    end
  end
  #keywords['unclassified'] = { articles: unclassified, recent_articles: recent_unclassified, last_edit: 0 }

  return keywords
end

#keywords = keyword_edits(all_kw, item_viewed)
changes = page_edits()

template = nil

File.open('/Users/ramuller/src/folders2web/viz-out.html.erb') do |f|
  template = ERB.new( f.read )
end

dwpage('stats:page_activity', template.result(binding))

