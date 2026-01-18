$ErrorActionPreference = 'Stop'

# Generates lab2_task3.hex for the ADC Polling Code

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

$words = New-Object System.Collections.Generic.List[uint16]

# 0x0000: rjmp main (offset 1 -> 0x0002)
$words.Add([uint16]0xC001)

# 0x0001: (unused vector space filler)
$words.Add([uint16]0x0000)

# 0x0002: main
$words.Add([uint16]0xE008) # ldi r16,0x08 (HIGH RAMEND)
$words.Add([uint16]0xBF0E) # out SPH,r16
$words.Add([uint16]0xEF0F) # ldi r16,0xFF (LOW RAMEND)
$words.Add([uint16]0xBF0D) # out SPL,r16

$words.Add([uint16]0xEF0F) # ldi r16,0xFF
$words.Add([uint16]0xB90A) # out DDRD,r16

$words.Add([uint16]0xE600) # ldi r16,0x60
$words.Add([uint16]0x9300) # sts ADMUX,r16
$words.Add([uint16]0x007C) # addr ADMUX (0x7C)

$words.Add([uint16]0xE807) # ldi r16,0x87
$words.Add([uint16]0x9300) # sts ADCSRA,r16
$words.Add([uint16]0x007A) # addr ADCSRA (0x7A)

# loop:
$words.Add([uint16]0x9100) # lds r16, ADCSRA
$words.Add([uint16]0x007A) 
$words.Add([uint16]0x6400) # ori r16, 0x40
$words.Add([uint16]0x9300) # sts ADCSRA, r16
$words.Add([uint16]0x007A)

# wait_adc:
$words.Add([uint16]0x9100) # lds r16, ADCSRA
$words.Add([uint16]0x007A)
$words.Add([uint16]0xFD06) # sbrc r16, 6
$words.Add([uint16]0xCFFC) # rjmp wait_adc (-4 words: back to lds r16, ADCSRA)

# read & display:
$words.Add([uint16]0x9100) # lds r16, ADCH
$words.Add([uint16]0x0079) # addr ADCH (0x79)
$words.Add([uint16]0xB90B) # out PORTD, r16

# rjmp loop
$words.Add([uint16]0xCFF5) # rjmp loop (-11 words)


$baseBytes = Emit-Words ($words.ToArray())

$lines = New-Object System.Collections.Generic.List[string]
for ($addr = 0; $addr -lt $baseBytes.Length; $addr += 16) {
  $end = [Math]::Min($baseBytes.Length - 1, $addr + 15)
  $chunk = $baseBytes[$addr..$end]
  $lines.Add((New-IHexRecord -addr $addr -data $chunk))
}

$lines.Add(':00000001FF')

$outPath = Join-Path $PSScriptRoot 'lab2_task3.hex'
[IO.File]::WriteAllText($outPath, ($lines -join "`r`n") + "`r`n")
Write-Host "Wrote: $outPath"
