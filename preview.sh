#!/bin/bash

# USAGE:
#    ./preview.sh [filename] [ft_group] [process_type]
#
# ARGS:
#    filename      : target filename
#    ft_group      : image : Use imagemagick
#                    video : Use ffmpeg
#    process_type  : single : Generate preview for the single file
#                    all    : Generate previews for all files in the dir
# DEPENDENCIES:
#    imagemagick
#    ffmpeg
#    kitten icat (or other graphic protocols)

# --------------------------------------------------------------------------------
# Consts
# --------------------------------------------------------------------------------

# Cache dir
CACHE_DIR="$HOME/.cache/vifm/preview"
# Path for saving previous dir info
PREV_DIR_FILE="$HOME/.cache/vifm/preview/previous_dir"
# Log file path
LOG_FILE="$HOME/.cache/vifm/preview/log"
# Loggin or not
LOG_ENABLED=1 # 0: No logging | 1: Logging (cause timeloss)

# Images
IMAGE_PATTERNS="*.bmp *.jpg *.jpeg *.png *.gif *.xpm *.avif *.webp *.heic"
IMAGE_QUALITY=80
IMAGE_RESIZE="600x600" # the size of vifm window on full screen
# IMAGE_RESIZE="1376x1617" # Measured exact size for me, then remove '--scale-up' option from 'kitten icat'

# Videos
VIDEO_PATTERNS="*.avi *.mp4 *.wmv *.dat *.3gp *.ogv *.mkv *.mpg *.mpeg *.vob fl[icv] *.m2v *.mov *.webm *.ts *.mts *.m4v r[am] *.qt *.divx as[fx]"
VIDEO_FRAME=1000      # frame num for cut, from the movie's start
VIDEO_SCALE="640:360" # width:height
# VIDEO_SCALE="1376:774" # Measured exact size for me, then remove '--scale-up' option from 'kitten icat'

# --------------------------------------------------------------------------------
# Variables
# --------------------------------------------------------------------------------
prev_dir=""
cur_dir=""

# --------------------------------------------------------------------------------
# Functions
# --------------------------------------------------------------------------------

# Loging
function Log() {
   label="$1"
   value="$2"
   length=12
   if [[ $LOG_ENABLED == 1 ]]; then
      printf "%-${length}s: %s\n" "$label" "$value" >>"$LOG_FILE"
   fi
}

# Generate preview & return the hash path
function GeneratePreview() {
   file="$1"      # file path
   ft_group="$2"  # image | viode
   sync_mode="$3" # async | sync
   # Get preview filename (hash)
   hash=$(echo $(realpath "$file") | sha256sum | cut -d' ' -f1) # get hash
   preview="$CACHE_DIR/$hash.jpg"                               # preview path

   # Generate preview
   if [ ! -f "$preview" ]; then
      if [[ $ft_group == "image" ]]; then
         # Image
         if [[ $sync_mode == 'async' ]]; then
            magick "$file" -quality $IMAGE_QUALITY -resize $IMAGE_RESIZE "$preview" &>/dev/null &
         elif [[ $sync_mode == 'sync' ]]; then
            magick "$file" -quality $IMAGE_QUALITY -resize $IMAGE_RESIZE "$preview" &>/dev/null
         fi
      elif [[ $ft_group == "video" ]]; then
         # Video
         if [[ $sync_mode == 'async' ]]; then
            ffmpeg -y -i "$1" -vf "select='eq(n,$VIDEO_FRAME)',scale=$VIDEO_SCALE" -frames:v 1 "$preview" &>/dev/null &
         elif [[ $sync_mode == 'sync' ]]; then
            ffmpeg -y -i "$1" -vf "select='eq(n,$VIDEO_FRAME)',scale=$VIDEO_SCALE" -frames:v 1 "$preview" &>/dev/null
         fi
      fi
   fi
   Log "preview" "$ft_group=$preview"

   echo $preview # 'kitten icat' get this echo
   # printf "%s\n" "$preview"
}

