#!/bin/bash

: : ' This script, for each tex-source, generates a text-file with the
    list of results and their bodies:

    for each tex source ./source/num.tex,
    we create its copy ./source_extraction/results/num.tex,
    add there the line  \usepackage{extract},
    and compile: results are in ./source_extraction/txt/num_source_text
    extracting of results is implemented in extract.sty 
'
 > source_extraction/results/fatal_error.txt

for paper in source/*pdf; do
    num="$(echo "$paper" | cut -d. -f 1-2 | cut -d/ -f 2)"

    # For now, only for tex-files, not dir (TODO)
    if [ -e source/$num.tex ]; then
	
	echo "$num"
	
	# Add \usepackage{extract} in the preambule of a copy
	sed -e '0,/\\newtheorem/ s/\\newtheorem/%EXTRACTING\n \\usepackage{.\/extract}\n%ENDEXTRACTING\n\\newtheorem/' source/$num.tex > source_extraction/results/$num.tex

	# Remove hyperref since it causes problems (TODO: find another solution)
	# Remove all ", hyperref", "hyperref," and strings containing "{hyperref}"
	sed -i 's/hyperref,//;s/,hyperref//;s/, hyperref//' ./source_extraction/results/$num.tex
	sed -i '/{hyperref}/d' ./source_extraction/results/$num.tex
	
	
	# Extract results with extract.sty
	pdflatex -interaction=nonstopmode -output-directory=source_extraction/results  source_extraction/results/$num.tex >/dev/null
	pdflatex -interaction=nonstopmode -output-directory=source_extraction/results  source_extraction/results/$num.tex >/dev/null

	if grep -q "Fatal error occurred, no output PDF file produced!" "source_extraction/results/$num.log"; then
	    echo "  Fatal error!"
	    echo "########################   $num\n" >> source_extraction/results/fatal_error.txt
	    cat  source_extraction/results/$num.log >> source_extraction/results/fatal_error.txt
	    
	fi
	
	mv source_extraction/results/$num"_source_text.txt" source_extraction/txt/$num"_source_text.txt"
    fi
done

echo "Done!"
