#! /bin/bash
echo "This script finds files >1 year old in your current directory 
      and outputs them to oldfiles.txt"
find . -type f -mtime +365 -exec ls -lh {} \; > oldfiles.txt
