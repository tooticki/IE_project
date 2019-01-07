#!/bin/bash

: : ' This script, for each tex-source, generates a text-file with the
    list of results.

    for each tex source ./source/num.tex,
    we create its copy ./source_extraction/results/num.tex,
    add there the line  \usepackage{extract},
    and compile: pdf-results are in ./source_extraction/results
    then we extract text from pdf using pdf-miner -xml
    extracting of results is implemented in extract.sty 
'
 > source_extraction/results/fatal_error.txt

 # Extract results from source to pdf-files
for paper in source/*pdf; do
    num="$(echo "$paper" | cut -d. -f 1-2 | cut -d/ -f 2)"

    # For now, only for tex-files, not dir (TODO)
    
    if [ -e source/$num.tex ] && [ ! -e source_extraction/results_pdf_xml/$num".pdf" ] ; then
	echo "Extracting results from source to pdf-file: $num"
	
	# Add \usepackage{extract} in the preambule of a copy
	sed -e '0,/\\newtheorem/ s/\\newtheorem/%EXTRACTING\n \\usepackage{.\/extract}\n%ENDEXTRACTING\n\\newtheorem/' source/$num.tex > source_extraction/results/$num.tex

	# Remove hyperref since it causes problems (TODO: find another solution)
	# Remove all ", hyperref", "hyperref," and strings containing "{hyperref}"
	sed -i 's/hyperref,//;s/,hyperref//;s/, hyperref//' ./source_extraction/results/$num.tex
	sed -i '/{hyperref}/d' ./source_extraction/results/$num.tex

	# Extract results with extract.sty to get pdf-file
	# Timeout guarantees that the compilation doesn't loop
	timeout 50s pdflatex -interaction=nonstopmode -output-directory=source_extraction/results  source_extraction/results/$num.tex >/dev/null
	timeout 50s pdflatex -interaction=nonstopmode -output-directory=source_extraction/results  source_extraction/results/$num.tex >/dev/null

	if grep -q "Fatal error occurred, no output PDF file produced!" "source_extraction/results/$num.log" ; then
	    echo "  Fatal error!"
	    echo "########################   $num\n" >> source_extraction/results/fatal_error.txt
	    cat  source_extraction/results/$num.log >> source_extraction/results/fatal_error.txt
	elif [ -e source_extraction/results/$num".pdf" ]; then
	     mv source_extraction/results/$num".pdf" source_extraction/results_pdf_xml/$num".pdf"	
	fi	

    fi        
done
# Extract xml-lines from all the pdf-files
./pdfs_to_xml_lines.sh

# Extract text from xmls
#TODO: write

echo "Done!"
