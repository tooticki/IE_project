% raex.cls 1.0.2 18-April-09
% Real Analysis Exchange LaTeX Class
% Lee Larson llarson@louisville.edu

% Identification
\ProvidesClass{raex}[2009/04/18 v1.0.2 Real Analysis Exchange]
\NeedsTeXFormat{LaTeX2e}

% Bring in the regular article class
\LoadClass[twoside]{article}[2005/09/16]
% Required packages (All are in the standard LaTeX distribution.)
\RequirePackage{amsmath}
\RequirePackage{amsthm}
\RequirePackage{amssymb}
\RequirePackage{ifthen}
\RequirePackage{textcase}
\RequirePackage{verbatim}

% Initial code
\newcommand*\@journalsection{\relax}
\newcommand*\fnstrut{\rule{0pt}{\footnotesep}}
\global\renewcommand{\thefootnote}{\fnsymbol{footnote}}
\newboolean{@production} \setboolean{@production}{false}
\newboolean{@symposium} \setboolean{@symposium}{false}
\newif\if@mrp \@mrpfalse
\newif\if@mrs \@mrsfalse

% Handle options
% Set the appropriate section label on the title page.
\DeclareOption{errata}{
	\renewcommand\@journalsection{ERRATA}
	\setboolean{@production}{true}\setboolean{@symposium}{false}}
\DeclareOption{survey}{
	\renewcommand\@journalsection{SURVEY}
	\setboolean{@production}{true}\setboolean{@symposium}{false}}
\DeclareOption{research}{
	\renewcommand{\@journalsection}{RESEARCH}
	\setboolean{@production}{true}\setboolean{@symposium}{false}}
\DeclareOption{inroads}{
	\renewcommand\@journalsection{INROADS}
	\setboolean{@production}{true}\setboolean{@symposium}{false}}
\DeclareOption{queries}{
	\renewcommand\@journalsection{QUERIES}
	\setboolean{@production}{true}\setboolean{@symposium}{false}}
\DeclareOption{symposium}{
	\renewcommand\@journalsection{\null}
	\setboolean{@production}{false}\setboolean{@symposium}{true}}
\DeclareOption{reprint}{
	\renewcommand\@journalsection{REPRINT}
	\setboolean{@production}{false}\setboolean{@symposium}{false}}
\DeclareOption{empty}{
	\renewcommand\@journalsection{\null}
	\setboolean{@production}{false}\setboolean{@symposium}{false}} % default
\ExecuteOptions{errata,survey,research,inroads,queries,symposium,reprint,empty}
\ProcessOptions \relax

% Set the page dimensions
\setlength{\textheight}{6.75in}
\setlength{\textwidth}{4.675in}
\setlength{\oddsidemargin}{0pt}
\setlength{\evensidemargin}{0pt}
\setlength{\hoffset}{0.9125in}

% Make the section and subsection titling a bit smaller.
\renewcommand\section{\@startsection {section}{1}{\z@}%
	{-3.5ex \@plus -1ex \@minus -.2ex}%
	{2.3ex \@plus.2ex}%
	{\normalfont\large\bfseries}%
}
\renewcommand\subsection{\@startsection{subsection}{2}{\z@}%
	{-3.25ex\@plus -1ex \@minus -.2ex}%
	 {1.5ex \@plus .2ex}%
	 {\normalfont\normalsize\bfseries}%
}

% myheadings small caps instead of italic.
\renewcommand\ps@myheadings{
	\let\@oddfoot=\@empty \let\@evenfoot=\@empty
	\def\@evenhead{\thepage\hfil\scshape\leftmark}%
	\def\@oddhead{{\scshape\rightmark}\hfil\thepage}%
	\let\@mkboth=\@gobbletwo
	\let\sectionmark=\@gobble
	\let\subsectionmark=\@gobble
}

% Always want author on left and title on right. These are filled in 
% within the top matter using \markboth{author}{title}.
\pagestyle{myheadings}

