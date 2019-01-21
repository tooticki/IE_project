#!/bin/bash

: : ' This script analyses the number of papers at each step of
      generation of training data   '

# Uploaded PDF files
source_pdf_files=( source/*."pdf" )
count_source_pdf_files=( ${#source_pdf_files[@]} )

# Uploaded tex files source code
source_tex_files=( source/*."tex" )
count_source_tex_files=( ${#source_tex_files[@]} )

# Uploaded dir source code
source_dirs=( source/"dir_"* )
count_source_dirs=( ${#source_dirs[@]} )

# Uploaded dirs suitable for extraction
source_ext_dirs=( source_extraction/results/"dir_"* )
count_source_ext_dirs=( ${#source_ext_dirs[@]} )

# PDFs with results where extraction went well
source_ext_pdf_files=(source_extraction/results_pdf_xml/*."pdf" )
count_source_ext_pdf_files=( ${#source_ext_pdf_files[@]} )

count_empty()
{
    empty_count=0
    for file in "$1"*"$2"; do
	if [ ! -s $file ] ; then
	    empty_count=$((empty_count+1))
	fi
    done
    echo $empty_count
}

# Xml files with results generated with miner
source_ext_resxml_files=( source_extraction/results_pdf_xml/*"_resxml.xml" )
count_source_ext_resxml_files=( ${#source_ext_resxml_files[@]} )

# Xml files with full text generated with miner
source_ext_textxml_files=(source_extraction/results_pdf_xml/*"_xml.xml" )
count_source_ext_textxml_files=( ${#source_ext_textxml_files[@]} )


resxml_empty_count=$(count_empty source_extraction/results_pdf_xml_miner_six/ "_resxml.xml")
textxml_empty_count=$(count_empty source_extraction/results_pdf_xml_miner_six/ "_xml.xml")

count_source_ext_textxml_files=$((count_source_ext_textxml_files-textxml_empty_count))
count_source_ext_resxml_files=$((count_source_ext_resxml_files-resxml_empty_count))

# Xml files with results generated with miner.six
source_ext_resxml_files_miner_six=( source_extraction/results_pdf_xml_miner_six/*"_resxml.xml" )
count_source_ext_resxml_files_miner_six=( ${#source_ext_resxml_files_miner_six[@]} )

# Xml files with with full text generated with miner.six
source_ext_textxml_files_miner_six=(source_extraction/results_pdf_xml_miner_six/*"_xml.xml" )
count_source_ext_textxml_files_miner_six=( ${#source_ext_textxml_files_miner_six[@]} )

resxml_empty_count_miner_six=$(count_empty source_extraction/results_pdf_xml_miner_six/ "_resxml.xml")
textxml_empty_count_miner_six=$(count_empty source_extraction/results_pdf_xml_miner_six/ "_xml.xml")

count_source_ext_textxml_files_miner_six=$((count_source_ext_textxml_files_miner_six-textxml_empty_count_miner_six))
count_source_ext_resxml_files_miner_six=$((count_source_ext_resxml_files_miner_six-resxml_empty_count_miner_six))



training_files=(training_data/*"training.csv" )
count_training_files=( ${#training_files[@]} )

echo "Uploaded data: $count_source_pdf_files files"

echo "    $count_source_tex_files files with source code as a tex-file and
    $count_source_dirs files with source code as a directory;
    $count_source_ext_dirs directories contained one single tex-file inside"

echo "Succeeded latex-compiling: $count_source_ext_pdf_files files"

echo "Succeeded xml-extraction with miner: $count_source_ext_textxml_files of fulltext files and $count_source_ext_resxml_files of results files"

echo "Succeeded xml-extraction with miner.six: $count_source_ext_textxml_files_miner_six of fulltext files and $count_source_ext_resxml_files_miner_six of results files"

echo "Succeeded generating training vectors:  $count_training_files"
