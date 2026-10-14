#!/bin/bash


function print_red()
{
    #"$@" => "$1" "$2" "$3"
    echo -e "\033[31m$@\033[0m"
}


function check()
{
    local command_return_value

    #echo "$@"
    eval "$@; typeset -a command_return_value=(\${PIPESTATUS[@]})"
    for i in "${command_return_value[@]}"
    do
        if [ $i -ne 0 ]; then
            print_red "error:$@"
            exit 1
        fi
    done
}

