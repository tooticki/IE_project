#!/bin/bash
#TODO: l

all_names="Lemma|Theorem|Corollary|Statement|Proposition|Definition|Remark|Conjecture"
result_names="Lemma|Theorem|Corollary|Statement|Proposition"
number="([0-9](\.)?)*|\."


for sourcetext in source_extraction/txt/*.txt; do
    num="$(echo "$sourcetext" | cut -d. -f 1-2 | cut -d/ -f 3)"
    extrtext=pdf_extraction/$num"_extr.txt"
    pdfcomp=comparison/$num"_pdfcomp.txt"
    sourcecomp=comparison/$num"_sourcecomp.txt"
    if [ -e $extrtext ]; then
	grep -ozP "(?s)\*\*\*(\n)[^0-9]*$number" $extrtext | tr '\0' '\n'   > $pdfcomp 
	# Remove ***, points after each number, and empty lines
	sed -i '/^\*\*\*/ d;s/\.$//;/^\s*$/d' $pdfcomp

	grep -ozP "(?s)\*\*\*(\n)[^0-9\.]+$number" $sourcetext | tr '\0' '\n'   > $sourcecomp
	# Remove ***, points after each number,  empty lines, ^L and ^A
	sed -i '/^\*\*\*/ d;s/\.$//;/^\s*$/d;/^\o14/ d;/^\o1/ d' $sourcecomp

	diff -y $sourcecomp $pdfcomp > comparison/$num"_comp.txt"
	diff $sourcecomp $pdfcomp | diffstat >> comparison/$num"_comp.txt"
	rm $pdfcomp
	rm $sourcecomp
    fi
#    echo No such extraction file: $num"_extr.txt"
done
	

# if [ $# -eq 0 ]
# then
#     grep -oP "^.?($all_names) $number.*" output/txt/*.txt | sed G > output/extraction/everything.txt
# else
#     while getopts "rdRslh" OPTION; do
# 	case $OPTION in
# 	    r)
# 		grep -oP "^.?($result_names) $number.*" output/txt/*.txt | sed G > output/extraction/results.txt
# 		;;
# 	    d)
# 		grep -oP "^.?(Definition) $number.*" output/txt/*.txt | sed G > output/extraction/definitions.txt
# 		;;
# 	    R)
# 		grep -ozP "(?s)\n($result_names) $number.*((\n\n)|(\nProof)|$all_names)" output/txt/*.txt | tr '\0' '\n'   > output/extraction/Results.txt
# 		sed -i 's@output/txt@\n  output/txt@g' output/extraction/Results.txt 
# 	       	;;
# 	    s)
# 		grep -ozP "(?s)begin{(lemma|theorem|statement|corollary)}.*end{(lemma|theorem|statement|corollary)}" source/*[1-9] | tr '\0' '\n'   > output/extraction/source_results.txt
# 		sed -i 's@source/@\n  source/@g' output/extraction/source_results.txt 
# 		;;		
# 	    l)
# 		echo "Not implemented yet :-("
# 		;;
#        	    h)
# 	        echo -e "Usage: ./extract.sh [OPTION]\nCreate file everything.txt containing all found lemmas, theorems, statements, corollaries definitions, and remarks.\nOptions:\n  -r to extract only results (lemmas, theorems, corollaries, and statements)\n  -R to extract results printing the whole text of each of them \n  -d to extract definitions\n  -s to extract results from the source code\n  -l to see links between results\n  -h to see this message" 
# 	esac
#     done    
# fi
