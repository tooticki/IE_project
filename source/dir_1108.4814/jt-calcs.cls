%% This is a modified version of a class file to produce a document
%% containing calculations.
%% TU Kaiserslautern, Germany. JT - 2012.
%%
%% The class provides the options:
%%	nocolour - set link colour from hyperref to black.
%%	numsubsectitle - number subsections.

\NeedsTeXFormat{LaTeX2e}[1994/01/01]
\ProvidesClass{jt-calcs}[2012/06/13 v1 A Class File for Calculations]

%======================================================
% Initial Stuff for Conditionals & Colours
%======================================================
\RequirePackage{ifthen}
\newboolean{numsubsectitle}

%======================================================
% Options For Class\Packages
%======================================================
\DeclareOption{nocolour}{\PassOptionsToPackage{nocolour,thmswap}{jt-head}}

\PassOptionsToClass{11pt,a4paper}{article}

\ProcessOptions

\LoadClass{article}

%======================================================
% Load Packages
%======================================================
\RequirePackage{jt-head}
\RequirePackage{fancyhdr}
\RequirePackage{setspace}
\RequirePackage{titlesec}
\RequirePackage[dotinlabels]{titletoc}
\RequirePackage{geometry}
\RequirePackage{enumitem}
\RequirePackage{chngcntr}
\RequirePackage{calc}

% Font Packages
\RequirePackage[OT1]{fontenc}
\RequirePackage[sc]{mathpazo}

\geometry{a4paper,includeheadfoot,margin=15mm}

% Allow equations to spread over multiple pages
\allowdisplaybreaks

%======================================================
% Title Page
%======================================================
\newcommand{\Ex@title}{you forgot to set this!}
\newcommand{\Ex@author}{you forgot to set this!}
\newcommand{\Ex@date}{you forgot to set this!}
\newcommand{\exname}{}
\renewcommand{\title}[1]{\renewcommand{\Ex@title}{{#1}}}
\renewcommand{\author}[1]{\renewcommand{\Ex@author}{{#1}}}
\renewcommand{\date}[1]{\renewcommand{\Ex@date}{{#1}}}

\newcommand{\start}%
{
\fancyhf{}
\fancyhead[R]{\thepage}
\thispagestyle{empty}
\setstretch{1.2}

{
\rule{\linewidth}{0.2mm}\\[10pt]
\centering
\begin{minipage}[c]{0.75\textwidth}
\centering\Large {\bf \Ex@title}\\[6pt]
{\it \Ex@author}\\
\end{minipage}\\[10pt]
\rule{0.5\linewidth}{0.2mm}\\}
}

\renewenvironment{abstract}
{
   \bigskip
   \begin{center}
   \begin{minipage}[c]{0.85\textwidth}
   \small{\bf Abstract.}
}{
   \end{minipage}
   \end{center}
   \bigskip\bigskip
}

\newenvironment{acknowledgments}
{
   \bigskip\noindent{\bf Acknowledgments:}
}{

}

%======================================================
% Table of Contents
%======================================================
\newlength{\tocleftlabelindent}
\newlength{\tocmarginindent}
\setlength{\tocleftlabelindent}{10mm}
\setlength{\tocmarginindent}{\parindent+\tocleftlabelindent}

\setcounter{tocdepth}{1}

\titlecontents{section}
[\tocmarginindent]
{}
{\contentslabel{\tocleftlabelindent}}
{}
{\titlerule*[1pc]{.}\contentspage}
[\contentsmargin{40mm}]

%======================================================
% Make Equation Numbering (section.number)
%======================================================
\numberwithin{equation}{section}
\renewcommand{\theequation}{\thesection.\arabic{equation}}

%======================================================
% Number Tables By Section
%======================================================
\counterwithin{table}{section}

%======================================================
% Fancyhdr and Titlesec Information
%======================================================
\setlength{\headheight}{15pt}
\pagestyle{fancy}

\titleformat{\section}[block]{\large\fillast}{\thesection.}{1em}{\bfseries}[\vspace{1mm}]

\ifthenelse{\boolean{numsubsectitle}}
{\titleformat{\subsection}[block]{\normalsize}{\thesubsection}{0.5em}{\bfseries}[\vspace{1mm}]}
{\titleformat{\subsection}[block]{\normalsize}{$\blacktriangleright$}{0.5em}{\bfseries}[\vspace{1mm}]}



%\titlespacing{\chapter}{3.5pc}{0mm}{10mm}[3.5pc]

%======================================================
% Set \emptyset to be \varnothing
%======================================================
\renewcommand{\emptyset}{\varnothing}

%======================================================
% End of Document
%======================================================
\newcommand{\address}[1]{\AtEndDocument{\par\sc{#1}}}
\newcommand{\email}[1]{\AtEndDocument{\par\it{Email:} \tt{#1}}}