#!/bin/bash

cd input
for f in *.pdf;
do pdftohtml "$f" "../output/html/${f%.*}.html";
done
cd ../
