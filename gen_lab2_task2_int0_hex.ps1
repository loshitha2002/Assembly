$ErrorActionPreference = 'Stop'

# Generates a valid Intel HEX for Lab2 Task2 (INT0 falling-edge toggle):
# - Switch on PD2 (Arduino D2 / INT0)
# - LED on PD0 (Arduino D0)
# Includes a full interrupt vector table + Arduino boot-start jump stubs.

function New-IHexRecord([int]$addr, [byte[]]$data) {
  $len = $data.Length
  $sum = $len + (($addr -shr 8) -band 0xFF) + ($addr -band 0xFF) + 0
  foreach ($b in $data) { $sum += $b }
  $chk = ((0x100 - ($sum -band 0xFF)) -band 0xFF)
  $hexData = ($data | ForEach-Object { $_.ToString('X2') }) -join ''
  return (':{0}{1}00{2}{3}' -f $len.ToString('X2'), $addr.ToString('X4'), $hexData, $chk.ToString('X2'))
}

function Emit-Words([uint16[]]$words) {
  $bytes = New-Object System.Collections.Generic.List[byte]
  foreach ($w in $words) {
    $bytes.Add([byte]($w -band 0xFF))
    $bytes.Add([byte](($w -shr 8) -band 0xFF))
  }
  return $bytes.ToArray()
}

# Layout (word addresses):
# - vectors: 0x0000..0x0019 (26 words)
# - default_isr: 0x001A (word 26) => byte 0x0034
# - reset/main:  0x001B (word 27) => byte 0x0036
# - INT0_ISR:    0x0028 (word 40) => byte 0x0050

$defaultWord = 0x001A
$resetWord   = 0x001B
$int0Word    = 0x0028

# Build vector table (ATmega328P: reset + 25 IRQ vectors = 26 entries)
# Index 1 is INT0.
$vectorWords = New-Object System.Collections.Generic.List[uint16]
for ($i = 0; $i -lt 26; $i++) {
  if ($i -eq 0) {
    $target = $resetWord
  } elseif ($i -eq 1) {
    $target = $int0Word
  } else {
    $target = $defaultWord
  }

  $k = $target - ($i + 1)
  if ($k -lt -2048 -or $k -gt 2047) { throw "RJMP offset out of range: i=$i k=$k" }
  $k12 = $k
  if ($k12 -lt 0) { $k12 = 0x1000 + $k12 }
  $vectorWords.Add([uint16](0xC000 -bor ($k12 -band 0x0FFF)))
}

$defaultIsrWords = @([uint16]0x9518) # RETI

# Reset routine (matches lab2_task2.asm):
# - init stack
# - PD0 output, PD2 input
# - EICRA: ISC01=1, ISC00=0 (falling edge)
# - EIMSK: INT0=1
# - sei
# - loop forever
$resetWords = @(
  [uint16]0xE008, # LDI r16, 0x08 (high RAMEND)
  [uint16]0xBF0E, # OUT SPH, r16
  [uint16]0xEF0F, # LDI r16, 0xFF (low RAMEND)
  [uint16]0xBF0D, # OUT SPL, r16
  [uint16]0x9A50, # SBI DDRD,0
  [uint16]0x9852, # CBI DDRD,2
  [uint16]0xE002, # LDI r16, 0x02 (ISC01)
  [uint16]0x9300, # STS EICRA, r16
  [uint16]0x0069, # EICRA data address
  [uint16]0xE001, # LDI r16, 0x01
  [uint16]0xBB0D, # OUT EIMSK, r16 (EIMSK I/O addr 0x1D)
  [uint16]0x9478, # SEI
  [uint16]0xCFFF  # RJMP . (idle loop)
)

# INT0 ISR: toggle PD0 on each falling edge
$int0Words = @(
  [uint16]0xB10B, # IN  r16, PORTD (PORTD I/O addr 0x0B)
  [uint16]0xE011, # LDI r17, 0x01
  [uint16]0x2701, # EOR r16, r17
  [uint16]0xB90B, # OUT PORTD, r16
  [uint16]0x9518  # RETI
)

$allWords = $vectorWords.ToArray() + $defaultIsrWords + $resetWords + $int0Words
$baseBytes = (Emit-Words $allWords)

$lines = New-Object System.Collections.Generic.List[string]
for ($addr = 0; $addr -lt $baseBytes.Length; $addr += 16) {
  $end = [Math]::Min($baseBytes.Length - 1, $addr + 15)
  $chunk = $baseBytes[$addr..$end]
  $lines.Add((New-IHexRecord -addr $addr -data $chunk))
}

# Arduino boot-start jump stubs (common boot section starts)
# JMP to reset word address 0x001B (byte address 0x0036): 0x940C 0x001B
$jmpToReset = [byte[]](0x0C,0x94,0x1B,0x00)
$bootStarts = @(0x7800, 0x7C00, 0x7E00)
foreach ($a in $bootStarts) {
  $lines.Add((New-IHexRecord -addr $a -data $jmpToReset))
}

$lines.Add(':00000001FF')

$outPath = Join-Path $PSScriptRoot 'lab2_task2.hex'
[IO.File]::WriteAllText($outPath, ($lines -join "`r`n") + "`r`n")
Write-Host "Wrote: $outPath"