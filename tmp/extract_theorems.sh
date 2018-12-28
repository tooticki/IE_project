#!/bin/bash
# -p: extract the whole theorem (the part before the proof or other object)
#TODO: l

if [ $# -eq 0 ]
then
    grep -oP "^Theorem [1-9][1-9]?[[:space:]]?\..*" output/txt/*.txt | sed G > output/extraction/theorems.txt
else
    while getopts "plh" OPTION; do
	case $OPTION in
	    p)
		grep -ozP "(?s)\nTheorem [1-9][1-9]?[[:space:]]?\..*?(Proof|Theorem|Lemma|Definition|Figure)" output/txt/*.txt | tr '\0' '\n'   > output/extraction/p_theorems.txt
		sed -i 's@output/txt@\n  output/txt@g' output/extraction/p_theorems.txt 
		;;
	    l)
	        grep -ozP "(?s)\nTheorem [1-9][1-9]?[[:space:]]?\..*?(Proof|Theorem|Lemma|Definition|Figure)" output/txt/*.txt | tr '\0' '\n'   > output/extraction/p_theorems.txt
	        sed -i 's@output/txt@\n  output/txt@g' output/extraction/p_theorems.txt
		echo "Not implemented yet :-("
		;;
       	    h)
	        echo -e "Use -p to extract full theorems\n    -l to see links between results\n    -h to see this message" 
	esac
    done    
fi
