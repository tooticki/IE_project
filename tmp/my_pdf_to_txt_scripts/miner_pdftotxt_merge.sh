#!/bin/bash
#TODO: l

all_names="Lemma|Theorem|Corollary|Statement|Proposition|Definition|Remark|Conjecture"
result_names="Lemma|Theorem|Corollary|Statement|Proposition"
number="([0-9A_Z](\.)?)*|\."

> cmp_result.txt
for pdftotxttext in source_extraction/txt/*[0-9].txt; do
    num="$(echo "$pdftotxttext" | cut -d. -f 1-2 | cut -d/ -f 3)"
#    echo $num
    minertext=source_extraction/txt/$num"_miner.txt"
    minercomp=source_extraction/txt/comparison_miner_pdftotxt/$num"_minercomp.txt"
    pdftotxtcomp=source_extraction/txt/comparison_miner_pdftotxt/$num"_sourcecomp.txt"
    if [ -e $pdftotxttext ]; then
	grep -ozP "(?s)\*\*\*(\n)+($result_names)(\s)*$number" $pdftotxttext | tr '\0' '\n'   > $pdftotxtcomp 
	# Remove ***, points after each number, and empty lines
	sed -i -r '/^\*\*\*/ d;s/\.$//;/^\s*$/d;/^\o14/ d;/^\o1/ d; s/([a-z])([0-9])/\1 \2/g' $pdftotxtcomp

	grep -ozP "(?s)\*\*\*(\n)+($result_names)(\s)*$number" $minertext | tr '\0' '\n'   > $minercomp
	# Remove ***, points after each number,  empty lines, ^L and ^A
	sed -i -r '/^\*\*\*/ d;s/\.$//;/^\s*$/d;/^\o14/ d;/^\o1/ d; s/([a-z])([0-9])/\1 \2/g' $minercomp

	diff -y $minercomp $pdftotxtcomp > source_extraction/txt/comparison_miner_pdftotxt/$num"_c.txt"
	
	diff -w $minercomp $pdftotxtcomp | diffstat  >> source_extraction/txt/comparison_miner_pdftotxt/cmp_result.txt
	sort $minercomp $pdftotxtcomp | uniq > source_extraction/txt/$num"_merged.txt"
	rm $pdftotxtcomp
	rm $minercomp
    fi
done

pluses="$(grep -o "[^(]+" source_extraction/txt/comparison_miner_pdftotxt/cmp_result.txt | wc -l)"
minuses="$(grep -o "[^(]-" source_extraction/txt/comparison_miner_pdftotxt/cmp_result.txt | wc -l)"
echo  "${pluses} times pdftotxt was better and ${minuses} times miner was better"
