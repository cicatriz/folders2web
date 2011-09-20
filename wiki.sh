#!/bin/bash
rm -rf /wiki/data/cache/*
rsync --exclude .htaccess --delete -avzPe ssh /Library/WebServer/Documents/wiki gosuapm@gosuapm.com:~/webapps/wiki/
ssh gosuapm@gosuapm.com 'chmod -R 755 ~/webapps/wiki/*; chmod 755 ~/webapps/wiki;touch ~/webapps/wiki/conf/dokuwiki.php'
#gunzip /wiki/sitemap.xml.gz
#ruby -pe 'gsub("localhost","learnstream.org")' < /wiki/sitemap.xml > /wiki/sitemap-tmp.xml
#mv /wiki/sitemap-tmp.xml /wiki/sitemap.xml
#gzip /wiki/sitemap.xml
#rsync --delete -avzPe ssh /wiki/sitemap.xml.gz houshuan@reganmian.net:~/public_html/
