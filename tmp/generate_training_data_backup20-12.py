import sys
import re
import os, fnmatch
import pandas as pd
from sets import Set

#Usage: python source_to_training_data.py paper.pdf results.pdf

font_re = r"font=\"([^\"]*)\"|>(.)</text>"  
newline = re.compile("</textline>")

#number_complex = "([0-9A_Z](\.)?)+([[:space:]](\(.*\)))?(\.)?[[:space:]]"
#number extention is of form (A_Z0-9etc)
#TODO: add theorem_name: (bla bla bla bla)

result_name = "Theorem"
number = "([0-9A-Z](\.)?)+"
number_extention = "\([a-zA-Z0-9]*\)"

result_and_number_re = re.compile(result_name+number)
result_re = re.compile(result_name)
number_re = re.compile(number)
number_extention_re = re.compile(number_extention)

# lines = list of lines
# line = list of words
# word = (font_names, "word"); font is a list of font_names: fonts for each letter
# letter = letter

#TODO: begin theorem as bold

# ########################################            
# Extraction xml-lines to lines

def extract_text(lines, input_file):
    """ Given a file.txt consisting of textlines extracted from an xml
        (by running xgrep -t -x "//textline" ./xml_file.xml > file.txt)
        extracts all lines in in form given above, keeping fonts for words.
    """
    with open(input_file, "r") as instream:
        for stream_line in instream:
            words = []
            word = ""
            font_names = []
            # match is always (font_match, letter_match)
            for match in re.findall(font_re, stream_line):
                if(len(match[0])>0):
                    font_names.append(match[0])
                if(len(match[1])>0):
                    if(match[1]==" "):
                        words.append((font_names, word))
                        word = ""
                        font_names = []
                    else:
                        word=word+match[1]
            lines.append(words)          
            
# ########################################            
# Output

def print_extracted_text(lines):
    """ Prints extracted text  """
    print lines_to_text(lines)

# ########################################
# Data-to-text transformations

def line_to_string(line):
    string = ""
    for font, word in line:
        string = string + " " + word
    string = string + "\n"
    return string
        
def lines_to_text(lines):
    text = ""
    for line in lines:
        text = text + line_to_string(line)
    return text

def heading_to_string(heading):
    string = heading[0]+" " + ".".join(map(str, heading[1]))
    return string

def results_to_text(results):
    text = ""
    for heading, body in results:
        text = text + heading_to_string(heading) + "\n" + body + "\n\n"
    return text


# ########################################            
# Word analisys

#TODO: exclude MathItal from italic? 
italic_re = re.compile(r"((TI)[0-9]+|Ital|rsfs|EUSM)")
bold_re = re.compile(r"(CMBX|Bold|NimbusRomNo9L-Medi)")
#TODO: check which fonts are really math
math_re = re.compile(r"(\+(CM)(SY|MI|EX)[0-9]+|math|Math|MSAM|MSBM|LASY|cmex|StandardSymL)")
normal_re = re.compile(r"(Times-Roman|CMR|CMTT|EUFM|NimbusRomNo9L-Regu|LMRoman[0-9]+-Regular)")

#TODO: add other headings remark
heading_re = re.compile(r"(Theorem|Lemma|Claim|Corollary|Proposition|Fact)")

def is_this_font(font, font_re):
    """ Return true if the given font matches font_re
        'italic' is a regex deciding it """
    if font_re.search(font):
        return True
    return False

def word_italicness(word):
    """ Return the proportion of italic letters in the word  """
    return (0 if len(word[1])==0 else sum(is_this_font(letter_font, italic_re) for letter_font in word[0])*1. / len(word[1]))

def word_boldness(word):
    """ Return the proportion of bold letters in the word  """
    return  (0 if len(word[1])==0 else sum(is_this_font(letter_font, bold_re) for letter_font in word[0])*1. / len(word[1]))

def word_mathness(word):
    """ Return the proportion of math letters in the word  """
    return  (0 if len(word[1])==0 else sum(is_this_font(letter_font, math_re) for letter_font in word[0])*1. / len(word[1]))

def is_heading(word):
    """ Return true if the word word is a heading: Theorem, Lemma etc
        Ignore font! """
    if heading_re.search(word[1]):
        return True
    return False

# ########################################
# Line analisys

def words_num(line):
    return len(line)

def average_word_length(line):
    return sum(len(word[1]) for word in line)*1. / words_num(line)

#TODO: add "first line": bold "Theorem"

def formuleness(line):
    return sum(word_mathness(word) for word in line)*1. / words_num(line)
    
def italicness(line):
    return sum(word_italicness(word) for word in line)*1. / words_num(line)

def first_word(line):
    if len(line)>0:
        return line[0][1]
    else:
        return ""

def second_word(line):
    if len(line)>1:
        return line[1][1]
    else:
        return ""

def is_heading_first_word(line):
    return is_heading(line[0])

#TODO: change to boldness, letters num
def first_word_boldness(line):
    return word_boldness(line[0])

