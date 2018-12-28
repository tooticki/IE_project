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
	            pdftotext "$f" "txt/${f%.*}.txt";
		done
		cd ../
		;;
	    -source_pdf)
		cd source_extraction/results
		for f in *.pdf;
		do
		    pdftotext "$f" "txt/${f%.*}.txt";
		done
		cd ../
		;;
	    *)
		echo "Usage: ./pdftotxts [-source] [-source_pdf]" ;;
	esac
    done
    exit;
fi
