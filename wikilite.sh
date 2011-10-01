#!/bin/bash
rm -rf /wiki/data/cache/*
rsync --delete -avzPe ssh /Library/WebServer/Documents/wiki/data gosuapm@gosuapm.com:~/webapps/wiki/
rsync --delete -avzPe ssh /Library/WebServer/Documents/wiki/lib/plugins/dokuresearchr/json.tmp gosuapm@gosuapm.com:~/webapps/wiki/lib/plugins/dokuresearchr/
ssh gosuapm@gosuapm.com 'chmod -R 755 ~/webapps/wiki/data/*; chmod 755 ~/webapps/wiki/data;touch ~/webapps/wiki/conf/local.php'
