#!/bin/bash

cd source
for f in *.pdf;
do
    pdftohtml "$f" "html/$f.html";
done
cd ../


