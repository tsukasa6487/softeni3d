param(
  [Parameter(Mandatory=$true)][string]$InputImage,
  [Parameter(Mandatory=$true)][string]$OutputImage,
  [Parameter(Mandatory=$true)][string]$Headline,
  [string]$Caption = 'ソフテニ3D',
  [ValidateSet('medium','large')][string]$Display = 'medium'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$source = [System.Drawing.Image]::FromFile((Resolve-Path -LiteralPath $InputImage).Path)
$width = if ($Display -eq 'medium') { 1179 } else { 1320 }
$height = if ($Display -eq 'medium') { 2556 } else { 2868 }
$canvas = [System.Drawing.Bitmap]::new($width,$height,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$graphics = [System.Drawing.Graphics]::FromImage($canvas)
$resources = New-Object System.Collections.Generic.List[System.IDisposable]
try {
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#062e28'))
  # Scale the layout uniformly so the source capture keeps its aspect ratio.
  $scale = [single]($width / 1320.0)
  $graphics.ScaleTransform($scale,$scale)
  $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
  $mint = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#6ee7b7'))
  $titleFont = New-Object System.Drawing.Font 'Yu Gothic',68,([System.Drawing.FontStyle]::Bold),([System.Drawing.GraphicsUnit]::Pixel)
  $captionFont = New-Object System.Drawing.Font 'Yu Gothic',40,([System.Drawing.FontStyle]::Bold),([System.Drawing.GraphicsUnit]::Pixel)
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  foreach ($item in @($white,$mint,$titleFont,$captionFont,$format)) { $resources.Add($item) }
  $graphics.DrawString($Caption,$captionFont,$mint,(New-Object System.Drawing.RectangleF 80,100,1160,80),$format)
  $titleRect = New-Object System.Drawing.RectangleF 80,210,1160,260
  $titleSize = $graphics.MeasureString($Headline,$titleFont,1160)
  if ($titleSize.Height -gt 260) { throw '見出しが枠に入りません。短くしてください。' }
  $graphics.DrawString($Headline,$titleFont,$white,$titleRect,$format)
  # Fit the entire capture. Never crop or distort the application UI.
  $ratio = [Math]::Min(1110.0/$source.Width,2110.0/$source.Height)
  $imageWidth = [int][Math]::Round($source.Width*$ratio)
  $imageHeight = [int][Math]::Round($source.Height*$ratio)
  $left = [int]((1320-$imageWidth)/2)
  $top = [int](570+(2110-$imageHeight)/2)
  $graphics.FillRectangle($white,$left-12,$top-12,$imageWidth+24,$imageHeight+24)
  $graphics.DrawImage($source,$left,$top,$imageWidth,$imageHeight)
  $target = [System.IO.Path]::GetFullPath($OutputImage)
  $parent = [System.IO.Path]::GetDirectoryName($target)
  if (-not [System.IO.Directory]::Exists($parent)) { throw "出力先フォルダを先に作ってください: $parent" }
  if ($target -eq (Resolve-Path -LiteralPath $InputImage).Path) { throw '素材への上書きはできません。' }
  $canvas.Save($target,[System.Drawing.Imaging.ImageFormat]::Png)
  Write-Output "Saved: $target ($width x $height, RGB)"
} finally {
  foreach ($item in $resources) { $item.Dispose() }
  $graphics.Dispose()
  $canvas.Dispose()
  $source.Dispose()
}
