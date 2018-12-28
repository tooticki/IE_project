%%% ====================================================================
%%% @LaTeX-file{
%%%    filename  = "jT.cls",
%%%    version   = "1.2f",
%%%    date      = "2001/03/05",
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{jT}
              [1996/02/02 v1.2f JTNB Author Class]

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{jT}}
\ProcessOptions\relax

\LoadClass{amsart}[1996/10/24]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Modif%%%%%%%%%%%%




\renewcommand\normalsize{\@xsetfontsize\normalsize 7%
    \@adjustvertspacing \let\@listi\@listI}



\def\ps@firstpage{\ps@plain
  \def\@oddfoot{\normalfont\scriptsize \hfil\hfil
     \global\topskip\normaltopskip}%
  \let\@evenfoot\@oddfoot
  \def\@oddhead{\@serieslogo\hss}%
  \let\@evenhead\@oddhead % in case an article starts on a left-hand page
}


\renewcommand{\andify}{%
   \nxandlist{\unskip, }{\unskip{} {\normalfont et~}}{\unskip{} {\normalfont et~}}}
 \def\and{\unskip {\normalfont,} \ignorespaces}




\def\maketitle{\par
  \@topnum\z@ % this prevents figures from falling at the top of page 1
  %\@setcopyright
  %\uppercasenonmath\shorttitle
  %\ifx\@empty\shortauthors \let\shortauthors\shorttitle
  %\else \andify\shortauthors \uppercasenonmath\shortauthors \fi
  \@maketitle@hook
  \begingroup
  \@maketitle
  \toks@\@xp{\small \shortauthors}\@temptokena\@xp{{\small\it\shorttitle}}%
  \edef\@tempa{\@nx\markboth{\the\toks@}{\the\@temptokena}}\@tempa
  \endgroup
  \thispagestyle{firstpage}% this sets first page specifications
  \c@footnote\z@
  \def\do##1{\let##1\relax}%
  \do\maketitle \do\@maketitle \do\title \do\@xtitle \do\@title
  \do\author \do\@xauthor \do\address \do\@xaddress
  \do\email \do\@xemail \do\curraddr \do\@xcurraddr
  \do\commby \do\@commby
  \do\dedicatory \do\@dedicatory \do\thanks \do\thankses
  \do\keywords \do\@keywords \do\subjclass \do\@subjclass
}
\def\@maketitle@hook{\global\let\@maketitle@hook\@empty}
\def\@maketitle{%
  \normalfont\normalsize
  \let\@makefnmark\relax  \let\@thefnmark\relax
  \ifx\@empty\@date\else \@footnotetext{\@setdate}\fi
  \ifx\@empty\@subjclass\else \@footnotetext{\@setsubjclass}\fi
  \ifx\@empty\@keywords\else \@footnotetext{\@setkeywords}\fi
  \ifx\@empty\thankses\else \@footnotetext{%
    \def\par{\let\par\@par}\@setthanks}\fi
  \@mkboth{\@nx\shortauthors}{\@nx\shorttitle}%
  \global\topskip42\p@\relax % 5.5pc   "   "   "     "     "
  \@settitle
  \ifx\@empty\authors \else \@setauthors \fi
  \ifx\@empty\@dedicatory
  \else
    \baselineskip18\p@
    \vtop{\centering{\footnotesize\itshape\@dedicatory\@@par}%
      \global\dimen@i\prevdepth}\prevdepth\dimen@i
  \fi
  \@setabstract
  \normalsize
  \if@titlepage
    \newpage
  \else
    \dimen@21\p@ \advance\dimen@-\baselineskip
    \vskip\dimen@\relax
  \fi
} % end \@maketitle

\def\@secnumfont{\bfseries}
\def\section{\@startsection{section}{1}%
    \z@{.7\linespacing\@plus\linespacing}{.5\linespacing}%
   {\normalfont\bfseries\centering}}


