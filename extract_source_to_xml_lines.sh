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
    pdf_xml_dir=source_extraction/results_pdf_xml
    results_dir=source_extraction/results
    
    # If source code is a tex-file    
    if [ -e source/$num.tex ] && [ ! -e $pdf_xml_dir/$num".pdf" ] ; then
	echo "Extracting results from source to pdf-file: $num"
	
	# Add \usepackage{extract} in the preambule of a copy
	sed -e '0,/\\newtheorem/ s/\\newtheorem/%EXTRACTING\n \\usepackage{.\/extract}\n%ENDEXTRACTING\n\\newtheorem/' source/$num.tex > $results_dir/$num.tex

	# Remove hyperref since it causes problems (TODO: find another solution)
	# Remove all ", hyperref", "hyperref," and strings containing "{hyperref}"
	sed -i 's/hyperref,//;s/,hyperref//;s/, hyperref//' $results_dir/$num.tex
	sed -i '/{hyperref}/d' $results_dir/$num.tex

	# Extract results with extract.sty to get pdf-file
	# Timeout guarantees that the compilation doesn't loop
	timeout 40s pdflatex -interaction=nonstopmode -output-directory=$results_dir  $results_dir/$num.tex >/dev/null
	timeout 40s pdflatex -interaction=nonstopmode -output-directory=$results_dir  $results_dir/$num.tex >/dev/null

	if grep -q "Fatal error occurred, no output PDF file produced!" "source_extraction/results/$num.log" ; then
	    echo "  Fatal error!"
	    echo "########################   $num\n" >> $results_dir/fatal_error.txt
	    cat  $results_dir/$num.log >> $results_dir/fatal_error.txt
	elif [ -e $results_dir/$num".pdf" ]; then
	     mv $results_dir/$num".pdf" $pdf_xml_dir/$num".pdf"	
	fi	
    fi
    # If source code is a directory
    if [ -e source/"dir_"$num ] && [ ! -e $pdf_xml_dir/$num".pdf" ] ; then
	tex_files=( source/"dir_"$num/*."tex" )
	count_tex=( ${#tex_files[@]} )
	tex_file=( ${tex_files[0]} )
	# If there is exactly one tex-file (otherwise, don't know which to compile, ignore)
	# TODO: compile file with document class grep --include=\*.tex -rnw '.' -e '\documentclass'
	if [ $count_tex == 1 ] ; then
	    echo "Extracting results from source to pdf-file: $num"
	    # Copy folder to source_extraction/results

	    dir_copy="source_extraction/results/dir_$num"
	    if [ ! -e source/"dir_"$num/$num".tex" ] ; then
		mv $tex_file source/"dir_"$num/$num".tex" # Rename
	    fi
	    tex_file=$num".tex"
	    cp -r source/"dir_"$num $dir_copy
	    # Add \usepackage{extract} in the preambule of a copy
	    sed -i '0,/\\newtheorem/ s/\\newtheorem/%EXTRACTING\n \\usepackage{.\/extract}\n%ENDEXTRACTING\n\\newtheorem/' $dir_copy/$tex_file
	    # Remove hyperref since it causes problems (TODO: find another solution)
	    # Remove all ", hyperref", "hyperref," and strings containing "{hyperref}"
	    sed -i 's/hyperref,//;s/,hyperref//;s/, hyperref//' $dir_copy/$tex_file
	    sed -i '/{hyperref}/d' $dir_copy/$tex_file
	    
	    # Extract results with extract.sty to get pdf-file
	    # Timeout guarantees that the compilation doesn't loop	    
	    timeout 40s pdflatex -interaction=batchmode -output-directory=$results_dir  $dir_copy/$tex_file >/dev/null
	    timeout 40s pdflatex -interaction=batchmode -output-directory=$results_dir  $dir_copy/$tex_file >/dev/null
	    
	    if grep -q "Fatal error occurred, no output PDF file produced!" "source_extraction/results/$num.log" ; then
		echo "  Fatal error!"
		echo "########################   $num\n" >> $results_dir/fatal_error.txt
		cat  $results_dir/$num.log >> $results_dir/fatal_error.txt
	    elif [ -e $results_dir/$num".pdf" ]; then
		mv $results_dir/$num".pdf" $pdf_xml_dir/$num".pdf"	
	    fi
	fi
    fi
    
done

# Extract xml-lines from all the pdf-files
./pdfs_to_xml_lines.sh

echo "Done!"
