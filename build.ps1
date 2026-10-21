[CmdletBinding()]
param(
    [string]$LilyPondPath,
    [string]$FluidSynthPath,
    [string]$PdfLatexPath,
    [string]$SoundFontPath,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
Set-Location -LiteralPath $Root

$TexFile = Join-Path $Root "music_theory.tex"
$LilyPondDir = Join-Path $Root "lilypond_files"
$ScorePdfDir = Join-Path $Root "score_pdfs"
$AudioDir = Join-Path $Root "audio"
$LatexBuildDir = Join-Path $Root "latex_build"
$LilyPondTempDir = Join-Path $LatexBuildDir "lilypond"
$FinalPdf = Join-Path $Root "music_theory.pdf"

function Find-Executable {
    param([string]$ExplicitPath, [string]$CommandName, [string[]]$FallbackPaths)
    if ($ExplicitPath) {
        if (-not (Test-Path -LiteralPath $ExplicitPath -PathType Leaf)) {
            throw "Executable not found at explicit path: $ExplicitPath"
        }
        return (Resolve-Path -LiteralPath $ExplicitPath).Path
    }
    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) { return $cmd.Source }
    foreach ($candidate in $FallbackPaths) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) { return $candidate }
    }
    throw "Could not find '$CommandName'. Add it to PATH or pass its path as a script parameter."
}

function Invoke-CheckedProcess {
    param([string]$FilePath, [string[]]$Arguments, [string]$Description)
    Write-Host "`n$Description" -ForegroundColor Cyan
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Description failed with exit code $LASTEXITCODE." }
}

if (-not (Test-Path -LiteralPath $TexFile -PathType Leaf)) {
    throw "Required notes file not found: $TexFile. The script intentionally does not generate it."
}
if (-not (Test-Path -LiteralPath $LilyPondDir -PathType Container)) {
    throw "Required input folder not found: $LilyPondDir"
}

New-Item -ItemType Directory -Force -Path $ScorePdfDir, $AudioDir, $LatexBuildDir, $LilyPondTempDir | Out-Null

$LilyPondPath = Find-Executable -ExplicitPath $LilyPondPath -CommandName "lilypond" -FallbackPaths @(
    (Join-Path $env:USERPROFILE "Applications\lilypond-2.26.0\bin\lilypond.exe"),
    "C:\Program Files\LilyPond\usr\bin\lilypond.exe"
)
$PdfLatexPath = Find-Executable -ExplicitPath $PdfLatexPath -CommandName "pdflatex" -FallbackPaths @(
    (Join-Path $env:LOCALAPPDATA "Programs\MiKTeX\miktex\bin\x64\pdflatex.exe")
)
$FluidSynthPath = Find-Executable -ExplicitPath $FluidSynthPath -CommandName "fluidsynth" -FallbackPaths @(
    (Join-Path $env:USERPROFILE "Applications\FluidSynth\bin\fluidsynth.exe")
)

if (-not $SoundFontPath) {
    foreach ($candidate in @(
        "C:\Program Files\MuseScore 4\sound\MS Basic.sf3",
        "C:\Program Files\MuseScore 4\Resources\SoundFonts\MuseScore_General.sf3"
    )) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $SoundFontPath = $candidate; break }
    }
}
if (-not $SoundFontPath -or -not (Test-Path -LiteralPath $SoundFontPath -PathType Leaf)) {
    throw "Could not find a SoundFont (.sf2/.sf3). Pass -SoundFontPath 'C:\path\to\soundfont.sf3'."
}

Write-Host "Project root: $Root"
Write-Host "LilyPond:     $LilyPondPath"
Write-Host "pdflatex:     $PdfLatexPath"
Write-Host "FluidSynth:   $FluidSynthPath"
Write-Host "SoundFont:    $SoundFontPath"

$LyFiles = @(Get-ChildItem -LiteralPath $LilyPondDir -Filter "*.ly" -File | Sort-Object Name)
if ($LyFiles.Count -eq 0) { throw "No .ly files found in $LilyPondDir" }