\AtBeginDocument{%
  \@ifundefined{publname}{%
    \let\publname\@empty
    \let\@serieslogo\@empty
  }{%
    \def\@serieslogo{%
      \vbox to\headheight{%
        \parindent\z@ \fontsize{11}{11\p@}\selectfont
	\vspace*{-5mm}
        \noindent\publname\  
        \currentvolume\ (\currentyear), \start@page--\end@page \@dateposted\endgraf
        \vss
      }%
    }%
  }%
}


\AtBeginDocument{%
    \@ifundefined{volinfo}{%
      \def\volinfo{%
     \currentvolume\ 
       (\currentyear)}%
    }{}%
}

\def\issueinfo#1#2{\def\currentvolume{#1}\def\currentyear{#2}}
\issueinfo{00}% volume number
  %{0}%        % issue number
  %{Xxxx}%     % month
  {XXXX}%     % year

\def\@settitle{\begin{center}%
  \baselineskip16\p@\relax
    \normalfont\bfseries
  \bfseries\fontsize{14}{20\p@}\bfseries
  \@title
  \end{center}%
}


\def\@setauthors{%
  \begingroup
  \trivlist
  \centering\footnotesize \@topsep30\p@\relax
  \advance\@topsep by -\baselineskip
  \item\relax
  \andify\authors\centering{\normalsize {par}}
  %\uppercasenonmath\authors
  \sc\fontsize{11}{14\p@}\sc \authors
  \endtrivlist
  \endgroup
}

\def\publname{\normalsize{\sl Journal de Th\'eorie des Nombres \newline de Bordeaux\,}}

%\def\ISSN{0025-5718}

%\copyrightinfo{1997}%            % copyright year
%  {American Mathematical Society}% copyright holder

\renewcommand{\datename}{Manuscrit re\c cu le}
\headheight=8pt 
\textheight=19.5cm
\textwidth=12.5cm
\setlength{\topmargin}{-0.9cm}
\setlength{\oddsidemargin}{-0.1cm}
\setlength{\evensidemargin}{-0.1cm}

\newcommand\normsix{\@xsetfontsize\normsix 6\@adjustvertspacing}

\newenvironment{resume}{\indent\normsix
     \list{}{\labelwidth\z@
    \leftmargin2.95pc \rightmargin\leftmargin
     \listparindent\normalparindent \itemindent\z@
      \parsep\z@ \@plus\p@
     \let\fullwidthdisplay\relax
    }
	\item[\hskip\labelsep\scshape\resumename.]%
}
 
\newenvironment{abstr}{\indent
    \normsix
     \list{}{\labelwidth\z@
    \leftmargin2.95pc \rightmargin\leftmargin
     \listparindent\normalparindent \itemindent\z@
      \parsep\z@ \@plus\p@
     \let\fullwidthdisplay\relax
         }
 \item[\hskip\labelsep\scshape\abstrname.]%
}
 
\def\abstrname{Abstract}
\def\resumename{R\'esum\'e}


\def\@setaddresses{\par
  \nobreak \begingroup
\footnotesize
  \def\address##1##2{\begingroup
    \par\addvspace\bigskipamount\noindent
    \@ifnotempty{##1}{(\ignorespaces##1\unskip) }%
    {\rm\ignorespaces##2}\par\endgroup}%
  \def\email##1##2{\begingroup
    \@ifnotempty{##2}{\nobreak\noindent{\itshape E-mail }%
      \@ifnotempty{##1}{, \ignorespaces##1\unskip}\/:\space
      \ttfamily##2\par\endgroup}}%
  \def\urladdr##1##2{\begingroup
    \@ifnotempty{##2}{\nobreak\noindent{\itshape URL}%
      \@ifnotempty{##1}{, \ignorespaces##1\unskip}\/:\space
      \ttfamily##2\par\endgroup}}%
  \addresses
  \endgroup
}

\endinput