def is_capital_first_letter(line):
    # returns True iff the first letter of the line is capital
    # i.e. returns False if the line is empty or
    # the first character is not a capital letter
    if len(first_word(line))>0:
        letter = (first_word(line))[0]
        return ('A'<= letter and letter <= 'Z')
    else:
        return False

def line_to_vector(line):
    return [words_num(line), average_word_length(line), italicness(line), formuleness(line), is_heading_first_word(line), first_word_boldness(line), is_capital_first_letter(line)]

def is_word_in_line(word, line):
    return any(string == word[1] for (_, string) in line)

def lines_similarity(k,l):
    matches_num = sum(is_word_in_line(w, k) for w in l)
    return 1.*matches_num/max(len(k),len(l))

equality_limit = 0.9
similarity_limit = 0.3

#TODO :test
def equal_lines(k, l):
    return lines_similarity(k,l)>equality_limit

def similar_lines(k, l):
    return lines_similarity(k,l)>similarity_limit


def stars_line(line):
    result = False
    for word in line:
        if word[1]=="***":
            result = True
    return result

# ########################################
# Font analisys

def fonts_list(input_file):
    fonts = []
    with open(input_file, "r") as instream:
        for stream_line in instream:
            font_names = []
            # match is always (font_match, letter_match)
            for match in re.findall(font_re, stream_line):
                if(len(match[0])>0):
                    # Remove font size in the end
                    s = re.sub(r'\d+$', '', match[0])
                    # Remove characters before + if any
                    if '+' in s:
                        i = s.index('+')
                        s = s[i+1:]
                    fonts.append(s)
    return fonts
                    
# ########################################
# Main

# print vectors: [words_num, average_word_length, italicness, formulaeness, is_heading, boldness_first_word, is_capital_first_letter, type]
# where type is [text, heading, body, after_body]
# in stdout

# for testing!
bad_papers = 0   # papers where matching with results didn't suceed
good_papers = 0  # did suceed


# if still doesn't work: just search all occurences of each line of results...
def data_from_xmls(fulltext_xml, results_xml):
    fulltext_lines = []
    results_lines = []
    extract_text(fulltext_lines, fulltext_xml)
    extract_text(results_lines, results_xml)

    # print lines_to_text(results_lines)

    # print lines_to_text(fulltext_lines)
    
    fi, ri, old_fi = 0, 1, 0
    fn, rn = len(fulltext_lines), len(results_lines)
    training_vectors = [[None] * 8] * fn

    def add_training_vector(type):
        # we shouldn't give a line the type text if it was marked as after_body
        if type != "text" or training_vectors[fi][0]==None:
            training_vectors[fi] = line_to_vector(fulltext_lines[fi]) + [type]


    while fi < fn:
        # print line_to_string(fulltext_lines[fi])[:20] + " ??? " + line_to_string(results_lines[ri])[:20]
        # print line_to_string(fulltext_lines[fi])[:50] + "  |  " + line_to_string(results_lines[ri])[:50]

        # heading matching
        if ri < rn and equal_lines(fulltext_lines[fi], results_lines[ri]) :
            


    global bad_papers
    global good_papers
    
    # print str(1.*ri/max(1,rn))+" of results were found"
    if 1.*ri/max(1,rn) < .95:
        bad_papers+=1
        return (training_vectors, False) # (list, is_good)
    else:
        good_papers+=1
        return (training_vectors, True)
#TODO: test better



def generate_csv_documents():
    columns_names = ["words_num", "awerage_word_length", "italicness", "formuleness", "heading_first_word", "boldness_first_word", "is_capital_first_letter", "type"]

    failed_papers = []
    
    # font analysis
    # fonts = []
    
    for file in os.listdir("source_extraction/results_pdf_xml"):
        # if file.endswith("_xml.xml"):
        if file.endswith("1005.3030_xml.xml"):
            training_vectors=[]
            
            #print "Treating "+file
            
            fulltext_xml = os.path.join("source_extraction/results_pdf_xml", file)
            results_xml = fulltext_xml[:-7]+"res"+fulltext_xml[-7:]


            if os.path.exists(results_xml):
                (training_vectors, is_good) = data_from_xmls(fulltext_xml, results_xml)

                # font analysis
                # fonts+=(fonts_list(fulltext_xml))

                if len(training_vectors)>0 and is_good:
                    # Write vectors to file 
                    df = pd.DataFrame(training_vectors, columns=columns_names)
                    df.to_csv('training_data/'+file[:-7]+'training.csv', index=False)
                else:
                    failed_papers.append(file)
                

    # font analysis
    # counts = dict()
    # for i in fonts:
    #     counts[i] = counts.get(i, 0) + 1
    # import operator
    # sorted_counts = sorted(counts.items(), key=operator.itemgetter(1))
    # sorted_counts.reverse()
    # for c in sorted_counts:
    #     print str(c[0])+(" "*(25-len(c[0])))+str(c[1])

    # failed papers
    for f in failed_papers:
        print f

    # for testing:
    print str(bad_papers)+" of papers did not succeed in matching"
    print str(good_papers)+" of papers succeeded in matching"


    
    
generate_csv_documents()

