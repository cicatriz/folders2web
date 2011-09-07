# execute ruby script from ruby:// handler

arg = ARGV[0][7..-1]
`ruby -KU $RESEARCHR_HOME/#{arg}`
