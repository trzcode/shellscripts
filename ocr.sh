#!/bin/bash

if [ $# -eq 0 -o $# -lt 1 -a $# -gt 2 ]; then
  echo "usage: $0 <filename|directory> <filename_match>"
  echo "example usage: $0 /scans scan"
  exit 1
fi

# /usr/bin
pdfsandwich=$(which pdfsandwich)
awk=$(which awk)

# check if all needed tools are installed (only the ones not installed under /bin/)
alltoolsinstalled="yes"
test "$pdfsandwich" = "" && echo "'pdfsandwich' not installed or not found by 'which'" && alltoolsinstalled="no"
test "$awk" = "" && echo "'awk' not installed or not found by 'which'" && alltoolsinstalled="no"

if [ "$alltoolsinstalled" = "no" ]; then
  exit 1
fi

OWNER_TO_MATCH="scanner"
EXTENSION_TO_MATCH=".pdf"
OCR_MARK="_ocr"
LOG_FILE=/var/log/ocr/pdfsandwich.log
DO_ARCHIVE="yes"

function do_ocr {
  # the full path to the file, e.g. /opt/scans/scan0001.pdf
  file=$1
  # the directory of the file, e.g. /opt/scans
  base_dir=$(dirname "$file")
  # the directory to store the processed files
  processed_dir=$base_dir/processed
  # the directory to archive the original files
  archive_dir=$base_dir/archive/
  # the complete file name, e.g. scan0001.pdf
  fullfilename=$(basename "$file")
  # the file name, e.g. scan0001
  filename="${fullfilename%.*}"
  # the extension, e.g. pdf
  extension="${fullfilename##*.}"
  extension=$(echo "$extension" | awk '{print tolower($0)}')
  # the path to the ocr'd file, e.g. /opt/scans/processed/scan0001_ocr.pdf
  ocrd_file=$processed_dir/$filename$OCR_MARK.$extension
  
  echo "Doing OCR on input file $fullfilename"
  
  # create processed_dir if not exists
  if [ ! -d $processed_dir ]; then
    echo "Create directory $processed_dir"
    mkdir -p $processed_dir
  fi

  # using pdfsandwich to ocr the file in german
  pdfsandwich -lang deu -rgb -o "$ocrd_file" "$file" >> $LOG_FILE 2>&1
  
  echo "Moving $file to archive"
  # moving the original file to the archive
  if [ "$DO_ARCHIVE" = "yes" ]; then
    # create archive_dir if not exists
    if [ ! -d $archive_dir ]; then
      echo "Create directory $archive_dir"
      mkdir -p $archive_dir
    fi
    mv "$file" $archive_dir
  fi
  # renaming the ocr'd file to the original filename
  mv "$ocrd_file" "$processed_dir/$filename.$extension"
  
  echo "Finished OCR on input file $fullfilename"
}

function do_ocr_on_directory {
  base_dir=$1
  filename_part_to_match=$2
  echo "Doing OCR on input directory $base_dir"
  # get list of files filtered by owner of the file, a string in the filename and the extension
  list_of_files=$(ls -l $base_dir | awk '$3 == "'$OWNER_TO_MATCH'" && 0 < index($9, "'$filename_part_to_match'") && 0 < index(tolower($9), "'$EXTENSION_TO_MATCH'") {print $9}')
  no_of_files=$(if [ -n "$list_of_files" ]; then echo "$list_of_files" | wc -l; else echo 0; fi)
  
  echo "Found $no_of_files files to OCR"
  for filename in $list_of_files; do
    do_ocr "$base_dir/$filename"
  done
  echo "Finished OCR on input directory $base_dir"
}

if [ $# -eq 1 ]; then
  if [ -f "$1" ]; then
    do_ocr "$1"
  elif [ -d "$1" ]; then
    do_ocr_on_directory "$1" ""
  fi
elif [ $# -eq 2 -a -d "$1" ]; then
  base_dir=$1
  filename_part_to_match=$2
  do_ocr_on_directory "$base_dir" "$filename_part_to_match"
else
  echo $#
fi

