
\NeedsTeXFormat{LaTeX2e}[1995/12/01]
\ProvidesClass{amcjoucc}[2014/04/01 AMC class]

\newif\if@final
\newif\if@finalweb
\newif\if@proofs
\newif\if@proofsline
\newif\if@oldstyle
\newif\if@imfm
\@finalfalse
\@finalwebfalse
\@proofsfalse
\@imfmfalse

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\DeclareOption{final}{\@finaltrue}
\DeclareOption{finalweb}{\@finalwebtrue\@finaltrue}
\DeclareOption{proofs}{\@proofstrue\@proofslinetrue\@finalwebtrue\@finaltrue}
\DeclareOption{proofsnoline}{\@proofstrue\@finalwebtrue\@finaltrue}
\DeclareOption{oldstyle}{\@oldstyletrue}
\DeclareOption{imfm}{\@imfmtrue}
\ProcessOptions
\LoadClass[b5paper,twoside,10pt]{article}


\if@proofsline\RequirePackage[displaymath, mathlines]{lineno}\fi
\RequirePackage{amsmath}
\RequirePackage{amsthm}
\RequirePackage{amsfonts}
\RequirePackage{geometry}
\if@final\RequirePackage{graphicx}\RequirePackage{lastpage}\RequirePackage{ccicons}\fi
\if@proofs\RequirePackage{eso-pic}\fi
\if@finalweb
\if@proofs
\RequirePackage[hyperfootnotes=false,colorlinks=true,pagebackref=true]{hyperref}
\else
\RequirePackage[hyperfootnotes=false,colorlinks=true]{hyperref}
\fi
\else
\RequirePackage{url}
\fi

\renewcommand{\normalsize}{\fontsize{10}{12}\selectfont}

\geometry{paperwidth=165mm,paperheight=235mm}
\geometry{textwidth=127mm,textheight=200mm}
\geometry{outer=16mm}
\geometry{top=20mm}
\geometry{headsep=7mm,footskip=7mm}

\numberwithin{equation}{section}

%\setlength{\textwidth}{130mm}
%\setlength{\textheight}{200mm}
%\setlength{\headsep}{0pt}
%\setlength{\headheight}{12pt}
%\setlength{\headsep}{1cm}
%\setlength{\voffset}{-17mm}
%\setlength{\oddsidemargin}{0mm}
%\setlength{\evensidemargin}{-7mm}

%\topmargin      -16.0mm
%\oddsidemargin  -11.0mm
%\evensidemargin -11.0mm
%\textheight     243.5mm
%\textwidth      183.0mm
%\columnsep        4.1mm
%\parindent        1.0em
%\headsep          6.3mm
%\headheight        12pt
%\lineskip           1pt
%\normallineskip     1pt
%\def\baselinestretch{1}

\RequirePackage{times}

