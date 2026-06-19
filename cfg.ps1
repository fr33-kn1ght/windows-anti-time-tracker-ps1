Add-Type -AssemblyName System.Windows.Forms

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Native
{
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT
    {
        public int X;
        public int Y;
    }

    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    [DllImport("user32.dll")]
    public static extern void mouse_event(
        uint dwFlags,
        uint dx,
        uint dy,
        uint dwData,
        UIntPtr dwExtraInfo);

    [DllImport("user32.dll")]
    public static extern void keybd_event(
        byte bVk,
        byte bScan,
        uint dwFlags,
        UIntPtr dwExtraInfo);

    public const uint MOUSEEVENTF_WHEEL = 0x0800;
    public const uint KEYEVENTF_KEYUP = 0x0002;
}
"@

$paused = $false

function Press-Key {
    param([byte]$vk)

    [Native]::keybd_event($vk,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 50
    [Native]::keybd_event($vk,0,[Native]::KEYEVENTF_KEYUP,[UIntPtr]::Zero)
}

function Move-Smooth {
    param(
        [int]$TargetX,
        [int]$TargetY
    )

    $p = New-Object Native+POINT
    [Native]::GetCursorPos([ref]$p) | Out-Null

    $startX = $p.X
    $startY = $p.Y

    $steps = Get-Random -Minimum 10 -Maximum 30

    for ($i = 1; $i -le $steps; $i++) {

        $x = [int]($startX + (($TargetX - $startX) * $i / $steps))
        $y = [int]($startY + (($TargetY - $startY) * $i / $steps))

        [Native]::SetCursorPos($x, $y) | Out-Null
        Start-Sleep -Milliseconds (Get-Random -Minimum 5 -Maximum 20)
    }
}

Write-Host ""
Write-Host "F8 - Pause/Resume"
Write-Host "F9 - Exit"
Write-Host ""

$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds

while ($true)
{
    # F9 - выход
    if ([Native]::GetAsyncKeyState(0x78)) { # F9
        Write-Host "Exit"
        break
    }

    # F8 - переключение паузы
    if ([Native]::GetAsyncKeyState(0x77)) { # F8
        $paused = -not $paused

        if ($paused) {
            Write-Host "Paused"
        }
        else {
            Write-Host "Resumed"
        }

        Start-Sleep -Milliseconds 500
    }

    if ($paused) {
        Start-Sleep -Milliseconds 200
        continue
    }

    $action = Get-Random -Minimum 0 -Maximum 10

    switch ($action)
    {
        {$_ -le 5} {
            # Плавный небольшой сдвиг мыши
            $p = New-Object Native+POINT
            [Native]::GetCursorPos([ref]$p) | Out-Null

            $newX = $p.X + (Get-Random -Minimum -50 -Maximum 51)
            $newY = $p.Y + (Get-Random -Minimum -50 -Maximum 51)

            $newX = [Math]::Max(0, [Math]::Min($newX, $screen.Width - 1))
            $newY = [Math]::Max(0, [Math]::Min($newY, $screen.Height - 1))

            Move-Smooth $newX $newY
        }

        6 {
            # Колесо вверх
            [Native]::mouse_event(
                [Native]::MOUSEEVENTF_WHEEL,
                0,0,120,[UIntPtr]::Zero)
        }

        7 {
            # Колесо вниз
            [Native]::mouse_event(
                [Native]::MOUSEEVENTF_WHEEL,
                0,0,[uint32]-120,[UIntPtr]::Zero)
        }

        8 {
            Press-Key 0x20  # Space
        }

        9 {
            Press-Key (Get-Random @(0x10,0x11,0x12)) # Shift/Ctrl/Alt
        }
    }

    Start-Sleep -Seconds (Get-Random -Minimum 3 -Maximum 15)
}
