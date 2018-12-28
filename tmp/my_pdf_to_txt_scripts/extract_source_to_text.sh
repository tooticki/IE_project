#!/bin/bash
#TODO: prop, cor def: add in the lists

for paper in source/*pdf; do
    num="$(echo "$paper" | cut -d. -f 1-2 | cut -d/ -f 2)"
    
    # for now, only for tex-files, not dir
    if [ -e source/$num.tex ]; then
	# Add usepackage extract.sty

	# Add \usepackage{extract} in the preambule
	sed -e '0,/\\newtheorem/ s/\\newtheorem/%EXTRACTING\n \\usepackage{.\/extract}\n%ENDEXTRACTING\n\\newtheorem/' source/$num.tex > source_extraction/results/$num.tex

	# Extract propositions with .sty
	pdflatex -interaction=nonstopmode -output-directory=source_extraction/results  source_extraction/results/$num.tex
	pdflatex -interaction=nonstopmode -output-directory=source_extraction/results  source_extraction/results/$num.tex
    fi
done

cd source_extraction/results
for f in *.pdf;
do
	pdftotext "$f" "../txt/${f%.*}.txt";
done
cd ../

#^L is a new page = new result
