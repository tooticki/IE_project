import sys
import re
import os, fnmatch
import pandas as pd
from sets import Set

#from generate_training_data import *

# take csv with text

# return a column


# Feature vectors: [words_num, average_word_length, italicness, formulaness, is_heading, is_proof, boldness_first_word, is_capital_first_letter, type]
def words_num (vector): return vector[0]
def average_word_length(vector): return vector[1]
def italicness (vector): return vector[2]
def formulaness (vector): return vector[3]
def is_heading (vector): return vector[4]
def is_proof (vector): return vector[5]
def boldness_first_word (vector): return vector[6]
def is_capital_first_letter (vector): return vector[7]

def vectors_to_tags(vectors):
#takes a list of vectors, returns a list of tags
    tags=[None] * len(vectors)    
    tags[0], tags[-1] = "text", "text"
    for i in range(1,len(vectors)-1):
        if is_heading(vectors[i]):
            tags[i]="heading"
        elif (tags[i-1]=="heading" or tags[i-1]=="body"):
            if (italicness(vectors[i])>.5 or formulaness(vectors[i])>.6) and not is_proof(vectors[i]):
                tags[i]="body"
            else:
                tags[i]="after_body"
        else:
            tags[i]="text"
    return tags


def data_to_tags():
    all_tags = []
    documents = []
    for doc in os.listdir("training_data"):
        if doc.endswith("ing.csv"):
            documents.append(pd.read_csv("training_data/"+doc))
            
    all_vectors_pd = pd.concat(documents)
    all_vectors = all_vectors_pd.values.tolist()
    all_tags = vectors_to_tags(all_vectors)
    all_tags_pd=pd.DataFrame(all_tags, columns=['type'])
    return all_tags_pd

#a = data_to_tags()
# print a[100:200]
