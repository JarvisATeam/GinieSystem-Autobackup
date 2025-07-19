#!/bin/bash 
SEARCH_PATH="$HOME/Library/Mobile 
Documents/com~apple~CloudDocs" 
SEARCH_TERMS="binance wallet crypto" echo " 
Starter sk etter Binance-wallet p iCloud..." 
TOTAL_FILES=$(find "$SEARCH_PATH" -type f | 
wc -l) COUNT=0 # Finner filene n etter n og 
viser prosentvis status find "$SEARCH_PATH" 
-type f | while read -r file; do
    grep -qEi "$SEARCH_TERMS" "$file" && 
echo " Funnet match i: $file"
    
    COUNT=$((COUNT + 1))
ROGRESS=$((COUNT * 100 / TOTAL_FILES))
    > > # Vis prosent kun hver 10. fil for 
unng spam0 == 0 || COUNT == TOTAL_FILES )); 
then ROGRESS% fullfrt...\r"
    fi done
echo -e "\n Sk fullfrt."
