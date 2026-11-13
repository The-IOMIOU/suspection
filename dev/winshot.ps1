# Screenshot one process's main window with PrintWindow(PW_RENDERFULLCONTENT), which captures D3D12 games without
# focusing them. Usage: winshot.ps1 -Proc BeamNG.drive.x64 -Out shot.png [-Scale 0.5]
param([Parameter(Mandatory)][string]$Proc, [Parameter(Mandatory)][string]$Out, [double]$Scale = 1.0)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class W {
  [StructLayout(LayoutKind.Sequential)] public struct R { public int L, T, Ri, B; }
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out R r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
  [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr c);
}
"@
# Per-monitor DPI aware, or GetClientRect returns scaled sizes and the capture is a cropped corner of a 4K window.
[W]::SetThreadDpiAwarenessContext([IntPtr]-4) | Out-Null
$p = Get-Process $Proc -ErrorAction Stop | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $p) { throw "no window for $Proc" }
$r = New-Object W+R
[W]::GetClientRect($p.MainWindowHandle, [ref]$r) | Out-Null
$bmp = New-Object System.Drawing.Bitmap ([Math]::Max(1, $r.Ri)), ([Math]::Max(1, $r.B))
$g = [System.Drawing.Graphics]::FromImage($bmp)
$dc = $g.GetHdc()
$ok = [W]::PrintWindow($p.MainWindowHandle, $dc, 3) # PW_CLIENTONLY | PW_RENDERFULLCONTENT
$g.ReleaseHdc($dc)
if ($Scale -ne 1.0) {
  $s = New-Object System.Drawing.Bitmap ([int]($bmp.Width * $Scale)), ([int]($bmp.Height * $Scale))
  $gs = [System.Drawing.Graphics]::FromImage($s)
  $gs.InterpolationMode = 'HighQualityBilinear'
  $gs.DrawImage($bmp, 0, 0, $s.Width, $s.Height)
  $bmp = $s
}
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
"$Proc $($r.Ri)x$($r.B) printwindow=$ok -> $Out"
