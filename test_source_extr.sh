
cd ./source_extraction/results_pdf_xml

counter_good=0
counter_empty=0
counter=0



count () {
    while read i;
    do
	counter=$((counter+1))
	n_begin="$(grep -o '>*<' $i | wc -l)"
	num="$(echo $i | cut -d. -f 1-2 | cut -d_ -f 1)";
	source="../results/"$num".tex"
	if [[ $n_begin -ne 0 ]]
	then
	    counter_good=$((counter_good+1))
	    echo -e "\n\n   $source" >> ../../tmp/txt_bestiary/extr_good.txt
	    grep -E "^.documentclass|^.usepackage" "$source" >> ../../tmp/txt_bestiary/extr_good.txt
	    echo -e "" >> ../../tmp/txt_bestiary/extr_good.txt
	    grep -E "newtheorem" "$source" >> ../../tmp/txt_bestiary/extr_good.txt
	    cp $i ../../tmp/txt_bestiary/good_extr/"$num"_source_extr.txt
	else
	    counter_empty=$((counter_empty+1))
	    echo -e "\n\n   $source" >> ../../tmp/txt_bestiary/extr_empty.txt
	    grep -E "^.documentclass|^.usepackage" "$source" >> ../../tmp/txt_bestiary/extr_empty.txt
	    echo -e "" >> ../../tmp/txt_bestiary/extr_empty.txt
	    grep -E "newtheorem" "$source" >> ../../tmp/txt_bestiary/extr_empty.txt
	    cp $i ../../tmp/txt_bestiary/empty_extr/"$num"_source_extr.txt
       fi
    done
    echo "$counter_good good extractions and $counter_empty empty ones out of $counter"
}

ls | grep xml.xml$ | count

cd ../../
