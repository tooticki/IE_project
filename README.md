# IE_project
Information extraction from scientific papers

## Usage:
* To upload source code and pdf from arXiv, save an arXiv-search page in source/url and run
   ```
   $ ./get_source.sh
   ```
* To generate xml-files from uploaded source code and pdfs, run
   ```
   $ ./extract_source_to_xml_lines.sh 
   ```
* To generate training data, run
   ```
   $ python generate_training_data.py 
   ```
* Code for learning is contained in a jupyter notebook: 
   ```
   $ jupyter notebook results_extracting_notebook.ipynb 
   ```
   (File results_extracting_notebook.py contains the same code)
