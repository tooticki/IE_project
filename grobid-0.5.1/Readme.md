# GROBID

[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![Build Status](https://travis-ci.org/kermitt2/grobid.svg?branch=master)](https://travis-ci.org/kermitt2/grobid)
[![Coverage Status](https://coveralls.io/repos/kermitt2/grobid/badge.svg)](https://coveralls.io/r/kermitt2/grobid)
[![Documentation Status](https://readthedocs.org/projects/grobid/badge/?version=latest)](https://readthedocs.org/projects/grobid/?badge=latest)
[![Docker Status](https://images.microbadger.com/badges/version/lfoppiano/grobid.svg)](https://hub.docker.com/r/lfoppiano/grobid/ "Latest Docker HUB image")
[![Dependency Status](https://www.versioneye.com/user/projects/5942f4990fb24f005a2a6136/badge.svg)](https://www.versioneye.com/user/projects/5942f4990fb24f005a2a6136)

## GROBID documentation

Visit the [GROBID documentation](http://grobid.readthedocs.org) for more detailed information.

## Purpose

GROBID (or Grobid) means GeneRation Of BIbliographic Data. 

GROBID is a machine learning library for extracting, parsing and re-structuring raw documents such as PDF into structured TEI-encoded documents with a particular focus on technical and scientific publications. First developments started in 2008 as a hobby. In 2011 the tool has been made available in open source. Work on GROBID has been steady as side project since the beginning and is expected to continue until at least 2020 :)

The following functionalities are available:

+ Header extraction and parsing from article in PDF format. The extraction here covers the usual bibliographical information (e.g. title, abstract, authors, affiliations, keywords, etc.).
+ References extraction and parsing from articles in PDF format. References in footnotes are supported, although still work in progress. They are rare in technical and scientific articles, but frequent for publications in the humanities and social sciences. All the usual publication metadata are covered. 
+ Parsing of references in isolation.
+ Extraction of patent and non-patent references in patent publications.
+ Parsing of names (e.g. person title, fornames, middlename, etc.), in particular author names in header, and author names in references (two distinct models).
+ Parsing of affiliation and address blocks. 
+ Parsing of dates (ISO normalized day, month, year).
+ Full text extraction from PDF articles, including a model for the the overall document segmentation and a model for the structuring of the text body. 
+ In a complete PDF processing, GROBID manages 55 final labels used to build relatively fine-grained structures, from traditional publication metadata (title, author first/last/middlenames, affiliation types, detailed address, journal, volume, issue, pages, etc.) to full text structures (section title, paragraph, reference markers, head/foot notes, figure headers, etc.). 

GROBID includes a comprehensive web service API, batch processing, a JAVA API, a relatively generic evaluation framework (precision, recall, etc.) and the semi-automatic generation of training data. 

GROBID can be considered as production ready. Deployments in production includes ResearchGate, HAL Research Archive, the European Patent Office, INIST-CNRS, Mendeley, CERN (Invenio), etc. 

The key aspects of GROBID are the following ones:

+ Written in Java, with JNI call to native CRF libraries. 
+ Speed - on a modern but low profile MacBook Pro: header extraction from 4000 PDF in 10 minutes (or from 3 PDF per second with the RESTful API), parsing of 3000 references in 18 seconds. 
+ Speed and Scalability: [INIST](http://www.inist.fr/lang=en) recently scaled GROBID REST service for extracting bibliographical references of 1 million PDF in 1 day on a Xeon 10 CPU E5-2660 and 10 GB memory (3GB used in average) with 9 threads - so around 11.5 PDF per second. The complete processing of 395,000 PDF (IOP) with full text structuring was performed in 12h46mn with 16 threads, 0.11s per PDF (~1,72s per PDF with single thread).
+ Lazy loading of models and resources. Depending on the selected process, only the required data are loaded in memory. For instance, extracting only metadata header from a PDF requires less than 2 GB memory in a multithreading usage, extracting citations uses around 3GB and extracting all the PDF structure around 4GB.  
+ Robust and fast PDF processing based on Xpdf and dedicated post-processing.
+ Modular and reusable machine learning models. The extractions are based on Linear Chain Conditional Random Fields which is currently the state of the art in bibliographical information extraction and labeling. The specialized CRF models are cascaded to build a complete document structure.  
+ Full encoding in [__TEI__](http://www.tei-c.org/Guidelines/P5), both for the training corpus and the parsed results.
+ Reinforcement of extracted bibliographical data via online call to CrossRef (optional), export in OpenURL, BibTeX, etc. for easier integration into Digital Library environments. 
+ Rich bibliographical processing: fine grained parsing of author names, dates, affiliations, addresses, etc. but also for instance quite reliable automatic attachment of affiliations and emails to authors. 
+ "Automatic Generation" of pre-formatted training data based on new PDF documents, for supporting semi-automatic training data generation. 
+ Support for CJK and Arabic languages based on customized Lucene analyzers provided by WIPO.

The GROBID extraction and parsing algorithms uses the [Wapiti CRF library](http://wapiti.limsi.fr). [CRF++ library](http://crfpp.googlecode.com/svn/trunk/doc/index.html) is not supported since GROBID version 0.4. The C++ libraries are transparently integrated as JNI with dynamic call based on the current OS. 

GROBID should run properly "out of the box" on MacOS X, Linux (32 and 64 bits) and Windows. 

## Demo

For testing purposes, a public GROBID demo server is available at the following address: [http://grobid.science-miner.com](http://grobid.science-miner.com)

The Web services are documented [here](http://grobid.readthedocs.io/en/latest/Grobid-service/).

_Warning_: Some quota and query limitation apply to the demo server! If you are interested in using such online GROBID service for your project without limitation (and with support), please contact us (<patrice.lopez@science-miner.com>).

## Latest version

The latest stable release of GROBID is version ```0.5.0```. As compared to previous version ```0.4.3```, this version brings:

+ Migrate from maven to gradle for faster, more flexible and more stable build, release, etc.
+ Usage of Dropwizard for web services
+ Move the Grobid service manual to [readthedocs](http://grobid.readthedocs.io/en/latest/Grobid-service/)
+ (thanks to @detonator413 and @lfoppiano for this release! future work in versions 0.5.* will focus again on improving PDF parsing and structuring accuracy)

New in previous release ```0.4.3```: 

+ New models: f-score improvement on the PubMed Central sample, bibliographical references +2.5%, header +7%  
+ New training data and features for bibliographical references, in particular for covering HEP domain (INSPIRE), arXiv identifier, DOI and url (thanks @iorala and @michamos !)
+ Support for CrossRef REST API (instead of the slow OpenURL-style API which requires a CrossRef account), in particular for multithreading usage (thanks @Vi-dot)
+ Improve training data generation and documentation (thanks @jfix)
+ Unicode normalisation and more robust body extraction (thanks @aoboturov)
+ fixes, tests, documentation and update of the pdf2xml fork for Windows (thanks @lfoppiano)

New in previous release ```0.4.2```: 

+ f-score improvement for the PubMed Central sample: fulltext +10-14%, header +0.5%, citations +0.5%
+ More robust PDF parsing
+ Identification of equations (with PDF coordinates)
+ End-to-end evaluation with Pub2TEI conversions
+ many fixes and refactoring

New in previous release ```0.4.1```:

+ Support for Windows thanks to the contributions of Christopher Boumenot!
+ Support to Docker.
+ Fixes and refactoring.
+ New web services for PDF annotation and updated web console application.
+ Some improvements on figure/table extraction - but still experimental at this stage (work in progress, as the whole full text model).

New in previous release ```0.4.0```:

+ Improvement of the recognition of citations thanks to refinements of CRF features - +4% in f-score for the PubMed Central sample.
+ Improvement of the full text model, with new features and the introduction of two additional models for figures and tables.
+ More robust synchronization of CRF sequence with PDF areas, resulting in improved bounding box calculations for locating annotations in the PDF documents.
+ Improved general robustness thanks to better token alignments.

## License

GROBID is distributed under [Apache 2.0 license](http://www.apache.org/licenses/LICENSE-2.0). 

Main author and contact: Patrice Lopez (<patrice.lopez@science-miner.com>)

## Sponsors

ej-technologies provided us a free open-source license for its Java Profiler. Click the JProfiler logo below to learn more.

[![JProfiler](doc/img/jprofiler_medium.png)](http://www.ej-technologies.com/products/jprofiler/overview.html)

## References

Please simply refer to the github project:

Grobid (2008-2017) <https://github.com/kermitt2/grobid>

See the [GROBID documentation](http://grobid.readthedocs.org/en/latest/References) for more related resources. 
