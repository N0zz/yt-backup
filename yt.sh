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

# google api key, generate here:
#  https://console.developers.google.com/project
api_key='AIzaSyDucw5w8r6mhTtXRhdzwsDLj3WYmeRpkZk'

# max vids is 50 for now, if you want more google api
# requires to use nextPageToken to get new page of videos
max_vids=5

echo "Enter youtube user name:"
read user_name

while [ -z "$user_name" ]
do
  echo 'User name can not be empty:'
  read user_name
done

echo "How many videos do you want to download(max "$max_vids")?"
read count

until [[ $count =~ ^[\-0-9]+$ ]] && (( $count > 0))
do
  echo 'Wrong value, it has to be positive integer. Try again:'
  read count
done

if (( $count > $max_vids ))
then
  echo "Defaulting videos count to "$max_vids".
  You can download maximum "$max_vids" videos."
  count=$max_vids
fi

user_uploads_key=$(curl --silent  'https://www.googleapis.com/youtube/v3/channels?part=contentDetails&forUsername='$user_name'&key='$api_key | jq '.items[0].contentDetails.relatedPlaylists.uploads')
clear_uploads_key=$(echo $user_uploads_key | cut -d '"' -f 2)



user_videos_list=$(curl --silent  'https://www.googleapis.com/youtube/v3/playlistItems?part=contentDetails&playlistId='$clear_uploads_key'&maxResults='$count'&key='$api_key)

for (( i=0; i<$count; i++ ))
do
  vids_queue[$i]=$(echo $user_videos_list | jq '.items['$i'].contentDetails.videoId' | cut -d '"' -f 2)
done

dir=$user_name
mkdir -p $dir
cd $dir

for i in ${!vids_queue[*]}
do
  current_vid=${vids_queue[$i]}
  if [ $current_vid != null ]
  then  
    youtube-dl "$@" http://youtube.com/watch?v=$current_vid
    ((d_cnt++))
  fi
done

if [ -z "$d_cnt" ]
then
  echo 'Could not download any video. Does this channel exist?'
  cd ..
  rmdir $dir
elif ((  $d_cnt < $count ))
then
  echo 'You have downloaded '$d_cnt' videos instead of '$count'. This channel does not have more vidoes uploaded. Downloaded videos:'
  ls
  cd ..
else
  echo 'You have downloaded '$d_cnt' videos. Videos list:'
  ls
  cd ..
fi