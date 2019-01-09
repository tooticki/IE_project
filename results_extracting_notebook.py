#!/usr/bin/env python
# coding: utf-8

# # TOC:
# * ## [Naive Bayes Classification](#naive)
# * ## [Conditional Random Fields 1](#crf1): pycrfsuite
# * ## [Conditional Random Fields 2](#crf2): sklearn_crfsuite
# * ## [Conditional Random Fields 3](#crf3): looking for better c1,c2
# 

# In[2]:


import pandas as pd
import seaborn as sns
import matplotlib
import os

documents = []
for doc in os.listdir("training_data"):
    if doc.endswith("ing.csv"):
        documents.append(pd.read_csv("training_data/"+doc))

all_vectors = pd.concat(documents)
len(documents), len(all_vectors)

#Last (81, 110525) : 81 docs :/
#Current (125, 174927)


# In[3]:


# Place features in X and types in Y

def get_features(vectors):
    return vectors.drop('type', axis=1)

def get_types(vectors):
    return vectors['type']

def pd_to_dict_list(data):
    return data.to_dict('records')
    #return data.values.tolist()

def pd_type_column_to_string_list(data):
     return [ x for x in data ]
    
X_pd = get_features(all_vectors)
y_pd = get_types(all_vectors)

X_doc_list = [ pd_to_dict_list(get_features(doc)) for doc in documents ]
y_doc_list = [ pd_type_column_to_string_list(get_types(doc)) for doc in documents ]

X_doc_list[0][52], y_doc_list[0][52]


# In[3]:


# Plot palette
col_list = ["pink", "lightblue", "lightgreen", "yellow"]
sns.palplot(sns.xkcd_palette(col_list))


# In[ ]:


# Plot
col_list_palette = sns.xkcd_palette(col_list)
sns.set_palette(col_list_palette)
sns.set_context("paper", rc={"axes.labelsize":45})
plot=sns.pairplot(
    data=all_vectors, hue="type",
    plot_kws = {'alpha': 0.3, 'edgecolor': 'k'},
    markers = ["+", "o", "s", "D"],
    height=10)
plot._legend.get_title().set_fontsize(45)
plot


# In[ ]:


# Save plot
plot.savefig("plots/lines_plot_28.png")


# <a id='naive'></a>
# # Naive Bayes Classification
# 

# In[55]:


# Separating data to training and test for all_vectors
from sklearn.model_selection import train_test_split
X_train, X_test, y_train, y_test = train_test_split(X_pd, y_pd, test_size=0.3)

# Trying Naive Bayes Classification on lines
from sklearn.naive_bayes import GaussianNB # 1. choose model class
model = GaussianNB()                       # 2. instantiate model
model.fit(X_train, y_train)                  # 3. fit model to data
y_model = model.predict(X_test)             # 4. predict on new data
y_model_train = model.predict(X_train)
from sklearn.metrics import accuracy_score
from sklearn.metrics import classification_report

#print "Test data"
#print classification_report(y_test, y_model, digits=2)
print "Training data"
print classification_report(y_train, y_model_train, digits=2)


# <a id='crf1'></a>
# # Conditional Random Fields 1

# In[53]:


# Conditional Random Fields 1.1

# Separating data to training and test for documents
X_train, X_test, y_train, y_test = train_test_split(X_doc_list, y_doc_list, test_size=0.3)

import pycrfsuite
trainer = pycrfsuite.Trainer(verbose=True)

#TODO: debug!!!

# Submit training data to the trainer
for xseq, yseq in zip(X_train, y_train):
    trainer.append(xseq, yseq)

# Set the parameters of the model
trainer.set_params({
    # coefficient for L1 penalty
    'c1' : 0.189,
    'c2' : 0.017,

    # maximum number of iterations
    'max_iterations': 100,

    # whether to include transitions that
    # are possible, but not observed
    'feature.possible_transitions': True
})

# Save the model to the file
trainer.train('crf_models/crf.model')


# In[54]:


# Conditional Random Fields 1.2
tagger = pycrfsuite.Tagger()
tagger.open('crf_models/crf.model')
y_pred = [tagger.tag(xseq) for xseq in X_test]

# Create a mapping of labels to indices
labels = {"heading": 0, "body": 1, "after_body": 2, "text": 3}

import numpy as np
from sklearn.metrics import classification_report

# Convert the sequences of tags into a 1-dimensional array
predictions = np.array([labels[tag] for row in y_pred for tag in row])
truths = np.array([labels[tag] for row in y_test for tag in row])

