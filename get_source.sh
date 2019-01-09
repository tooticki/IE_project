# Given that there is a file url_10-14.html in source/url,
#  which is a saved page of an ArXiv search result;
#  saves all pdf-files and sources for papers from this page
#  in ./source

unpack_gz()
{
    while read num; do
	ext="$(file source/$num)"
    if [[ $ext = *"gzip"* ]]; then
	mv source/$num source/$num.gz
	gunzip source/$num.gz
	echo "gz!"
    fi
    done <source/url/reference_numbers.txt
}

unpack_tar()
{
    while read num; do
    ext="$(file source/$num)"
    if [[ $ext = *"tar"* ]]; then
	mkdir source/dir_$num
	tar xopf source/$num -C source/dir_$num
	rm source/$num
	echo "tar!"
    fi	
    done <source/url/reference_numbers.txt
}

rename_tex()
{
    while read num; do
	ext="$(file source/$num)"
	if [[ $ext = *"LaTeX"* ]]; then
	    echo "TeX!"	
	    mv source/$num source/$num.tex
	fi
    done <source/url/reference_numbers.txt
}

# Get reference numbers:
# Given that there is a file url_*.html in source/url,
#  which is a saved page of an ArXiv search result;
#  extract all papers' reference numbers in url/reference_numbers.txt

for html_page in source/url/*html; do
    grep -oP "arXiv:[0-9]+\.[0-9]+" "$html_page" | cut  -d: -f 2 >> source/url/reference_numbers.txt
done

# Get source:
# For each TeX-file num.pdf, we create either dir_num or num.tex
# Ignore files with strange source

while read num; do
    files=(source/*$num*)
    if  [ ! -e "${files[0]}" ] ;
    then
	echo "Downloading https://arxiv.org/e-print/$num"
	curl -s "https://arxiv.org/e-print/$num" > source/$num
	sleep .5
    fi
done <source/url/reference_numbers.txt

# You never know how many layers await
unpack_gz
unpack_tar
unpack_gz
unpack_tar
unpack_gz
unpack_tar
rename_tex

while read num; do
    if { [ -e source/$num.tex ] || [ -e source/dir_$num ]; };
    then
	if [ ! -e source/$num.pdf ] ; then
	    echo "Downloading https://arxiv.org/pdf/$num.pdf"
	    curl -s "https://arxiv.org/pdf/$num.pdf" > source/$num.pdf
	fi
    else
	rm source/$num
	rm source/$num.gz
	echo "Strange file extention, $(file source/$num)"
    fi
done <source/url/reference_numbers.txt
