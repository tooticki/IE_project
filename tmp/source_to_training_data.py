import sys
import re

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
# word = ("font", "word"); font is the font of the first letter!
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
            font = ""
            # match is always (font_match, letter_match)
            for match in re.findall(font_re, stream_line):
                if(font == "" and len(match[0])>0):
                    font = match[0]
                if(len(match[1])>0):
                    if(match[1]==" "):
                        words.append((font, word))
                        word = ""
                        font = ""
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

italic_re = re.compile(r".*(MI|TI)[0-9]+")
bold_re = re.compile(r".*(CMBX)[0-9]+")

def is_this_font(font, font_re):
    """ Return true if the given font matches font_re
        'italic' is a regex deciding it """
    if font_re.search(font):
        return True
    return False

def is_italic(word):
    """ Return true if the given word=(font,letters) is italic  """
    return is_this_font(word[0], italic_re)

def is_bold(word):
    """ Return true if the given word=(font,letters) is bold  """
    return is_this_font(word[0], bold_re)

#TODO: make is_math work!!!
def is_math(word):
    """ Return true if the given word=(font,letters) is bold  """
    return False


# ########################################
# Line analisys

def words_num(line):
    return len(line)

def average_word_length(line):
    return sum(len(word[1]) for word in line)*1. / words_num(line)

def formuleness(line):
    return sum(is_math(word) for word in line)*1. / words_num(line)
    
def italicness(line):
    return sum(is_italic(word) for word in line)*1. / words_num(line)

def line_to_vector(line):
    return [words_num(line), average_word_length(line), italicness(line)]


def is_word_in_line(word, line):
    return any(string == word[1] for (_, string) in line)

def lines_similarity(k,l):
    matches_num = sum(is_word_in_line(w, k) for w in l)
    return 1.*matches_num/max(len(k),len(l))

equality_limit = 0.7
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
# Main

# print vectors: [words_num, average_word_length, italicness, is_theorem]
# in stdout

if len(sys.argv)!=3:
    print "Usage: python source_to_training_data.py paper.pdf results.pdf"
else:
    fulltext_lines = []
    results_lines = []
    extract_text(fulltext_lines, sys.argv[1])
    extract_text(results_lines, sys.argv[2])

    #print_extracted_text(results_lines)
    
    fi, ri, old_fi = 0, 1, 0
    fn, rn = len(fulltext_lines), len(results_lines)
    training_vectors = [None] * fn    

    while fi < fn:
        #print line_to_string(fulltext_lines[fi])[:20] + " ??? " + line_to_string(results_lines[ri])[:20]
        if ri < rn:
            if equal_lines(fulltext_lines[fi], results_lines[ri]) :
                # if got some noise
                if ri+1 < rn and fi+1 < fn and (not stars_line(results_lines[ri+1])) and (not similar_lines(fulltext_lines[fi+1], results_lines[ri+1])):
                    ri+=1
                    fi = old_fi
                else:                
                    while fi < fn and ri < rn  and not stars_line(results_lines[ri]): #and equal_lines(fulltext_lines[fi], results_lines[ri]):
                        training_vectors[fi] = line_to_vector(fulltext_lines[fi]) + ["result"]
                        ri+=1
                        fi+=1
                    ri+=1
                    old_fi = fi
            else:
                training_vectors[fi] = line_to_vector(fulltext_lines[fi]) + ["text"]
                fi+=1
        else:
            training_vectors[fi] = line_to_vector(fulltext_lines[fi]) + ["text"]
            fi+=1

    for x in training_vectors:
            print x
            
#    print "Stopped at full: "+str(fi)+" out of "+str(fn)
#    print "Stopped at resuslt: "+str(ri)+" out of "+str(rn)
