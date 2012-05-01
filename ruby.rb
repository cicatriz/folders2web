# execute ruby script from ruby:// handler
arg = ARGV[0][7..-1]
arg.gsub!(".rb",'')
`ruby -KU $RESEARCHR_HOME/dokuwiki.rb #{arg}`
