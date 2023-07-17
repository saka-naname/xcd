#!/bin/bash

# Init
# Get height of screen
__XCD_ROWS=$(stty -a | grep -Po '(?<=rows )\d+')
__XCD_COLS=$(stty -a | grep -Po '(?<=columns )\d+')
__XCD_DIRS=()
__XCD_ORG_IFS=$IFS
__XCD_CURRENT=$(realpath $(pwd))
__XCD_CUR=1
__XCD_KEYIN=""

function __xcd_init() {
    for ((i = 0; i < $__XCD_ROWS - 1; i++)); do
        echo ""
    done
}

function __xcd_clear() {
    tput cup 0 0
    tput civis
    for ((i = 0; i < $__XCD_ROWS - 1; i++)); do
        echo "$(__xcd_fill $__XCD_COLS)"
    done
    tput cnorm
}

function __xcd_fill() {
    for ((i = 0; i < $1; i++)); do
        echo -n " "
    done
}

function __xcd_render() {
    tput civis
    tput cup 0 0
    tput bold
    if test $(tput colors) = 256; then
        tput setaf 2
    fi
    echo $__XCD_CURRENT

    for item in ${__XCD_DIRS[@]}; do
        if test $(tput colors) = 256; then
            if test -d $(realpath "$__XCD_CURRENT/$item"); then
                tput setaf 4
                tput bold
            else
                tput sgr0
                tput setaf 255
            fi
        fi
        echo "  $item"
    done
    tput sgr0

    __xcd_render_cur
    tput cnorm
}

function __xcd_loaddir() {
    IFS=$'\n'
    __XCD_DIRS=(..
    $(ls -1 --group-directories-first $__XCD_CURRENT))
    IFS=$__XCD_ORG_IFS
}

function __xcd_readkey() {
    read -rsn1 input
    if [ "$input" = $'\x1B' ]; then
        read -rsn1 -t 0.005 input
        if [ "$input" = "[" ]; then
            read -rsn1 -t 0.005 input
            case $input
            in
                A) echo "[Up]" ;;
                B) echo "[Down]" ;;
                C) echo "[Right]" ;;
                D) echo "[Left]";;
            esac
        else
            echo "[ESC]"
        fi
        read -rsn5 -t 0.005
        return 0
    elif [ "$input" = "" ]; then
        echo "[Enter]"
        read -rsn5 -t 0.005
        return 0
    fi
    echo $input
    return 1
}

function __xcd_movcur() {
    if test $# = 1; then
        __XCD_CUR=$(($__XCD_CUR + $1))
        if test $__XCD_CUR -lt 0; then
            __XCD_CUR=0
        elif test $__XCD_CUR -ge ${#__XCD_DIRS[*]}; then
            __XCD_CUR=$((${#__XCD_DIRS[*]} - 1))
        fi

        __xcd_render_cur
    fi
}

function __xcd_render_cur() {
    tput civis
    tput cup $__XCD_CUR 0
    tput bold
    if test $__XCD_CUR != 0; then
        echo " "
    else
        echo ""
    fi
    echo ">"
    if test $(($__XCD_ROWS - $__XCD_CUR)) != 1; then
        echo " "
    fi

    tput cup $(($__XCD_ROWS - 1)) 0
    tput sgr0
    tput cnorm
}

function __xcd_movdir() {
    if test $# = 1; then
        if test -d $(realpath "$__XCD_CURRENT/$1"); then
            __XCD_CURRENT=$(realpath "$__XCD_CURRENT/$1")
            __xcd_clear
            __xcd_loaddir
            __XCD_CUR=1
            __xcd_render
        fi
    fi
}

__xcd_init
__xcd_loaddir
__xcd_render

while true
do
    __XCD_KEYIN=$(__xcd_readkey)
    case "$__XCD_KEYIN"
    in
        q) break ;;
        "[Up]")    __xcd_movcur -1 ;;
        "[Down]")  __xcd_movcur 1  ;;
        "[Left]")  __xcd_movdir .. ;;
        "[Right]") __xcd_movdir "${__XCD_DIRS[$__XCD_CUR]}" ;;
        "[Enter]") cd $__XCD_CURRENT && break ;;
    esac

    if test $(stty -a | grep -Po '(?<=rows )\d+') != $__XCD_ROWS; then
        __XCD_ROWS=$(stty -a | grep -Po '(?<=rows )\d+')
        __xcd_clear
        __xcd_render
    fi
done

__xcd_clear
tput cup 0 0

unset -v __XCD_ROWS
unset -v __XCD_COLS
unset -v __XCD_DIRS
unset -v __XCD_ORG_IFS
unset -v __XCD_ORG_CURRENT
unset -v __XCD_CUR
unset -v __XCD_KEYIN
unset -f __xcd_init
unset -f __xcd_clear
unset -f __xcd_fill
unset -f __xcd_render
unset -f __xcd_loaddir
unset -f __xcd_readkey
unset -f __xcd_movcur
unset -f __xcd_movdir
