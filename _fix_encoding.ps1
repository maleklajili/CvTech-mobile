param()
$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

$files = @(
  'lib\presentation\views\profile\ai_cv_view.dart',
  'lib\presentation\views\profile\cv_builder_view.dart',
  'lib\presentation\views\profile\cv_customization_screen.dart',
  'lib\presentation\views\profile\cv_preview_screen.dart',
  'lib\presentation\views\profile\manual_cv_view.dart',
  'lib\presentation\views\profile\manual_cv_form_view.dart',
  'lib\presentation\views_models\profile\ai_cv_view_model.dart',
  'lib\presentation\views_models\profile\manual_cv_view_model.dart',
  'lib\presentation\views_models\profile\cv_template_selector_view_model.dart',
  'lib\presentation\views_models\profile\cv_theme_view_model.dart',
  'lib\presentation\widgets\cv\cv_preview_widget.dart',
  'lib\utils\cv_pdf_generator.dart',
  'lib\presentation\views\profile\widgets\tab_profile\info_tab\generate_cv\cv_template_selector_dialog.dart'
)

$latin1 = [System.Text.Encoding]::GetEncoding(1252)
$utf8   = New-Object System.Text.UTF8Encoding($false)

# Mojibake marker chars: U+00C3 (A-tilde), U+00E2 (a-circumflex), U+00C2 (A-circumflex)
$markerChars = @([char]0x00C3, [char]0x00E2, [char]0x00C2)

foreach ($f in $files) {
  if (-not (Test-Path $f)) { Write-Host "SKIP    $f"; continue }
  $content = [System.IO.File]::ReadAllText($f, $utf8)
  $hit = $false
  foreach ($c in $markerChars) { if ($content.IndexOf($c) -ge 0) { $hit = $true; break } }
  if (-not $hit) { Write-Host "CLEAN   $f"; continue }
  $bytes = $latin1.GetBytes($content)
  $fixed = $utf8.GetString($bytes)
  [System.IO.File]::WriteAllText($f, $fixed, $utf8)
  Write-Host "FIXED   $f"
}
