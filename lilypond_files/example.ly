\version "2.24.0"

\header {
  title = "C major scale"
  subtitle = "Build-script example"
  composer = "Generated with LilyPond"
  tagline = ##f
}


\paper {
  paper-width = 180\mm
  paper-height = 65\mm
  top-margin = 3\mm
  bottom-margin = 3\mm
  left-margin = 5\mm
  right-margin = 5\mm
  indent = 0\mm
  ragged-bottom = ##t
  ragged-last-bottom = ##t
}

\score {
  \new Staff \relative c' {
    \clef treble
    \key c \major
    \time 4/4
    c4 d e f
    g4 a b c
    c1
  }
  \layout { }
  \midi {
    \tempo 4 = 90
  }
}
