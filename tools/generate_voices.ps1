# Records placeholder voice lines for every entry in data/lines.json using the
# Windows text-to-speech voices. Real recordings dropped into audio/voice/ with
# the same file name replace these. Pitch per speaker is applied in-game
# (scripts/audio.gd, SPEAKERS) so it can be tuned without re-recording.
#
# Usage:  powershell -ExecutionPolicy Bypass -File tools/generate_voices.ps1 [-Force]
param([switch]$Force)

$root = Split-Path -Parent $PSScriptRoot
$lines = Get-Content -Raw -Encoding UTF8 (Join-Path $root "data/lines.json") | ConvertFrom-Json
$outDir = Join-Path $root "audio/voice"
New-Item -ItemType Directory -Force $outDir | Out-Null

Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$format = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(22050, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)

# speaker -> SAPI voice and speaking rate (-10..10)
$voices = @{
	"leo"     = @{ voice = "Microsoft Zira Desktop";  rate = 1 }
	"mom"     = @{ voice = "Microsoft Zira Desktop";  rate = -1 }
	"dad"     = @{ voice = "Microsoft David Desktop"; rate = -1 }
	"sibling" = @{ voice = "Microsoft David Desktop"; rate = 2 }
	"tv"      = @{ voice = "Microsoft David Desktop"; rate = 2 }
}

$made = 0
foreach ($p in $lines.PSObject.Properties) {
	if ($p.Name.StartsWith("_")) { continue }
	$file = Join-Path $outDir ($p.Name + ".wav")
	if ((Test-Path $file) -and -not $Force) { continue }
	$v = $voices[$p.Value.speaker]
	if (-not $v) { Write-Warning "Unknown speaker '$($p.Value.speaker)' for $($p.Name)"; continue }
	$synth.SelectVoice($v.voice)
	$synth.Rate = $v.rate
	$synth.SetOutputToWaveFile($file, $format)
	$synth.Speak($p.Value.text)
	$synth.SetOutputToNull()
	$made++
}
$synth.Dispose()
Write-Output "Recorded $made line(s) into $outDir"
