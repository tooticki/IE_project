#!/bin/bash
#TODO: prop, cor def: add in the lists

all_names="lemma|theorem|corollary|statement|proposition|definition|remark|conjecture"
all_Names="Lemma|Theorem|Corollary|Statement|Proposition|Definition|Remark|Conjecture"
result_Names="Lemma|Theorem|Corollary|Statement|Proposition"
number="([0-9](\.)?)+([[:space:]](\(.*\)))?(\.)[[:space:]]"

all_names_list=($(echo "$all_names" | tr '|' '\n'))
all_Names_list=($(echo "$all_Names" | tr '|' '\n'))

all_names_list[2]="corollary|cor"
all_names_list[3]="statement|stat"
all_names_list[4]="proposition|prop"
all_names_list[5]="definition|def"
all_names_list[6]="conjecture|conj"

if [ $# -eq 0 ]
then
    echo -e `grep -oP "begin\{($all_names)\}.*" source/*tex | wc -l | grep -oP "[0-9]*"` "items in the source"
    echo -e `grep -oP ":.?($all_Names) $number.*" output/extraction/everything.txt | wc -l | grep -oP "[0-9]*"` "items found\n"
    for index in ${!all_names_list[*]}
    do
	e=${all_names_list[$index]}
	d=${all_Names_list[$index]}
	echo -e `grep -oP "begin\{($e)\}.*" source/*tex | wc -l | grep -oP "[0-9]*"`  " $d""s in the source"
	echo -e `grep -oP ":.?($d) $number.*" output/extraction/everything.txt | wc -l | grep -oP "[0-9]*"` " $d""s in the extraction\n"
    done
else
    while getopts ":tlf:" OPTION; do
	case $OPTION in
	    t)
		grep -oP ":.?(Theorem) $number.*" output/extraction/everything.txt | wc -l | grep -oP "[0-9]*"
		echo "theorems found out of"
		grep -oP "begin\{(theorem)\}.*" source/*tex | wc -l | grep -oP "[0-9]*"
		echo "theorems in source."
		;;
	    l)
		grep -oP ":.?(Lemma) $number.*" output/extraction/everything.txt | wc -l | grep -oP "[0-9]*"
		echo "lemmas found out of"
		grep -oP "begin\{(lemma)\}.*" source/*tex | wc -l | grep -oP "[0-9]*"
		echo "lemmas in source."
		;;
	    f)
		s="$OPTARG"
		echo -e `grep -oP "begin\{($all_names)\}.*" source/$s.tex | wc -l | grep -oP "[0-9]*"` "items in the source"
		echo -e `grep -oP "$s.txt:.?($all_Names) $number.*" output/extraction/everything.txt | wc -l | grep -oP "[0-9]*"` "items found\n"
		for index in ${!all_names_list[*]}
		do
		    e=${all_names_list[$index]}
		    d=${all_Names_list[$index]}
		    echo -e `grep -oP "begin\{($e)\}.*" source/$s.tex | wc -l | grep -oP "[0-9]*"`  " $d""s in the source"
		    echo -e `grep -oP "$s.txt:.?($d) $number.*" output/extraction/everything.txt | wc -l | grep -oP "[0-9]*"` " $d""s in the extraction\n"
		done	      		
	esac
    done    
fi
