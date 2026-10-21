\version "2.24.0"

\header {
  title = "Modulation from C major to D major"
  subtitle = "Compact piano example"
  composer = "Music theory notes"
  tagline = ##f
}

global = {
  \time 4/4
  \tempo 4 = 72
}

rightHand = \relative c' {
  \clef treble
  \key c \major
  <c e g>2 <b d gis>2 |
  <a c e>2 <a cis eis>2 |
  \key d \major
  <fis a d>1 |
}

leftHand = \relative c {
  \clef bass
  \key c \major
  c2 b2 |
  a2 a2 |
  \key d \major
  d1 |
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
  \new PianoStaff <<
    \new Staff = "right" \with {
      instrumentName = "Piano"
    } << \global \rightHand >>
    \new Staff = "left" << \global \leftHand >>
  >>
  \layout {
    indent = 0
    ragged-right = ##t
    \context {
      \Score
      \override SpacingSpanner.common-shortest-duration = #(ly:make-moment 1/2)
    }
  }
  \midi { }
}
