#!/bin/bash

: ' For each pdf-file num.pdf from source_extraction/results_pdf_xml,
  transform it to source_extraction/results_pdf_xml/num_xml.xml '

#TODO: test again

for f in source_extraction/results_pdf_xml/*.pdf;
do
    num="$(echo "$f" | cut -d. -f 1-2 | cut -d/ -f 3)"
    echo $num
    if [ ! -e "${f%.*}_resxml.xml" ]; then
	echo "Extracting xml-lines from results pdf: "$f
	python miner/tools/pdf2txt.py -t xml "$f" > source_extraction/results_pdf_xml/tmp.xml;
	xgrep -t -x "//textline" source_extraction/results_pdf_xml/tmp.xml > "${f%.*}_resxml.xml"
    fi
    if [ ! -e "${f%.*}_xml.xml" ]; then
	echo "Extracting xml-lines from full pdf: "$f
	python miner/tools/pdf2txt.py -t xml "source/$num.pdf" > source_extraction/results_pdf_xml/tmp.xml;
	xgrep -t -x "//textline" source_extraction/results_pdf_xml/tmp.xml > "${f%.*}_xml.xml"
    fi
done

rm source_extraction/results_pdf_xml/tmp.xml



