#!/bin/bash
#
# Using jq to decode json data from google api.
#  http://stedolan.github.io/jq/
#
# Using youtube-dl to download vidoes.
#  http://rg3.github.io/youtube-dl/
#
# You can simply use all youtube-dl functions, exampe:
#  ./yt.sh -s
# Will results in using youtube-dl like this:
#  youtube-dl -s [URL]
#
# TODO : take care about using variables and quotation style
# according to google style guide for bash shell scripting
# https://google-styleguide.googlecode.com/svn/trunk/shell.xml

# google api key, generate here:
#  https://console.developers.google.com/project
readonly api_key='AIzaSyDucw5w8r6mhTtXRhdzwsDLj3WYmeRpkZk'

readonly api_base='https://www.googleapis.com/youtube'
readonly api_version='v3'

# max vids is 50 for now, if you want more google api
# requires to use nextPageToken to get new page of videos
#max_vids=50
readonly vids_per_page=5

read_data(){
  # Get channel name and videos count
  echo "Enter youtube user name:"
  read user_name

  while [ -z "$user_name" ]; do
    echo 'User name can not be empty:'
    read user_name
  done

  echo "How many videos do you want to download?"
  read count

  until [[ $count =~ ^[\-0-9]+$ ]] && (( $count > 0)); do
    echo 'Wrong value, it has to be positive integer. Try again:'
    read count
  done
}

request_uploads_key(){
  # Get requested channel uploads key
  local final=$api_base'/'$api_version
  final+='/channels?part=contentDetails&forUsername='
  final+=$user_name'&key='$api_key
  user_uploads_key=$(curl --silent $final \
                   | jq '.items[0].contentDetails.relatedPlaylists.uploads')
  clean_uploads_key=$(echo $user_uploads_key | cut -d '"' -f 2)
}

request_vids_list(){
  # Get list of vidoes ids to download
  until [ "$done" == "true" ]; do  
    ((i++))
    if [ -z "$next_page" ]; then
      local final=$api_base'/'$api_version
      final+='/playlistItems?part=contentDetails&playlistId='
      final+=$clean_uploads_key'&maxResults='
      final+=$vids_per_page'&key='$api_key
      next_page=$(curl --silent $final \
                | jq '.nextPageToken' \
                | cut -d '"' -f 2)
      
      final=$api_base'/'$api_version
      final+='/playlistItems?part=contentDetails&playlistId='
      final+=$clean_uploads_key'&maxResults='$vids_per_page'&key='$api_key
      user_videos_list=$(curl --silent $final)
    else
      final=$api_base'/'$api_version
      final+='/playlistItems?part=contentDetails&playlistId='
      final+=$clean_uploads_key'&maxResults='$vids_per_page
      final+='&pageToken='$next_page'&key='$api_key
      user_videos_list=$(curl --silent $final)
      
      final=$api_base'/'$api_version
      final+='/playlistItems?part=contentDetails&playlistId='
      final+=$clean_uploads_key'&maxResults='$vids_per_page
      final+='&pageToken='$next_page'&key='$api_key
      next_page=$(curl --silent $final \
                | jq '.nextPageToken' \
                | cut -d '"' -f 2)
    fi
    
    for (( k=0; k<$vids_per_page; k++ )); do
      vid_pos=$(($k+($i-1)*$vids_per_page))
      vids_queue[$vid_pos]=$(echo $user_videos_list \
                           | jq '.items['$k'].contentDetails.videoId' \
                           | cut -d '"' -f 2)
      ((saved_vids++))
    done

    echo -ne "Fetching channel vids ("$saved_vids"/"$count")...\r"

  
    if (( $count < $saved_vids )); then
      done="true"
      # Prints videos list for debugging purposes  
#     for v in ${!vids_queue[*]}; do
#       printf "%d:%s\n" $v ${vids_queue[$v]}
#     done
    fi
  done
}

create_directory(){
  # Create directory named after youtube channel
  dir=$user_name
  mkdir -p $dir
  cd $dir
}

calculate_time_left(){
  time_now=$(date +%s)
  time_from_start=$(($time_now-$start))
  avg_time=$(($time_from_start/$d_cnt))
  vids_left=$(($count-$d_cnt))
  time_left=$(($avg_time*($vids_left+1)))
  
  ((sec=time_left%60, time_left/=60, min=time_left%60, hrs=time_left/60))
  eta=$(printf "%d:%02d:%02d" $hrs $min $sec)
}

download_vids(){
  # Downloads all vids from the list one after another
  
  # start date to calculate time to finish downloading
  start=$(date +%s)

  for i in ${!vids_queue[*]}; do
    if (( $i >= $count )); then
      break
    fi
    
    current_vid=${vids_queue[$i]}
    
    if ! [ -z "$current_vid" ]; then
      if [ "$current_vid" != null ]; then
        ((d_cnt++))
        
        calculate_time_left
        
        echo -ne "Downloading "$current_vid"("$d_cnt"/"$count") ETA: "$eta"\r"
        local final=http://youtube.com/watch?v=
        final+=$current_vid
        youtube-dl "$@" -q --console-title $final
      fi
    fi
  done
}

echo_final_info(){
  # Prints info about downloaded/not downloaded videos and lists them
 
  ((sec=time_from_start%60, time_from_start/=60))
  ((min=time_from_start%60, hrs=time_from_start/60))
  total_time=$(printf "%d hours %02d minutes and %02d seconds" $hrs $min $sec)
  
  if [ -z "$d_cnt" ]; then
    echo 'Could not download any video. Does this channel exist?'
    cd ..
    rmdir $dir
  elif ((  $d_cnt < $count )); then
    local final='You have downloaded '$d_cnt' videos '
    final+='instead of '$count' in '$total_time'. '
    final+='This channel does not have more vidoes uploaded. '
    final+='Downloaded videos:'
    echo $final
    ls -1
    cd ..
  else
    echo 'You have downloaded '$d_cnt' videos in '$total_time'. Videos list:'
    ls -1
    cd ..
  fi
}

main(){
  read_data
  request_uploads_key
  request_vids_list
  create_directory
  download_vids
  echo_final_info
}

main