# Print out the classification report
print(classification_report(
    truths, predictions, target_names=["heading", "body", "after_body", "text"]))


# <a id='crf2'></a>
# # Conditional Random Fields 2

# In[51]:


#Conditional Random Fields 2.1
import sklearn_crfsuite
from sklearn_crfsuite import scorers
from sklearn_crfsuite import metrics
from sklearn.metrics import make_scorer
from sklearn.model_selection import RandomizedSearchCV
import scipy.stats

#TODO: debug!!!

# Separating data to training and test
X_train, X_test, y_train, y_test = train_test_split(X_doc_list, y_doc_list, test_size=0.3)

# Set the parameters of the model
crf = sklearn_crfsuite.CRF(
    algorithm='lbfgs',
        
    c1 = 0.189,
    c2 = 0.017,
    
    max_iterations=100,
    
    # whether to include transitions that
    # are possible, but not observed
    all_possible_transitions=True
)

crf.fit(X_train, y_train)
y_pred_train = crf.predict(X_train)
y_pred_test = crf.predict(X_test)

print("Training on the training part")
print(metrics.flat_classification_report(y_train, y_pred_train, digits=2))
# print("Training on the test part")
# print(metrics.flat_classification_report(y_test, y_pred_test, digits=2))


# In[28]:


# Conditional Random Fields 2.2
# Dependencies

from collections import Counter

def print_state_features(state_features):
    for (attr, label), weight in state_features:
        print("%0.6f %-8s %s" % (weight, label, attr))

print("Top positive:")
print_state_features(Counter(crf.state_features_).most_common(30))

print("\nTop negative:")
print_state_features(Counter(crf.state_features_).most_common()[-30:])


# In[30]:


# Conditional Random Fields 2.4
# Transitions

def print_transitions(trans_features):
    for (label_from, label_to), weight in trans_features:
        print("%-6s -> %-7s %0.6f" % (label_from, label_to, weight))

print("Top likely transitions:")
print_transitions(Counter(crf.transition_features_).most_common(20))

print("\nTop unlikely transitions:")
print_transitions(Counter(crf.transition_features_).most_common()[-20:])


# In[29]:


# Conditional Random Fields 2.3
# Dependencies

import matplotlib.pyplot as plt

_x = [s.parameters['c1'] for s in rs.grid_scores_]
_y = [s.parameters['c2'] for s in rs.grid_scores_]
_c = [s.mean_validation_score for s in rs.grid_scores_]

fig = plt.figure()
fig.set_size_inches(12, 12)
ax = plt.gca()
ax.set_yscale('log')
ax.set_xscale('log')
ax.set_xlabel('C1')
ax.set_ylabel('C2')
ax.set_title("Randomized Hyperparameter Search CV Results (min={:0.3}, max={:0.3})".format(
    min(_c), max(_c)
))

ax.scatter(_x, _y, c=_c, s=60, alpha=0.9, edgecolors=[0,0,0])

print("Dark blue => {:0.4}, dark red => {:0.4}".format(min(_c), max(_c)))


# <a id='crf3'></a>
# # Conditional Random Fields 3

# In[46]:


# Conditional Random Fields 3.1
# Adjusting c1, c2 to take care of "heading", "body", and "after_body" rather than "text"

# Takes time, +-4min

params_space = {
    'c1': scipy.stats.expon(scale=0.5),
    'c2': scipy.stats.expon(scale=0.05),
}

labels = ['heading', 'body', 'after_body']

# use the same metric for evaluation
f1_scorer = make_scorer(metrics.flat_f1_score,
                        average='weighted', labels=labels)

# search
rs = RandomizedSearchCV(crf, params_space,
                        cv=3,
                        verbose=1,
                        n_jobs=-1,
                        n_iter=20,
                        scoring=f1_scorer)

rs.fit(X_train, y_train)

#something goes wrong


# In[49]:


# Conditional Random Fields 3.2
# Check up c1, c2 and build a crf

#previous: 0.18, 0.017
#last: {'c1': 0.28900203043076822, 'c2': 0.015259555421089956}
print rs.best_params_

crf=rs.best_estimator_

crf.fit(X_train, y_train)
y_pred_train = crf.predict(X_train)
y_pred_test = crf.predict(X_test)

print(metrics.flat_classification_report(y_train, y_pred_train, digits=2))

#rs.best_score_

