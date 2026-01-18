$ErrorActionPreference = 'Stop'

# Generates lab2_task2_fixed.hex for lab2_task2_fixed.asm
# Difference vs lab2_task2.hex: ISR branches are swapped so PD2 LOW -> LED ON.

function New-IHexRecord([int]$addr, [byte[]]$data) {
  $len = $data.Length
  $sum = $len + (($addr -shr 8) -band 0xFF) + ($addr -band 0xFF)
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

# Layout (word addresses, matching lab2_task2_fixed.asm):
# 0x0000: jmp start        (2 words)
# 0x0002: jmp isr_into     (2 words)  [INT0addr]
# 0x0004: start:
# 0x000D: loop:
# 0x000E: isr_into:
# 0x0013: on:
# 0x0016: off:

$startWord = 0x0004
$isrWord   = 0x000E

$words = New-Object System.Collections.Generic.List[uint16]

# Vector @ 0x0000: jmp start
$words.Add([uint16]0x940C)
$words.Add([uint16]$startWord)

# Vector @ INT0addr (0x0002): jmp isr_into
$words.Add([uint16]0x940C)
$words.Add([uint16]$isrWord)

# start:
$words.Add([uint16]0xE040) # ldi r20,0x00
$words.Add([uint16]0xE001) # ldi r16,0x01
$words.Add([uint16]0x9300) # sts EICRA,r16
$words.Add([uint16]0x0069) # EICRA address
$words.Add([uint16]0xE001) # ldi r16,0x01
$words.Add([uint16]0xBB0D) # out EIMSK,r16
$words.Add([uint16]0x9478) # sei
$words.Add([uint16]0xE011) # ldi r17,0x01
$words.Add([uint16]0xB91A) # out DDRD,r17

# loop:
$words.Add([uint16]0xCFFF) # rjmp loop

# isr_into: (FIXED BRANCH ORDER)
$words.Add([uint16]0xB109) # in r16,PIND
$words.Add([uint16]0xFD02) # sbrs r16,2
$words.Add([uint16]0xC002) # rjmp on
$words.Add([uint16]0xC004) # rjmp off
$words.Add([uint16]0x9518) # reti

# on:
$words.Add([uint16]0xE001) # ldi r16,0x01
$words.Add([uint16]0xB90B) # out PORTD,r16
$words.Add([uint16]0x9518) # reti

# off:
$words.Add([uint16]0xE000) # ldi r16,0x00
$words.Add([uint16]0xB90B) # out PORTD,r16
$words.Add([uint16]0x9518) # reti

$baseBytes = Emit-Words ($words.ToArray())

$lines = New-Object System.Collections.Generic.List[string]
for ($addr = 0; $addr -lt $baseBytes.Length; $addr += 16) {
  $end = [Math]::Min($baseBytes.Length - 1, $addr + 15)
  $chunk = $baseBytes[$addr..$end]
  $lines.Add((New-IHexRecord -addr $addr -data $chunk))
}

# Arduino boot-start jump stubs to reset vector (0x0000)
$jmpToReset = [byte[]](0x0C,0x94,0x00,0x00)
foreach ($a in @(0x7800, 0x7C00, 0x7E00)) {
  $lines.Add((New-IHexRecord -addr $a -data $jmpToReset))
}

$lines.Add(':00000001FF')

$outPath = Join-Path $PSScriptRoot 'lab2_task2_fixed.hex'
[IO.File]::WriteAllText($outPath, ($lines -join "`r`n") + "`r`n")
Write-Host "Wrote: $outPath"
