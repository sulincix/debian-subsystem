#!/bin/bash
set -e
xgettext -o po/lsl.pot  -L Shell --keyword --keyword="_" $(find -type f -iname *.sh)
for file in `ls po/*.po`; do
    msgmerge $file po/lsl.pot -o $file.new
    echo POT: $file
    rm -f $file
    mv $file.new $file
done