# Record current directory
function RecordCurDir() {
   echo $cur_dir >"$PREV_DIR_FILE"
}

# Generate image previews for all files in dir
function GenerateImagePreviewAll() {
   # List files in the directory and loop through each pattern
   local cnt=0
   for pat in $IMAGE_PATTERNS; do
      Log "pat" "$pat"
      # For each pattern, find matching files
      for file in "$cur_dir"/$pat; do
         # Only proceed if $file is a regular file
         if [[ -f "$file" ]]; then
            Log "file" "$file"
            local preview=$(GeneratePreview "$file" image async) # Execute without echo
            ((cnt++))
         fi
      done
   done
   wait
   echo $cnt
}

# Generate video previews for all files in dir
function GenerateVideoPreviewAll() {
   # List files in the directory and loop through each pattern
   local cnt=0
   for pat in $VIDEO_PATTERNS; do
      Log "pat" "$pat"
      # For each pattern, find matching files
      for file in "$cur_dir"/$pat; do
         # Only proceed if $file is a regular file
         if [[ -f "$file" ]]; then
            Log "file" "$file"
            local preview=$(GeneratePreview "$file" video async) # Execute without echo
            ((cnt++))
         fi
      done
   done
   wait
   echo $cnt
}

# --------------------------------------------------------------------------------
# Main script
# --------------------------------------------------------------------------------

function main() {
   # Get directories
   # Logging
   Log "ft_group" "$FT_GROUP"
   Log "process_type" "$PROCESS_TYPE"
   Log "prev_dir" "$prev_dir"
   Log "cur_dir" "$cur_dir"
   Log "file" "$FILE_PATH"

   if [[ $PROCESS_TYPE == "all" ]]; then
      # GeneratePreviewAll()' (in background)
      local image_cnt=0
      local video_cnt=0
      if [[ "$prev_dir" != "$cur_dir" ]]; then # Check if the directory has changed
         image_cnt=$(GenerateImagePreviewAll)
         Log "function" "GenerateImagePreviewAll() processed: $image_cnt image files"
         video_cnt=$(GenerateVideoPreviewAll)
         Log "function" "GenerateVideoPreviewAll() processed: $video_cnt video files"
      fi
      Log "function" "RecordCurDir()"
      RecordCurDir "$FILE_PATH"
   elif [[ $PROCESS_TYPE == "single" ]]; then
      # Generate preview for the single file
      GeneratePreview "$FILE_PATH" $FT_GROUP sync
      # local preview=$(GeneratePreview "$FILE_PATH" $FT_GROUP) # Execute without echo
      Log "function" "GeneratePreview() processed: '$FILE_PATH'"
   else
      Log "ERROR" "Invalid process_type '$PROCESS_TYPE'"
   fi
}

# --------------------------------------------------------------------------------
# Main script
# --------------------------------------------------------------------------------

# Get args
FILE_PATH="${1//\\ / }" # replace '\ ' to ' '
FT_GROUP="$2"
PROCESS_TYPE="$3"

# Create cache directory
mkdir -p "$CACHE_DIR"

# Logging
Log "filename" "$FILE_PATH"
Log "ft_group" "$FT_GROUP"
Log "process_type" "$PROCESS_TYPE"

# Validate
if [ ! -f "$FILE_PATH" ]; then
   Log "ERROR" "[filename] '$FILE_PATH' not exists"
   # exit
fi
if [[ FT_GROUP != "image" && FT_GROUP != "video" ]]; then
   Log "ERROR" "[ft_group] has to be 'image' | 'video'"
   # exit
fi
if [[ $PROCESS_TYPE != "single" && $PROCESS_TYPE != "all" ]]; then
   Log "ERROR" "[process_type] has to be 'single' | 'all'"
   # exit
fi

cur_dir=$(dirname "$(realpath "$FILE_PATH")")
[ ! -f "$PREV_DIR_FILE" ] && prev_dir="" || prev_dir=$(cat "$PREV_DIR_FILE")

# Execute
main "$FILE_PATH" "$FT_GROUP" "$PROCESS_TYPE"
