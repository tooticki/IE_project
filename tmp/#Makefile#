# Long first parts of Grobid commands

GROBID_1 := java -Xmx1G -jar grobid-0.5.1/grobid-core/build/libs/grobid-core-0.5.1-onejar.jar -gH grobid-0.5.1/grobid-home
GROBID_2 := java -Xmx2G -jar grobid-0.5.1/grobid-core/build/libs/grobid-core-0.5.1-onejar.jar -gH grobid-0.5.1/grobid-home

# Now the rules. In those rules,
# $@ == output
# $< == first input (usually there is only one, so it's fine)
# $^ == all the inputs, separated by spaces
# The general format is:
# OUTPUT: INPUTS
# 	COMMAND
#  /\
# (this is a tab haracter, NOT spaces.)

# xml-generation
header:
	$(GROBID_1) -dIn input -dOut output/header -r -exe processHeader

full:
	$(GROBID_1) -dIn input -dOut output/full_text -r -exe processFullText

references:
	$(GROBID_2) -dIn input -dOut output/references -r -exe processReferences

#html-generation
html:
	./generate_html.sh


# searching for things

# purelemmas:
# 	grep -oP "(^Lemma [1-9][1-9]?[[:space:]]?\..*)(?=Proof\.)" output/html/*.html | sed G > lemmas.txt

lemmas:
	grep -oP "^Lemma [1-9][1-9]?[[:space:]]?\..*" output/html/*.html | sed G > output/extraction/lemmas.txt

# puretheorems:
# 	grep -oP "(>Theorem [1-9][1-9]?[[:space:]]?\..*)(?=Proof\.)" output/full_text/*.xml | sed G > theorems.txt

theorems:
	grep -oP "^Theorem [1-9][1-9]?[[:space:]]?\..*" output/html/*.html | sed G > output/extraction/theorems.txt


# purelemmas:
# 	grep -oP "(>Lemma [1-9][1-9]?[[:space:]]?\..*)(?=Proof\.)" output/full_text/*.xml | sed G > lemmas.txt

# lemmas:
# 	grep -oP ">(Lemma [1-9][1-9]?[[:space:]]?\..*)" output/full_text/*.xml | sed G > lemmas.txt

# puretheorems:
# 	grep -oP "(>Theorem [1-9][1-9]?[[:space:]]?\..*)(?=Proof\.)" output/full_text/*.xml | sed G > theorems.txt

# theorems:
# 	grep -oP ">(Theorem [1-9][1-9]?[[:space:]]?\..*)" output/full_text/*.xml | sed G > theorems.txt
