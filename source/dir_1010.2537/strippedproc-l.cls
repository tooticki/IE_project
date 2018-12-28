\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{strippedproc-l}
              [2007/06/18 v2.01 PROC Author Class]

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{amsart}}
\ProcessOptions

\LoadClass{amsart}[1996/10/24]

\def\ISSN{0002-9939}

\copyrightinfo{\currentyear}%    % copyright year
  {American Mathematical Society}% copyright holder

% set "communicated by" line
\def\@maketitle{%
  \normalfont\normalsize
  \let\@makefnmark\relax  \let\@thefnmark\relax
  \ifx\@empty\@date\else \@footnotetext{\@setdate}\fi
  \ifx\@empty\@subjclass\else \@footnotetext{\@setsubjclass}\fi
  \ifx\@empty\@keywords\else \@footnotetext{\@setkeywords}\fi
  \ifx\@empty\thankses\else \@footnotetext{%
    \def\par{\let\par\@par}\@setthanks}\fi
  \@mkboth{\@nx\shortauthors}{\@nx\shorttitle}%
  \global\topskip42\p@ % 5.5 picas to the base of the first title line
  \@settitle
  \ifx\@empty\authors \else \@setauthors \fi
  \ifx\@empty\@commby
  \else
    \baselineskip18\p@
    \vtop{\centering{\footnotesize\@commby\@@par}%
      \global\dimen@i\prevdepth}\prevdepth\dimen@i
  \fi
  \ifx\@empty\@dedicatory
  \else
    \baselineskip18\p@
    \vtop{\centering{\footnotesize\itshape\@dedicatory\@@par}%
      \global\dimen@i\prevdepth}\prevdepth\dimen@i
  \fi
  \@setabstract
  \normalsize
  \dimen@34\p@ \advance\dimen@-\baselineskip
  \vskip\dimen@\relax
} % end \@maketitle

\endinput
