import sys
import re
import pandas as pd

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
# Extraction

def extract_text(lines, input_file):
    """ Given a argv[1]=file.txt consisting of textlines extracted from an xml
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
            
def print_extracted(lines):
    """ Prints extracted lines in sys.argv[2]  """
    with open(sys.argv[2], "w") as outstream:
        for line in lines:
            for (font, word) in line:
                for letter in word:
                    outstream.write(letter)
                outstream.write("["+font+"]  ")
            outstream.write("\n")

def print_lines_info(lines):
    with open(sys.argv[2], "w") as outstream:
        for line in lines:
            outstream.write("length:"+str(words_num(line))+" avg_word:"+("{0:0.2f}".format(average_word_length(line)))+" italic:"+("{0:0.2f}".format(italicness(line)))+"\n")
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


# ########################################
# Line analisys

def words_num(line):
    return len(line)

def average_word_length(line):
    return sum(len(word[1]) for word in line)*1. / words_num(line)

#TODO: make it depend on number of math font symbols!!!
def formuleness(line):
    return max(.1/max(words_num(line),1), 1./max(average_word_length(line),1))
    
def italicness(line):
    return sum(is_italic(word) for word in line)*1. / words_num(line)

def line_vectors(lines):
    for line in lines:
        yield (words_num(line), average_word_length(line), italicness(line))

def line_vectors_list(lines):
    return list(line_vectors(lines))
        
#TODO rename?
def paired_line_vectors_list(lines):
    line_vectors_list = list(line_vectors(lines))
    if len(line_vectors_list)==0:
        return []
    result =[]
    for i in range (0, len(line_vectors_list)-1):
        result.append(line_vectors_list[i]+line_vectors_list[i+1])
        
    result.append(line_vectors_list[-1]+line_vectors_list[-1])
            
def theoremness(lines, line):
    line_index = lines.index(line)
    return max(italicness(line), formuleness(line))

#TODO: make eningness depending on differences between theoremness
# of lines

# number of math symbols: math font of latex

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
# Lines vectors to DataFame
# (wn[i], awl[i], it[i], wn[i+1], awl[i+1], it[i+1],) -> last body line or not

#TODO: add the next line vector!
def lines_data_frame(lines):
    return pd.DataFrame(line_vectors_list(lines), columns = ['words_number', 'average_word_length', 'italicness'])



# ########################################
# Extracting theorems

#[0-9]<[A-Z]<[a-z]
def ordered (sl, tl):
    for (x,y) in zip(sl, tl):
        if (x<y):
            return True
        elif (y<x):
            return False
    return (False)

def not_in_place (begins, i):
    answer = False
    if i > 0:
        answer = not ordered(begins[i-1][1],begins[i][1])
    if i < len(begins)-1:
        answer = answer or not ordered(begins[i][1],begins[i+1][1])
    return answer

def clever_append (begins, indexes, j, p):
    try:
        i = begins.index(p)
        if ((is_bold(p[0]) and not is_bold(begins[i][0])) or ordered(begins[-1][1], p[1]) or not_in_place(begins, i) ):
            begins.remove(begins[i])
            indexes.remove(indexes[i])
            begins.append(p)
            indexes.append(j)
    except ValueError:
        begins.append(p)
        indexes.append(j)

def match_to_string(match):
    return (match.groups() if match else "")

def search_to_string(search):
    return (search.group(0) if search else "")

def num_to_list(num):
    numl = search_to_string(num).split('.')
    try:
        numl.remove('')
    except ValueError:
        pass
    return numl

#TODO: count only bold theorems if at least one of them is bold
def list_of_begins(lines):
    """" Find all beginning of results, like "Theorem 3.1", and collect
         them in a list "begins" where each element is of form
         (heading, line_index) where heading=('Name', [number])
    """
    begins = [] #(theorem, num :"12.34.51"->[12,34,51] , (TODO!) extent)
    indexes = []
    for (line, line_index) in zip(lines, range(len(lines))):
        if len(line)>0:
            res_num = re.match(result_and_number_re, line[0][1])
            res = re.match(result_re, line[0][1])
            if res_num:
                res = result_re.search(line[0][1])
                num = number_re.search(line[0][1])
                num_list = num_to_list(num)
                clever_append(begins, indexes, line_index, (search_to_string(res), num_list, begins))
            elif res:
                if len(line)>1:
                    num = re.match(number_re, line[1][1])
                    num_list = num_to_list(num)
                    if num:
                        clever_append(begins, indexes, line_index, (search_to_string(res), num_list))
    return zip(begins,indexes)

#TODO: change these constants...
max_theorem_length = 15
theoremness_limit = .45

def find_end(lines, line_index):
    i = line_index+1
    while i<len(lines) and i-line_index < max_theorem_length :
        if theoremness(lines, lines[i]) < theoremness_limit:
            return i
        i+=1
    return i
    
def list_of_results(lines):
    begins = list_of_begins(lines)
    results = []
    for heading, begin_index in begins:
        end_index=find_end(lines, begin_index)
        results.append((heading, lines_to_text(lines[begin_index : end_index+1])))
    return results

#TODO: to remove wrong begins, take also lines into account, number of
#italic words if needed: def remove_wrong_begins(list_of_begins):

# ########################################
# Main

def test_function(input_file):
    lines = []
    extract_text(lines, input_file)
    print list_of_begins(lines)
    results = list_of_results(lines)
    print results_to_text(results)
    lines_df = lines_data_frame(lines)
    print lines_df

print "Hello"
    
#for vector in line_vectors(lines):
#    print str(vector)
