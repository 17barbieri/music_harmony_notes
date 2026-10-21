\version "2.26.0"

\header {
  tagline = ##f
}

\paper {
  paper-width = 180\mm
  paper-height = 30\mm
  top-margin = 3\mm
  bottom-margin = 3\mm
  left-margin = 5\mm
  right-margin = 5\mm
  indent = 0\mm
  ragged-bottom = ##t
  ragged-last-bottom = ##t
  print-page-number = ##f
}

\layout {
  ragged-right = ##f
}

\score {
  \new Staff \relative c' {
    \clef treble
    \key c \major
    \time 8/4
    c4 d e f g a b c
  }
  \layout { }
  \midi { }
}