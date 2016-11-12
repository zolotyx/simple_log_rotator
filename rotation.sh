#!/bin/bash

usage() { echo "Usage: $0 -c <config> [-p <pause>]" 1>&2; exit 1; }

generate_file_name () {
  local old_name=$1
  local n=$2

  local suffix=""
  if (( n > 0 )); then
    suffix=".$n"
  fi
  if (( n > 1 )); then
    suffix="$suffix.gz"
  fi

  echo "$old_name$suffix"
}

rotation() {

  local file=$1
  local N=$2
  local iteration=$3

  move_log() {
    
    local f=$1
    local M=$2

    local current_file_name=`generate_file_name $f $((M-1))`
    local new_file_name=`generate_file_name $f $M`


    if [ -f $current_file_name ]; then
      if ((M == 2)); then
        echo "ARCHIVED: $current_file_name -> $new_file_name"
        gzip $current_file_name 
        mv "$current_file_name.gz" $new_file_name

      else  
        echo "MOVED: $current_file_name -> $new_file_name"
        mv $current_file_name $new_file_name
      fi
      
    fi

    if ((M == 1)); then
      touch $f
      exit 1;
    fi
    move_log $f $((M-1))
  }

  if [ -z "${iteration}" ]; then
    iteration=0
  fi

  move_log $file $N
}

while getopts ":c:p:" opt; do
  case $opt in
    c)
      config=${OPTARG}
      ;;
    p)
      pause=${OPTARG}
      ;;
  esac
done


if [ -z "${config}" ]; then
    usage
    exit1;
fi

if [ ! -f "${config}" ]; then
    echo "Config file not found!"
    exit 1;
fi

if [ -z "${pause}" ]; then
    pause=10
fi

echo "Press [CTRL+C] to stop.."
while true
do
  while read -r line
  do
    if [ ! -z "$line" ]; then
      IFS=' ' read -ra params <<< "$line"
      mask=${params[0]}
      size=${params[1]}
      N=${params[2]}
      path=${params[3]}

      if ((N > 0)); then
        # echo "find $path -type f -regex $mask -size +${size}"
        find $path -type f -name $mask -size "+${size}" | while read filename
        do
          # echo $filename
          rotation $filename $N  
        done 
      fi  
    fi   
  done < "$config"

  sleep $pause
done



