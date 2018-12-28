% raedoc.tex for LaTeX2e
% Version 11-Nov-1997.
% Contact Lee Larson (lmlars01@homer.louisville.edu) about bugs.
% The latest version can be obtained from
%     <http://www.louisville.edu/~lmlars01/index.html
% or
%     <ftp://ftp.louisville.edu/pub/math/Larson/rae/>

% Identification
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{rae}[1996/10/19]

% Bring in the regular article class
% Changed from two sided option 11-JULY-96
\LoadClass[twoside]{article}

% Set the page dimensions for the Exchange
% Corrected for faux single-side 19-Oct-96
\setlength{\textheight}{6.75in}
\advance\textheight by \topskip
\setlength{\textwidth}{4.675in}
\setlength{\oddsidemargin}{0pt}
\setlength{\evensidemargin}{0pt}
\setlength{\hoffset}{0.9125in}

% These define the parameters from the issueinfo.tex file, if
% it exists.
\newcommand{\Volume}[1]%
  {\newsavebox{\volumebox}\sbox{\volumebox}{\scriptsize#1}
  \let\Volume\relax}
\newcommand{\IssueNumber}[1]%
  {\newsavebox{\issuebox}\sbox{\issuebox}{\scriptsize#1}
  \let\IssueNumber\relax}
\newcommand{\Year}[1]%
  {\newsavebox{\yearbox}\sbox{\yearbox}{\scriptsize#1}
  \let\Year\relax}

% Stuff to do at the beginning of text insertion.
\AtBeginDocument{%
% Catch first page number for the header information.
\label{firstpage}%
% If issueinfo.tex exists, then we're in production mode. So, we
% get the issue information from the disk and the starting page
% number. The format for issueinfo.tex has three lines
% \Volume{20}
% \IssueNumber{2}
% \Year{1994/5}
% with an optional fourth line to set the first page number to nn
% \firstpagenumber{nn}
  \IfFileExists{issueinfo}{\input{issueinfo}\getfirstpage}{\null}
% Fill in the information at the bottom of the page for key words,
% Math Reviews classification and the date received by the
% editors. If any of the information macros is not there, then
%that one is left out.
  \ifx\nnull\key@words%
  \else
  \insert\footins{\footnotesize
  \fnstrut Key Words: \key@words\fnstrut}
  \fi
  \ifx\nnull\math@reviews%
  \else
  \insert\footins{\footnotesize
  \fnstrut
  Mathematical Reviews subject classification: \math@reviews
  \fnstrut}
  \fi
  \ifx\date@received\nnull
  \else
 	\insert\footins{\footnotesize 
   \fnstrut Received by the editors \date@received\fnstrut}
 \fi
% Blow out macros which are no longer needed.
 \let\getfirstpage\relax
 \let\firstpagenumber\relax
 \let\nnull\relax
}

% Catch the last page number in the aux file for use in the 
% journal header.
\AtEndDocument{\label{lastpage}}

% Here is the information supplied in the header which is not
% part of the normal LaTeX topmatter.
\newcommand{\nnull}{\null} %For use with \ifx.
\newcommand{\fnstrut}{\rule{0pt}{\footnotesep}} % Separate notes
%
\newcommand{\keywords}[1]{\renewcommand{\key@words}{#1}}
\newcommand{\key@words}{\null}
%
\newcommand{\MathReviews}[1]{\renewcommand{\math@reviews}{#1}}
\newcommand{\math@reviews}{\null}
%
\def\received#1{\renewcommand{\date@received}{#1}}
\newcommand{\date@received}{\null}

% Code to patch the myheadings option to small caps instead
% of italic.

\def\ps@myheadings{%
    \let\@oddfoot\@empty\let\@evenfoot\@empty
    \def\@evenhead{\thepage\hfil\scshape\leftmark}%
    \def\@oddhead{{\scshape\rightmark}\hfil\thepage}%
    \let\@mkboth\@gobbletwo
    \let\sectionmark\@gobble
    \let\subsectionmark\@gobble
    }


% Code to patch \maketitle from article.cls.

\renewcommand\maketitle{\par
  \begingroup
    \renewcommand\thefootnote{\fnsymbol{footnote}}%
    \def\@makefnmark{\hbox to\z@{$\m@th^{\@thefnmark}$\hss}}%
    \long\def\@makefntext##1{\parindent 1em\noindent
            \hbox to1.8em{\hss$\m@th^{\@thefnmark}$}##1}%
    \if@twocolumn
      \ifnum \col@number=\@ne
        \@maketitle
      \else
        \twocolumn[\@maketitle]%
      \fi
    \else
      \global\@topnum\z@ % Prevents figures from going at top of page.
      \@maketitle
    \fi
    \thispagestyle{plain}\@thanks
  \endgroup
  \setcounter{footnote}{0}%
  \let\thanks\relax
  \let\maketitle\relax\let\@maketitle\relax
  \gdef\@thanks{}\gdef\@author{}\gdef\@title{}}
\def\@maketitle{%
% First, do the stuff for the production option. Use the existence of
% the issueinfo.tex file as the flag for production rather than
% civilian mode.
  \IfFileExists{issueinfo}{%
    \hfill\parbox{3in}{\scriptsize\raggedleft
      \textbf{Real Analysis Exchange}
        \linebreak
      Vol.~\usebox{\volumebox}(\usebox{\issuebox}), \usebox{\yearbox},
      pp.~\pageref{firstpage}--\pageref{lastpage}}}{\null}
  % Add a bit of space between the coordinate information and the 
  % author information.
  \par\vskip 1em
  % Put in the author information.
  \begingroup
    \def\and{\par\vskip .2em}
    % Use left justification to inhibit breaking names.
    \begin{flushleft}%
     {\@author}\par
    \end{flushleft}
  \endgroup
  \vskip 2em%
  \begin{center}%
    {\Large\textbf{\@title}\par}
  \end{center}%
  \par
  \vskip .5em}

% Make the section titling a bit smaller.
\renewcommand\section{\@startsection {section}{1}{\z@}%
                                   {-3.5ex \@plus -1ex \@minus -.2ex}%
                                   {2.3ex \@plus.2ex}%
                                   {\reset@font\large\bfseries}}
\renewcommand\subsection{\@startsection{subsection}{2}{\z@}%
                                     {-3.25ex\@plus -1ex \@minus -.2ex}%
                                     {1.5ex \@plus .2ex}%
                                     {\reset@font\normalsize\bfseries}}

%
% Procedure to set beginning page number. If the macro
% \firstpagenumber{nn} appears in the topmatter, that will
% set the first page number. Otherwise, it can be called
% interactively from \getfirstpage. This is for the production
% of the papers in the journal.
%
\def\getfirstpage{
\newcount\FirstPage
\typein[\FirstPage]{First page number: }
\ifnum\FirstPage>0
  \firstpagenumber{\FirstPage}
\else\setcounter{page}{1}
\fi}
\def\firstpagenumber#1{\global\setcounter{page}{#1}
 \let\getfirstpage\relax
 \message{First page set to \the\c@page.}}
 
% Always want author on left and title on right.
\pagestyle{myheadings}