foreach ($LyFile in $LyFiles) {
    $Name = $LyFile.BaseName
    $ScorePdf = Join-Path $ScorePdfDir "$Name.pdf"
    $AudioMidi = Join-Path $AudioDir "$Name.mid"
    $AudioWav = Join-Path $AudioDir "$Name.wav"
    $TempBase = Join-Path $LilyPondTempDir $Name
    $TempPdf = "$TempBase.pdf"
    $TempMidi = "$TempBase.midi"
    $TempMid = "$TempBase.mid"

    $NeedLilyPond = $Force -or -not (Test-Path -LiteralPath $ScorePdf) -or -not (Test-Path -LiteralPath $AudioMidi)
    if ($NeedLilyPond) {
        # Remove stale staged outputs first, so a failed/partial render cannot be mistaken for fresh output.
        Remove-Item -LiteralPath $TempPdf, $TempMidi, $TempMid -Force -ErrorAction SilentlyContinue
        Invoke-CheckedProcess -FilePath $LilyPondPath -Arguments @(
            "--pdf", "--output=$LilyPondTempDir", $LyFile.FullName
        ) -Description "Rendering $($LyFile.Name) to PDF and MIDI"

        if (-not (Test-Path -LiteralPath $TempPdf -PathType Leaf)) {
            throw "LilyPond did not produce the expected PDF: $TempPdf"
        }
        Copy-Item -LiteralPath $TempPdf -Destination $ScorePdf -Force

        if (Test-Path -LiteralPath $TempMidi -PathType Leaf) {
            Copy-Item -LiteralPath $TempMidi -Destination $AudioMidi -Force
        } elseif (Test-Path -LiteralPath $TempMid -PathType Leaf) {
            Copy-Item -LiteralPath $TempMid -Destination $AudioMidi -Force
        } else {
            throw "$($LyFile.Name) produced no MIDI file. Ensure its score contains a \midi { } block."
        }

        # Do not leave duplicate score PDF/MIDI artifacts in the temporary directory.
        Remove-Item -LiteralPath $TempPdf, $TempMidi, $TempMid -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "Up to date: $($LyFile.Name)" -ForegroundColor DarkGray
    }

    if ((Test-Path -LiteralPath $AudioMidi -PathType Leaf) -and ($Force -or -not (Test-Path -LiteralPath $AudioWav -PathType Leaf))) {
        Invoke-CheckedProcess -FilePath $FluidSynthPath -Arguments @(
            "-ni", "-F", $AudioWav, "-T", "wav", "-r", "44100", $SoundFontPath, $AudioMidi
        ) -Description "Rendering $Name.mid to WAV"
    } elseif (-not (Test-Path -LiteralPath $AudioMidi -PathType Leaf)) {
        throw "No MIDI found for $Name; WAV cannot be generated."
    }
}

# Compile the existing root-level LaTeX document twice to resolve references.
$TexName = [System.IO.Path]::GetFileName($TexFile)
$TexBase = [System.IO.Path]::GetFileNameWithoutExtension($TexFile)
for ($Pass = 1; $Pass -le 2; $Pass++) {
    Invoke-CheckedProcess -FilePath $PdfLatexPath -Arguments @(
        "-interaction=nonstopmode", "-halt-on-error", "-file-line-error",
        "-output-directory=$LatexBuildDir", $TexFile
    ) -Description "Compiling $TexName (pass $Pass)"
}
$BuiltPdf = Join-Path $LatexBuildDir "$TexBase.pdf"
if (-not (Test-Path -LiteralPath $BuiltPdf -PathType Leaf)) {
    throw "LaTeX completed without creating the expected PDF: $BuiltPdf"
}
Copy-Item -LiteralPath $BuiltPdf -Destination $FinalPdf -Force

Write-Host "`nBuild complete." -ForegroundColor Green
Write-Host "Combined notes PDF: $FinalPdf"
Write-Host "Individual score PDFs: $ScorePdfDir"
Write-Host "MIDI/WAV audio: $AudioDir"
Write-Host "LaTeX auxiliary files: $LatexBuildDir"