\if@imfm
\def\@urladdress{http://amc.imfm.si}
\else
\def\@urladdress{http://amc-journal.eu}
\fi
\newcount\@authorcount
\newcount\@footcount
\@authorcount=0
\if@oldstyle
\@footcount=1
\else
\@footcount=0
\fi
\if@final\else\def\ccby{CC}\fi
\def\@emails{}
\def\@authors{}
\def\@journalname{}
\def\@issn{}
\def\p@pertitle{}
\def\blfootnote{\xdef\@thefnmark{}\@footnotetext} 
\long\def\symbolfootnote[#1]#2{\begingroup%
\def\thefootnote{\fnsymbol{footnote}}\footnote[#1]{#2}\endgroup} 
\def\@journalnumber{x}
\def\@journalyear{xxxx}
\def\@startpage{1}
\def\@endpage{x}
\def\@oddrunninghead{}
\def\@evenrunninghead{}
\def\@onlinedate{*}
\def\@receiveddate{*}
\def\@acceptdate{*}

\newcommand{\journalnumber}[1]{\def\@journalnumber{#1}}
\newcommand{\journalyear}[1]{\def\@journalyear{#1}}
\newcommand{\journalpages}[2]{%
\def\@startpage{#1}
\def\@endpage{#2}
}
\newcommand{\oddrunninghead}[1]{\def\@oddrunninghead{#1}}
\newcommand{\evenrunninghead}[1]{\def\@evenrunninghead{#1}}
\newcommand{\dates}[3]{%
\def\@receivedate{#1}%
\def\@acceptdate{#2}%
\def\@onlinedate{#3}}

\newenvironment{frontmatter}
{\thispagestyle{amctitle}%
\setcounter{page}{\@startpage}%
\if@final
  \begin{minipage}{0.3\linewidth}
  \raggedright
  \if@finalweb\includegraphics[width=0.70\textwidth]{cc-logo.pdf}\else\includegraphics[width=0.70\textwidth]{cc-logo.pdf}\fi
  \end{minipage} \hfill
  \begin{minipage}{0.3\linewidth}
  \centering 
  ~
  \end{minipage} \hfill
  \begin{minipage}{0.3\linewidth}
%  \centering \LARGE $\mathcal{AMC}$ \vskip 4pt \hrule \vskip 4pt 
%  {\small Ars}\\[-14pt]
%  {\small Mathematica}\\[-14pt]
%  {\small Contemporanea}%
  \centering 
  \if@finalweb\includegraphics[width=\textwidth]{AMCc.pdf}\else\includegraphics[width=\textwidth]{AMC.pdf}\fi
  \end{minipage}
\fi
\vskip 10pt
\if@proofsline\global\linenumbers\fi%
}
{\vskip 20pt%
\blfootnote{\raggedright \ifnum\@authorcount=1\textit{E-mail address:}\else\textit{E-mail addresses:}\fi ~\@emails}%
\if@proofsline\global\linenumbers\fi%
}

\newcommand{\footadvance}[1]{%
\global\advance\@footcount by #1
}

\newcommand{\titledata}[2]{%
\global\def\p@pertitle{#1}%
\vskip 5mm
\begin{center}\LARGE\bfseries%
#1\if!#2!\else
\global\advance\@footcount by 1%
\symbolfootnote[\@footcount]{#2}\fi\end{center}%
\vskip 1mm
}

\newcommand{\authordata}[4]{
\advance\@authorcount by 1%
\xdef\@emails{\@emails\ifnum\@authorcount>1 , \fi {#3} (#1)}%
\xdef\@authors{\@authors\ifnum\@authorcount>1 , \fi {#1}}
\begin{center}%
\if!#4!
{\large #1}\\[1mm]
{\itshape #2}
\else
\global\advance\@footcount by 1%
{\large #1} \symbolfootnote[\@footcount]{#4}\\[1mm]
{\itshape #2}%
\fi
\end{center}}

\newcommand{\authordatanoemail}[3]{
\begin{center}%
\if!#3!
{\large #1}\\[1mm]
{\itshape #2}
\else
\global\advance\@footcount by 1%
{\large #1} \symbolfootnote[\@footcount]{#3}\\[1mm]
{\itshape #2}%
\fi
\end{center}}

\newcommand{\authordataff}[5]{
\advance\@authorcount by 1%
\xdef\@emails{\@emails\ifnum\@authorcount>1 , \fi #3 (#1)}%
\xdef\@authors{\@authors\ifnum\@authorcount>1 , \fi {#1}}
\begin{center}%
\global\advance\@footcount by 1%
{\large #1} \symbolfootnote[\@footcount]{#4}
\global\advance\@footcount by 1%
\symbolfootnote[\@footcount]{#5}
\\[1mm]
{\itshape #2}%
\end{center}}

\newcommand{\authordatawithfootnote}[4]{
\advance\@authorcount by 1%
\xdef\@emails{\@emails\ifnum\@authorcount>1 , \fi #3 (#1)}%
\xdef\@authors{\@authors\ifnum\@authorcount>1 , \fi {#1}}
\begin{center}%
{\large #1} $^{#4}$\\[1mm]
{\itshape #2}%
\end{center}}

% (1) name1, (2) mail1, (3) foot1, 
\newcommand{\authordatanoaffil}[3]{
\advance\@authorcount by 1%
\xdef\@emails{\@emails\ifnum\@authorcount>1 , \fi #2 (#1)}%
\xdef\@authors{\@authors\ifnum\@authorcount>1 , \fi {#1}}
\if!#3!
{\large #1}
\else
\global\advance\@footcount by 1%
{\large #1} \symbolfootnote[\@footcount]{#3}%
\fi}

\newcommand{\affiliation}[1]{
{\itshape #1}
}


\newcommand{\keywords}[1]{\def\@keywords{#1}}
\newcommand{\msc}[1]{\def\@msc{#1}}

\renewenvironment{abstract}
{
\if*\@onlinedate\begin{center}\small Received dd mmmm yyyy, accepted dd mmmmm yyyy, published online dd mmmmm yyyy\end{center}\vskip 1mm \else \begin{center}\small Received \@receivedate, accepted \@acceptdate, published online \@onlinedate\end{center}\vskip 1mm \fi
\hrule height 0.25pt
\vskip 5pt
\noindent \textbf{Abstract}
\vskip 5pt
}
{
\vskip 5pt
\noindent \textit{\small Keywords:~\@keywords}

\vskip 3pt
\noindent \textit{\small Math.\ Subj.\ Class.: \@msc}
\vskip 5pt
\hrule height 0.25pt
} 

\renewcommand{\section}{%
\@startsection{section}{1}{0pt}{-\baselineskip}{0.5\baselineskip}{\large\bfseries}%
}

%\newcommand*{\section}{%
%\@startsection
%{section}{1}{0pt}{-1.5ex plus -1ex minus -.2ex}%
%{1ex plus .2ex}{\large\sf}
%}

\renewcommand{\subsection}{%
\@startsection{subsection}{2}{0pt}{-\baselineskip}{0.5\baselineskip}{\bfseries}%
}

\theoremstyle{plain}
\newtheorem{thm}{Theorem}[section]
\newtheorem{theorem}[thm]{Theorem}
\newtheorem{prop}[thm]{Proposition}
\newtheorem{proposition}[thm]{Proposition}
\newtheorem{lem}[thm]{Lemma}
\newtheorem{lemma}[thm]{Lemma}
\newtheorem{cor}[thm]{Corollary}
\newtheorem{corollary}[thm]{Corollary}
\newtheorem{claim}[thm]{Claim}
\newtheorem{axiom}[thm]{Axiom}
\newtheorem{conj}[thm]{Conjecture}
\newtheorem{conjecture}[thm]{Conjecture}
\newtheorem{fact}[thm]{Fact}
\newtheorem{hypo}[thm]{Hypothesis}
\newtheorem{assum}[thm]{Assumption}
\newtheorem{crit}[thm]{Criterion}
\newtheorem{cons}[thm]{Construction}
\theoremstyle{definition}
\newtheorem{defn}[thm]{Definition}
\newtheorem{exmp}[thm]{Example}
\newtheorem{example}[thm]{Example}
\newtheorem{rem}[thm]{Remark}
\newtheorem{remark}[thm]{Remark}
\newtheorem{prob}[thm]{Problem}
\newtheorem{problem}[thm]{Problem}
\newtheorem{prin}[thm]{Principle}
\newtheorem{quest}[thm]{Question}
\newtheorem{alg}[thm]{Algorithm}

\if@proofs
  \newcommand{\ps@amc}{%
    \renewcommand\@oddhead{\hfil \small \textit{\@oddrunninghead} \hfil \textit{\thepage}}
    \renewcommand\@evenhead{\small \textit{\thepage} \hfil \textit{\@evenrunninghead} \hfil}
    \renewcommand\@evenfoot{}
    \renewcommand\@oddfoot{}
  }
  \newcommand{\ps@amctitle}{%
    \renewcommand\@oddhead{}
    \let\@evenhead\@oddhead
    \renewcommand\@evenfoot{}
    \let\@oddfoot\@evenfoot
  }
\else
  \newcommand{\ps@amc}{%
    \renewcommand\@oddhead{\hfil \small \textit{\@oddrunninghead} \hfil \textit{\thepage}}
    \renewcommand\@evenhead{\small \textit{\thepage} \hfil \textit{\@evenrunninghead} \hfil}
    \renewcommand\@evenfoot{}
    \renewcommand\@oddfoot{}
  }
  \newcommand{\ps@amctitle}{%
    \renewcommand\@oddhead{}
    \let\@evenhead\@oddhead
    \renewcommand\@evenfoot{}
    \let\@oddfoot\@evenfoot
  }
\fi

\def\enumerate{%
  \ifnum \@enumdepth >\thr@@\@toodeep\else
    \advance\@enumdepth\@ne
    \edef\@enumctr{enum\romannumeral\the\@enumdepth}%
      \expandafter
      \list
        \csname label\@enumctr\endcsname
        {\usecounter\@enumctr\def\makelabel##1{\hss\llap{##1}}%
          \itemsep=0pt}%
  \fi}
\def\itemize{%
  \ifnum \@itemdepth >\thr@@\@toodeep\else
    \advance\@itemdepth\@ne
    \edef\@itemitem{labelitem\romannumeral\the\@itemdepth}%
    \expandafter
    \list
      \csname\@itemitem\endcsname
      {\def\makelabel##1{\hss\llap{##1}}%
        \itemsep=0pt}%
  \fi}

\renewenvironment{description}
                 {\list{}{\labelwidth\z@ \itemindent-\leftmargin
                          \let\makelabel\descriptionlabel}\itemsep=0pt}
                 {\endlist}


\renewenvironment{thebibliography}[1]
     {\section*{\refname}%
      \list{\@biblabel{\@arabic\c@enumiv}}%
           {\settowidth\labelwidth{\@biblabel{#1}}%
            \leftmargin\labelwidth
            \advance\leftmargin\labelsep
            \@openbib@code
            \usecounter{enumiv}%
            \let\p@enumiv\@empty
            \renewcommand\theenumiv{\@arabic\c@enumiv}
            \itemsep=0.0pt}%
      \sloppy
      \small
      \clubpenalty4000
      \@clubpenalty \clubpenalty
      \widowpenalty4000%
      \sfcode`\.\@m}
     {\def\@noitemerr
       {\@latex@warning{Empty `thebibliography' environment}}%
      \endlist}
\let\@openbib@code\@empty

\if@proofs
\newcommand{\BackgroundPic}{
\put(0,-50){
\parbox[b][\paperheight]{\paperwidth}{%
\vfill
\centering
\includegraphics[width=\paperwidth,height=\paperheight,keepaspectratio]{proofs.pdf}%
\vfill
}}}
\fi

\newcommand{\amcend}
{
%\ifodd\thepage
%\if\blankpage
%\else
%Even number of pages
%\fi
%\contentsline {subsection}{\textbf{Imprimitivity of locally finite, 1-ended, planar graphs}\\ 
%Mark E.\ Watkins, Jozef \v{S}ir\'{a}\v{n}}{217}
\if@final
\newwrite\contentsfile
\immediate\openout\contentsfile=contentsfile.txt
\makeatletter
\immediate\write\contentsfile{\@backslashchar contentsline\@charlb subsection\@charrb
\@charlb\@backslashchar textbf\@charlb\p@pertitle\@charrb\@backslashchar\@backslashchar}
\immediate\write\contentsfile{\@authors\@charrb\@charlb\@startpage\@charrb}
\makeatother
\closeout\contentsfile
%\fi
}



\pagestyle{amc}

\if@proofs\AddToShipoutPicture{\BackgroundPic}\fi

\newcommand{\blankpage}{\newpage\thispagestyle{empty}~}

%%
%% End of file `amcjou.cls'.