% Here is information specific to journal production
% volume
\newcommand*{\Volume}[1]{\renewcommand*{\vol@no}{#1}}
\newcommand*{\vol@no}{??}
% number
\newcommand*{\IssueNumber}[1]{\renewcommand*{\issue@no}{#1}}
\newcommand*{\issue@no}{?}
% year
\newcommand*{\Year}[1]{\renewcommand*{\year@no}{#1}}
\newcommand{\year@no}{????}
% contributing editor
\newcommand{\Editor}[1]{\newcommand*{\contributing@editor}{#1}}
\let\contributing@editor=\relax
% date received
\newcommand*\Received[1]{\newcommand*{\date@received}{#1}}
\let\date@received=\relax
% First page number
\newcommand\@firstpagenumber{1}
\newcommand\FirstPageNumber[1]{
	\setcounter{page}{#1}
	\renewcommand\@firstpagenumber{#1}
	\typeout{First page set to \the\c@page.}
}
% Cover title
\newcommand*\CoverTitle[1]{\renewcommand*{\cover@title}{#1}}
\newcommand*{\cover@title}{}
% Cover author
\newcommand\CoverAuthor[1]{\renewcommand{\cover@author}{#1}}
\newcommand{\cover@author}{\relax}

% maketitle
\renewcommand\maketitle{
	\par
	\begingroup
		\global\@topnum\z@ % Prevents figures from going at top of page.
		\@maketitle
		\thispagestyle{plain}%\@thanks
	\endgroup
	\setcounter{footnote}{0}
	\let\thanks=\relax
	\let\maketitle=\relax
	\let\@maketitle=\relax
	\gdef\@thanks{}
	\gdef\@author{}
	\gdef\@title{}
}% \renewcommand\maketitle

\renewcommand\@maketitle{
	{\noindent\Large \@journalsection}
	\hfill\parbox{3in}{\scriptsize\raggedleft\textbf{Real Analysis Exchange}
	\linebreak
	\ifthenelse{\boolean{@production}}{%
	Vol.~\vol@no(\issue@no),~\year@no, pp.~\pageref{firstpage}--\pageref{lastpage}}{\relax}
	\ifthenelse{\boolean{@symposium}}{%
	Summer Symposium~\year@no, pp.~\pageref{firstpage}--\pageref{lastpage}}{\relax}}
	\par\vskip 1em
	\begin{flushleft}
		\unhbox\author@box
	\end{flushleft}
	\vskip 2em
	\begin{center}
		{\Large\textbf{\MakeTextUppercase{\@title}}\par}
	\end{center}
	\par
	\vskip .5em
}% \renewcommand\@maketitle

% ----------------
% Key Words Environment
\gdef\KeyWordList{\relax}
\newenvironment{KeyWords}
{
\newtoks\scratch
\newtoks\@words
\newtoks\@ewords
\newcommand\keyword[1]{
	\scratch={##1}
	\if\KeyWordList\relax{\global\edef\KeyWordList{\the\scratch}
	}\else{
		\@words=\expandafter{\KeyWordList}
		\global\edef\KeyWordList{\the\@words, \the\scratch}
	}\fi
}
}% \newenvironment{KeyWords} begin
{ }% \newenvironment{KeyWords} end

% -----------------
% Math Reviews Classification Environment
\newenvironment{MathReviews}
{% \newenvironment{MathReviews} begin
\newcommand\@MR{\relax}
\newcommand{\@epo}{<subject rank="primary" scheme="msc2000">}
\newcommand{\@epc}{</subject>}
\newcommand{\@eso}{<subject rank="secondary" scheme="msc2000">}
\newcommand{\@esc}{</subject>}
\gdef\PrimarySubjectList{\relax}
\gdef\SecondarySubjectList{\relax}
\newtoks\scratch
\newtoks\@subjects
\newcommand{\primary}[1]{
	\global\@mrptrue
	\scratch={##1}
	\if\PrimarySubjectList\relax{
		\global\edef\PrimarySubjectList{\the\scratch}
	}\else{
		\@subjects=\expandafter{\PrimarySubjectList}
		\global\edef\PrimarySubjectList{\the\@subjects, \the\scratch}
	}\fi
}
\newcommand{\secondary}[1]{
	\global\@mrstrue
	\scratch={##1}
	\if\SecondarySubjectList\relax{
		\global\edef\SecondarySubjectList{\the\scratch}
	}\else{
		\@subjects=\expandafter{\SecondarySubjectList}
		\global\edef\SecondarySubjectList{\the\@subjects, \the\scratch}
	}\fi
}
}% \newenvironment{MathReviews} begin
{% \newenvironment{MathReviews} end
\gdef\@MR{
	\if\PrimarySubjectList\relax{\relax} %no primary subjects
	\else{
		\null
	}\fi
}
\let\@subj=\relax
}% \newenvironment{MathReviews} end

% -----------------
% Author Environment
\newsavebox{\name@box}
\newsavebox{\author@box}
\newsavebox{\firstname@box}
\newsavebox{\lastname@box}
\newsavebox{\postaladdress@box}
\newsavebox{\emailaddress@box} \newboolean{@email}
\newsavebox{\thanks@box}

\newenvironment{Author}
	{ % \newenvironment{Author} begin
		\def\FirstName##1{\sbox{\firstname@box}{##1}}
		\def\LastName##1{\sbox{\lastname@box}{##1}}
		\def\PostalAddress##1{\sbox{\postaladdress@box}{##1}}
		\def\Thanks##1{\sbox{\thanks@box}{\footnote{##1}}}
		\setboolean{@email}{false}
		\def\Email##1{\setboolean{@email}{true}\sbox{\emailaddress@box}{\texttt{##1}}}
	} % \newenvironment{Author} begin
	{ %at end Author environment
		\global\sbox{\author@box}{%
		\unhbox\author@box
		\unhbox\firstname@box\ \unhbox\lastname@box,% name
		\unhbox\thanks@box\ % thanks
		\unhbox\postaladdress@box.\quad % postal address
		\ifthenelse{\boolean{@email}}{email: \unhbox\emailaddress@box\ }{}% email address
		\smallskip\linebreak
		}
	}
	
% proof environment
\renewenvironment{proof}[1][\proofname]{\par
  \pushQED{\qed}%
  \normalfont \topsep6\p@\@plus6\p@\relax
  \trivlist
  \item[\hskip\labelsep\scshape
    #1\@addpunct{.}]\ignorespaces
}{%
  \popQED\endtrivlist\@endpefalse
}

% Stuff to do at the beginning of text insertion.
\AtBeginDocument{
	\global\renewcommand{\thefootnote}{\arabic{footnote}}
	\label{firstpage}
	\if@mrp{\insert\footins{\footnotesize
		Mathematical Reviews subject classification: Primary:~\PrimarySubjectList
		\if@mrs{;\ Secondary:~\SecondarySubjectList}\fi}}
	\fi
	\newcommand*\@KW{Key words: }
	\if\KeyWordList\relax{\relax
	}\else{
		\insert\footins{\footnotesize\fnstrut\@KW \KeyWordList\fnstrut}}
	\fi
	\ifx\date@received\relax{
		\relax
	}\else{
		\insert\footins{\footnotesize\fnstrut Received by the editors \date@received\fnstrut}
	}\fi
	\ifx\contributing@editor\relax{
		\relax
	}\else{
		\insert\footins{\footnotesize\fnstrut Communicated by: \contributing@editor\fnstrut}
	}\fi
}% \AtBeginDocument

% Stuff to do at the end of text insertion
\AtEndDocument{
\label{lastpage}
}

% The Real Analysis Exchange has standardized on blackboard
% bold symbols for standard spaces. Use these definitions to
% define macros with which you are comfortable.
\newcommand*{\BBSpace}[1]{\ensuremath{\mathbb{#1}}}
\newcommand*{\NaturalNumbers}{\BBSpace{N}} % blackboard bold N
\newcommand*{\Integers}{\BBSpace{Z}} % blackboard bold Z
\newcommand*{\RationalNumbers}{\BBSpace{Q}} % blackboard bold Q
\newcommand*{\RealNumbers}{\BBSpace{R}} % blackboard bold R
\newcommand*{\ComplexNumbers}{\BBSpace{C}} % blackboard bold C

% raex.cls finis



