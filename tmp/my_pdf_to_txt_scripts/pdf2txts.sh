#!/bin/bash


# A string with command options
options=$@

# An array with all the arguments
arguments=($options)

# Loop index
index=0

if [ ${#arguments[@]} -eq 0 ];
then
    echo "Usage: ./pdftotxts.sh [-source] [-source_pdf]"
else
    for argument in $options
    do
	# Incrementing index
	index=`expr $index + 1`

	# The conditions
	case $argument in
	    -pdf)
		cd source
		for f in *.pdf;
		do
	            ../../pdfminer/pdf2txt.py "$f" "txt/${f%.*}_miner.txt";
		done
		cd ../
		;;
	    -source_pdf)
		cd miner
		for f in ../source_extraction/results/*.pdf;
		do
		    path="$(echo "../source_extraction/txt/${f%.*}_miner.txt" | cut -d/ -f 1-3,7)"
		    pdf2txt.py "$f" > "$path";
		done
		cd ../
		;;
	    *)
		echo "Usage: ./pdf2txts [-source] [-source_pdf]" ;;
	esac
    done
    exit;
fi
