import sys
import re
import os, fnmatch
import pandas as pd
from sets import Set

# Usage: python source_to_training_data.py
#!!! Remove ancient training data first if you want to generate different data

# ########################################            
# Useful regexps

font_re = r"font=\"([^\"]*)\"|>(.)</text>"  
newline = re.compile("</textline>")

result_name = "Theorem"
number = "([0-9A-Z](\.)?)+"
number_extention = "\([a-zA-Z0-9]*\)"

result_and_number_re = re.compile(result_name+number)
result_re = re.compile(result_name)
number_re = re.compile(number)
number_extention_re = re.compile(number_extention)

# ########################################            
# Extraction xml-lines to data-lines

# lines = list of data-lines
# data-line = list of words
# word = (font_names, "word"); font_names is a list of fonts of letters
# letter = letter

def extract_text(lines, input_file):
    """ Given a file consisting of textlines extracted from an xml
        (by running xgrep -t -x "//textline" ./xml_file.xml > file.txt)
        extracts all lines in the form given above, keeping fonts for words.
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
    """Prints a list of results where results is a list of
    (heading, body)"""
    text = ""
    for heading, body in results:
        text = text + heading_to_string(heading) + "\n" + body + "\n\n"
    return text

# ########################################            
# Output

def print_extracted_text(lines):
    """ Prints data-lines as plain text  """
    print lines_to_text(lines)

# ########################################            
# Word analisys

#TODO: exclude MathItal from italic?

italic_re = re.compile(r"((TI)[0-9]+|Ital|rsfs|EUSM)")
bold_re = re.compile(r"(CMBX|Bold|NimbusRomNo9L-Medi)")
math_re = re.compile(r"(\+(CM)(SY|MI|EX)[0-9]+|math|Math|MSAM|MSBM|LASY|cmex|StandardSymL)")
normal_re = re.compile(r"(Times-Roman|CMR|CMTT|EUFM|NimbusRomNo9L-Regu|LMRoman[0-9]+-Regular)")

#TODO: remove definitions, remarks etc from results!

heading_re = re.compile(r"(Theorem|Lemma|Claim|Corollary|Proposition|Fact)")
proof_re = re.compile(r"Proof")

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

def is_proof(word):
    if proof_re.search(word[1]):
        return True
    return False

# ########################################
# Line analisys

def words_num(line):
    return len(line)

def average_word_length(line):
    return sum(len(word[1]) for word in line)*1. / words_num(line)

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

def is_proof_first_word(line):
    return is_proof(line[0])

def first_word_boldness(line):
    return word_boldness(line[0])

def is_capital_first_letter(line):
    """ returns True iff the first letter of the line is capital
        i.e. returns False if the line is empty or
        the first character is not a capital letter"""
    if len(first_word(line))>0:
        letter = (first_word(line))[0]
        return ('A'<= letter and letter <= 'Z')
    else:
        return False

def line_to_vector(line):
    """ Return a vector of features for the line:
        [number of words, average word length,
        italicness, formuleness, is the first word a heading,
        is the first word "Proof", is the first word bold,
        is the first letter capital]
    """
    return [words_num(line), average_word_length(line),
            italicness(line), formuleness(line), is_heading_first_word(line),
            is_proof_first_word(line), first_word_boldness(line),
            is_capital_first_letter(line)]

def is_word_in_line(word, line):
    return any(string == word[1] for (_, string) in line)

def lines_similarity(k,l):
    """ Return the proportion of common words of two lines"""
    matches_num = sum(is_word_in_line(w, k) for w in l)
    return 1.*matches_num/max(len(k),len(l))

# Bounds on lines similarity for considering two lines equal or similar
# TODO: test more and adjust the equality constant
equality_limit = 0.7
similarity_limit = 0.3

def equal_lines(k, l):
    return lines_similarity(k,l)>equality_limit

def similar_lines(k, l):
    return lines_similarity(k,l)>similarity_limit

def stars_line(line):
    """ Return True iff the line consists of 3 stars: *** """
    result = False
    for word in line:
        if word[1]=="***":
            result = True
    return result

def empty_line(line):
    """ "Empty" means no letters no digits """
    letters_digits_re = re.compile(r"[A-Za-z0-9]")
    result = True
    for word in line:
        if letters_digits_re.search(word[1]):
            result = False
    return result

# TODO: Refine constants
def ignored_line(line):
    """ lines which are meaningless and can possibly repeat many times
        in the text """
    return (not stars_line(line)) and (empty_line(line) or (average_word_length(line)*words_num(line) <= 3) )

# ########################################
# Font analisys

def fonts_list(input_file):
    """ Make a list of all fonts appearing in the file: used for testing """
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

# Feature vectors: [words_num, average_word_length, italicness, formulaeness, is_heading, is_proof, boldness_first_word, is_capital_first_letter, type]
# where type is in [text, heading, body, after_body]
columns_names = ["words_num", "awerage_word_length", "italicness", "formuleness", "heading_first_word", "proof_first_word", "boldness_first_word", "is_capital_first_letter", "type"]
features_num = len(columns_names)

# Used for debug:
bad_papers = 0            # papers where matching with results didn't suceed
good_papers = 0           # did suceed
invalid_input_papers = 0  # results input file is invalid


def add_training_vector(fulltext_lines, training_vectors, fi, type):
    """ Allows replacing any type with anything but text """
    line = fulltext_lines[fi]
    if  training_vectors[fi][0] is None  or (training_vectors[fi][features_num-1] != "heading" and type != "text"):
        training_vectors[fi] = line_to_vector(line) + [type]


# DONE: make another function which would remove bodies in the middle of nothing....
def correct_oddities(vectors, fulltext_lines):
    #TODO: more ?
    type=features_num-1
    for fi in range(1, len(vectors)-1):
        tl = vectors[fi-1][type]
        t =  vectors[fi][type]
        tr = vectors[fi+1][type]
        if tl == tr == "body" and t == "text":
            vectors[fi][type] = "body"
        if tl == tr == "text" and (t == "body" or t == "after_body"):
            vectors[fi][type] = "text"
        if tl == "body" and tr == "text":
            vectors[fi][type] = "after_body"   


def fill_empty_vectors(vectors, fulltext_lines):
    """the main procedure leaves some vectors empty (the ignored ones:
        empty lines, digits etc). This function fills them according
        to simple logic
    """
    # TODO: remove errors
    type=features_num-1
    for fi in range(len(vectors)):
        if vectors[fi][type] is None:
            vectors[fi] = line_to_vector(fulltext_lines[fi]) + [None]
        
            if fi>0 and fi<len(vectors)-1:
                tl = vectors[fi-1][type]
                tr = vectors[fi+1][type]
                if tl == tr and tr is not None:
                    vectors[fi][type] = tl
                elif (tl == "text" or tl == "after_body") and tr == "heading":
                    vectors[fi][type] = "text"
                elif tl == "text" and (tr == "body" or tr == "after_body"):
                    vectors[fi][type] = "heading"
                elif tl == "heading" and (tr == "body" or tr == "after_body"):
                    vectors[fi][type] = "body"
                elif (tl == "heading" or tl == "body") and (tr == "text" or tr is None):
                    vectors[fi][type] = "after_body"
                else: vectors[fi][type]="text"
            
            else:
                vectors[fi][features_num-1]="text"

def next_result(ri):
    """ Returns new ri and new restarted_current_line"""
    return (ri + 1, False)

def restart_if_you_can(ri, fi, restarted_current_line):
    """ If can restart, prepare for restart and return True
        else proceed for the next result.
        Returns new ri, fi, restarted_current_line, and if it could restart or not
    """
    if restarted_current_line == False:
        return (ri, 0, True, True)
    else:
        return (ri + 1, fi, False, False)


def data_from_xmls(fulltext_xml, results_xml):
    fulltext_lines = []
    results_lines = []
    extract_text(fulltext_lines, fulltext_xml)
    extract_text(results_lines, results_xml)

    # For debug:
    # print lines_to_text(results_lines)
    # print lines_to_text(fulltext_lines)
    
    fi, heading_fi, ri, heading, fn, rn  = 0, 0, 1, True,  len(fulltext_lines), len(results_lines)
    training_vectors = [[None] * features_num] * fn
    restarted_current_line = False
    stars_exist = False  # True iff we found at least one "***"

    if fn==0 or rn==0:
        global invalid_input_papers
        print ("Full text" if fn == 0 else "Results file")+" is empty!"
        invalid_input_papers += 1
        return ([], False, [])
            
    while ri < rn:
        result_line = results_lines[ri]
        if fi >= fn:
            (ri, fi, restarted_current_line, _) = restart_if_you_can(ri, fi, restarted_current_line)
            fi = 0
            continue
        if stars_line(result_line): # stars line -> the next is heading
            stars_exist = True
            if fi>0:
                add_training_vector(fulltext_lines, training_vectors, fi, "after_body")
                fi += 1
            (ri, restarted_current_line) = next_result(ri)
            heading = True
            continue
        
        if heading: # if the line is heading
            # look for this heading in the text
            while fi < fn and not equal_lines(result_line, fulltext_lines[fi]):
                add_training_vector(fulltext_lines, training_vectors, fi, "text")
                fi += 1
            if fi >= fn:
                (ri, fi, restarted_current_line, restart) = restart_if_you_can(ri, fi, restarted_current_line)
                if not restart:
                    heading = False
                    fi = heading_fi # forget this line, start searching the next line from the last heading
            else:
                if is_proof_first_word(result_line): # if a proof is included in a result, ignore everything until the next result
                    while(ri < rn and not stars_line (results_lines[ri])):
                        (ri, restarted_current_line) = next_result(ri)
                else:
                    heading_fi = fi
                    add_training_vector(fulltext_lines, training_vectors, fi, "heading")
                    fi += 1
                    (ri, restarted_current_line) = next_result(ri)
                heading = False
            continue

        # -3 for the case when lines are exchanged
        fi = max(0,heading_fi-12)
        
        #ignore empty lines
        limit = fn
        if ignored_line(result_line): #don't look for too small lines backwards
            restarted_current_line = True
            limit = min(fn, fi+8)
            #(ri, restarted_current_line) = next_result(ri)
            #continue
        while fi < limit and not equal_lines(result_line, fulltext_lines[fi]):
            fi += 1
        if fi >= limit:
            (ri, fi, restarted_current_line, restart) = restart_if_you_can(ri, fi, restarted_current_line)
            if restart:
                continue
        #    else:
        #        heading_fi = 0
        else:
            if is_proof_first_word(result_line): # if a proof is included in a result, ignore everything until the next result
                while(ri < rn and not stars_line (results_lines[ri])):
                    (ri, restarted_current_line) = next_result(ri)                    
            else:
                add_training_vector(fulltext_lines, training_vectors, fi, "body")
                fi += 1
                (ri, restarted_current_line) = next_result(ri)

    while fi<fn:
        add_training_vector(fulltext_lines, training_vectors, fi, "text")
        fi += 1

    #TODO: remove bugs and then --- remove all this debug code

    fill_empty_vectors(training_vectors, fulltext_lines)
    correct_oddities(training_vectors, fulltext_lines)

    # For debug:
    vectors_with_text = [[None] * (features_num + 1)] * fn
    for i in range(fn):
        vectors_with_text[i] = training_vectors[i]+[line_to_string(fulltext_lines[i])]
    
    global bad_papers
    global good_papers
    global invalid_input_papers
    
    if not stars_exist:
        invalid_input_papers+=1
        print "invalid input results!"
        return (training_vectors, False, [])
    else:
        if ri/max(1,rn)  < .7 :
            bad_papers+=1
            print "!!!!DID NOT SUCEED!!!!"
            return (training_vectors, False, [])
        else:
            good_papers+=1
            return (training_vectors, True, vectors_with_text)


def generate_csv_documents():
    failed_papers = []    
    # Font analysis
    # fonts = []
    
    for file in os.listdir("source_extraction/results_pdf_xml"):
        if file.endswith("_xml.xml"):
            training_vectors=[]            
            print "Treating " + file            
            fulltext_xml = os.path.join("source_extraction/results_pdf_xml", file)
            results_xml = fulltext_xml[:-7]+"res"+fulltext_xml[-7:]
            training_file_prefix = 'training_data/'+file[:-7]
            
            if os.path.exists(results_xml) and not os.path.exists(training_file_prefix+'training.csv'):
                (training_vectors, is_good, vt) = data_from_xmls(fulltext_xml, results_xml)

                # Font analysis
                # fonts+=(fonts_list(fulltext_xml))

                
                if len(training_vectors)>0 and is_good :
                    # Write vectors to file 
                    df = pd.DataFrame(training_vectors, columns=columns_names)
                    df.to_csv(training_file_prefix+'training.csv', index=False)
                    
                    df2 = pd.DataFrame(vt, columns=columns_names+["text"])
                    df2.to_csv(training_file_prefix+'training_plus_text.csv', index=False)
                else:
                    failed_papers.append(file)
            else:
                print "Training file already exists or no results file was found"
                
    # Font analysis:
    # counts = dict()
    # for i in fonts:
    #     counts[i] = counts.get(i, 0) + 1
    # import operator
    # sorted_counts = sorted(counts.items(), key=operator.itemgetter(1))
    # sorted_counts.reverse()
    # for c in sorted_counts:
    #     print str(c[0])+(" "*(25-len(c[0])))+str(c[1])

    # For debug:
    print str(bad_papers)+" of papers did not succeed in matching"
    print str(good_papers)+" of papers succeeded in matching"
    print str(invalid_input_papers)+" of papers got invalid input"
        
    # For debug:
    print "Failed papers: "
    for f in failed_papers:
        print f

        
generate_csv_documents()

