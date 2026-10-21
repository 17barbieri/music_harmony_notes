# Music theory notes build example

## Source layout

- `music_theory.tex`: root-level notes document; the build script does not create or overwrite it.
- `lilypond_files/example.ly`: C major scale example.
- `lilypond_files/modulation.ly`: compact piano grand-staff example modulating from C major to D major.
- `build.ps1`: Windows PowerShell build script.

## Build

Run from PowerShell in this folder:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\build.ps1
```

The script creates:

- `score_pdfs/`: one PDF per `.ly` source.
- `audio/`: one `.mid` and one `.wav` per `.ly` source.
- `latex_build/`: LaTeX auxiliary files only.
- `music_theory.pdf`: combined notes PDF in the project root.

Use `-Force` to regenerate outputs:

```powershell
.\build.ps1 -Force
```

If a tool is not found automatically, pass its full path:

```powershell
.\build.ps1 `
  -LilyPondPath 'C:\Users\Admin\Applications\lilypond-2.26.0\bin\lilypond.exe' `
  -PdfLatexPath 'C:\Users\Admin\AppData\Local\Programs\MiKTeX\miktex\bin\x64\pdflatex.exe' `
  -FluidSynthPath 'C:\Users\Admin\Applications\FluidSynth\bin\fluidsynth.exe' `
  -SoundFontPath 'C:\Program Files\MuseScore 4\sound\MS Basic.sf3'
```

The build script stages LilyPond output temporarily and moves only the score PDF and MIDI into their final output folders. This avoids retaining duplicate `.pdf`/`.midi` build products under `latex_build/lilypond`.


## Compact score layout

The LilyPond files use a custom 180 mm × 65 mm page with small margins, so the
exported PDFs contain much less empty page area. The LaTeX document then places
each score in a centered block with a maximum width and height while preserving
its aspect ratio. If a score is still too large or too small, adjust the
`width` and `height` values in `music_theory.tex`.
