# yt-backup
Simple youtube movies backup script.

# Usage
http://showterm.io/d5b10edcc7a3cb07ec86e

# Info
On debian simply use:    
`sudo apt-get install jq youtube-dl curl`

Using curl to get data from google api.    
https://github.com/bagder/curl

Using jq to decode json data from google api.  
http://stedolan.github.io/jq/  
  
Using youtube-dl to download vidoes.  
http://rg3.github.io/youtube-dl/  
  
You can simply use all youtube-dl functions, exampe:  
./yt.sh -s  
Will results in using youtube-dl like this:  
youtube-dl -s [URL]  
  
Google api key can be generated here(requires enabled YT APIs):  
https://console.developers.google.com/project  
