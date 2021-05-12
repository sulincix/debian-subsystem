#!/bin/bash
get_area(){
    status=0
    while read line ; do
        if [[ $line == "["$1"]" ]] ; then
            status=1
        elif [[ ! -n $line || ${line:0:1} == "[" ]]  ; then
            status=0
        fi
        [[ $status -eq 1 && ${line:0:1} != "#" ]] && echo $line
    done
}
get_value(){
    cat | grep "^$1=" | sed "s/^$1=//g" | tail -n 1
}
usage(){
    echo "iniparser [file.ini] [section] [variable]"
    exit 1
}
[[ $# -lt 3 ]] && usage
cat "$1" | get_area "$2" | get_value "$3"
