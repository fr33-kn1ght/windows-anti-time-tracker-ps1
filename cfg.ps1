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

function Log {
    param([string]$Message)

    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$time] $Message"
}

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

    $steps = Get-Random -Minimum 10 -Maximum 25

    for ($i = 1; $i -le $steps; $i++) {

        $x = [int]($startX + (($TargetX - $startX) * $i / $steps))
        $y = [int]($startY + (($TargetY - $startY) * $i / $steps))

        [Native]::SetCursorPos($x, $y) | Out-Null

        Start-Sleep -Milliseconds (
            Get-Random -Minimum 5 -Maximum 15
        )
    }
}

$paused = $false

$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds

Log "Started"
Log "F8 - Pause/Resume"
Log "F9 - Exit"

while ($true)
{
    if ([Native]::GetAsyncKeyState(0x78))
    {
        Log "Exit"
        break
    }

    if ([Native]::GetAsyncKeyState(0x77))
    {
        $paused = -not $paused

        if ($paused) {
            Log "Paused"
        }
        else {
            Log "Resumed"
        }

        Start-Sleep -Milliseconds 500
    }

    if ($paused)
    {
        Start-Sleep -Milliseconds 200
        continue
    }

    $r = Get-Random -Minimum 1 -Maximum 101

    if ($r -le 75)
    {
        $p = New-Object Native+POINT
        [Native]::GetCursorPos([ref]$p) | Out-Null

        $microMove = (Get-Random -Minimum 1 -Maximum 101) -le 30

        if ($microMove)
        {
            $dx = Get-Random -Minimum -5 -Maximum 6
            $dy = Get-Random -Minimum -5 -Maximum 6
        }
        else
        {
            $dx = Get-Random -Minimum -50 -Maximum 51
            $dy = Get-Random -Minimum -50 -Maximum 51
        }

        $newX = $p.X + $dx
        $newY = $p.Y + $dy

        $newX = [Math]::Max(
            0,
            [Math]::Min($newX, $screen.Width - 1)
        )

        $newY = [Math]::Max(
            0,
            [Math]::Min($newY, $screen.Height - 1)
        )

        Move-Smooth $newX $newY

        Log "Mouse move -> ($newX,$newY)"
    }
    elseif ($r -le 90)
    {
        $delta = @(120,-120) | Get-Random

        [Native]::mouse_event(
            [Native]::MOUSEEVENTF_WHEEL,
            0,
            0,
            [uint32]$delta,
            [UIntPtr]::Zero
        )

        if ($delta -gt 0)
        {
            Log "Wheel UP"
        }
        else
        {
            Log "Wheel DOWN"
        }
    }
    elseif ($r -le 95)
    {
        Press-Key 0x20
        Log "Key SPACE"
    }
    else
    {
        $keys = @{
            0x10 = "SHIFT"
            0x11 = "CTRL"
            0x12 = "ALT"
        }

        $vk = $keys.Keys | Get-Random

        Press-Key $vk

        Log "Key $($keys[$vk])"
    }

    $delay = Get-Random -Minimum 3 -Maximum 15

    Log "Sleep $delay sec"

    Start-Sleep -Seconds $delay
}
