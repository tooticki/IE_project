#!/bin/bash

: ' For each pdf-file num.pdf from source, transform it
  to pdf_extraction/xml/num_xml.xml 
'

#TODO: test

for f in *.pdf;
do
    echo $f
    if [ ! -e "${f%.*}_xml.xml" ]; then
	python ../../../miner/tools/pdf2txt.py -t xml "$f" > tmp.xml;
	xgrep -t -x "//textline" tmp.xml > "${f%.*}_xml.xml"
    fi
done

rm tmp.xml



