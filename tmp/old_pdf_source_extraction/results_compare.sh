#!/bin/bash
#TODO: l

all_names="Lemma|Theorem|Corollary|Statement|Proposition|Definition|Remark|Conjecture"
result_names="Lemma|Theorem|Corollary|Statement|Proposition"
number="([0-9A_Z](\.)?)*|\."

#clear log
> comparison/log_compare.txt

for sourcecomp in source_extraction/txt/*"_merged.txt"; do
    num="$(echo "$sourcecomp" | cut -d/ -f 3 | cut -d_ -f 1)"
    extrtext=pdf_extraction/$num"_extr.txt"
    pdfcomp=comparison/$num"_pdfcomp.txt"
    if [ -e $extrtext ]; then
	grep -ozP "(?s)\*\*\*(\n)+($result_names)(\s)*$number" $extrtext | tr '\0' '\n'   > $pdfcomp 
	# Remove ***, points after each number, and empty lines
	sed -i '/^\*\*\*/ d;s/\.$//;/^\s*$/d' $pdfcomp
	sort -o $pdfcomp $pdfcomp

	diff -y $sourcecomp $pdfcomp > comparison/$num"_comp.txt"
	
	echo -e $num ":\c" | tee -a comparison/log_compare.txt
	diff $sourcecomp $pdfcomp | diffstat | head -n 1 | tee -a comparison/log_compare.txt
	rm $pdfcomp
    fi
#    echo No such extraction file: $num"_extr.txt"
done
	
