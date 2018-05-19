#! /bin/bash
echo " This script finds files >1 GB in your current directory and outputs to
       gigfiles.txt"
find . -type f -size +1000000k -exec ls -lh {} \; > gigfiles.txt
