# yt-backup
Simple youtube movies backup script.

# Usage
http://showterm.io/fc8cb3c2f320c3301f693

# Info
Using jq to decode json data from google api.  
http://stedolan.github.io/jq/  
  
Using youtube-dl to download vidoes.  
http://rg3.github.io/youtube-dl/  
  
You can simply use all youtube-dl functions, exampe:  
./yt.sh -s  
Will results in using youtube-dl like this:  
youtube-dl -s [URL]  
  
Google api key can be generated here(requires enables YT APIs):  
https://console.developers.google.com/project  
