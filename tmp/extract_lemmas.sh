#!/bin/bash
# -p: extract the whole theorem (the part before the proof or other object)
#TODO: l

if [ $# -eq 0 ]
then
    grep -oP "^Lemma [1-9][1-9]?[[:space:]]?\..*" output/txt/*.txt | sed G > output/extraction/lemmas.txt
else
    while getopts "plh" OPTION; do
	case $OPTION in
	    p)
		grep -ozP "(?s)\nLemma [1-9][1-9]?[[:space:]]?\..*?(Proof|Lemma|Lemma|Definition|Figure)" output/txt/*.txt | tr '\0' '\n'   > output/extraction/p_lemmas.txt
		sed -i 's@output/txt@\n  output/txt@g' output/extraction/p_lemmas.txt 
		;;
	    l)
	        grep -ozP "(?s)\nLemma [1-9][1-9]?[[:space:]]?\..*?(Proof|Lemma|Lemma|Definition|Figure)" output/txt/*.txt | tr '\0' '\n'   > output/extraction/p_lemmas.txt
	        sed -i 's@output/txt@\n  output/txt@g' output/extraction/p_lemmas.txt
		echo "Not implemented yet :-("
		;;
       	    h)
	        echo -e "Use -p to extract full lemmas\n    -l to see links between results\n    -h to see this message" 
	esac
    done    
fi
