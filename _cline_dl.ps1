$ErrorActionPreference = 'Continue'
Set-Location 'c:\Users\Administrator\Desktop\Test\TestDemo'
Remove-Module PSReadLine -ErrorAction SilentlyContinue
$log   = "$env:TEMP\zz_dl.txt"
$cmake = 'C:\Users\Administrator\AppData\Local\stm32cube\bundles\cmake\4.3.1+st.1\bin\cmake.exe'
$p     = 'C:\Users\Administrator\AppData\Local\stm32cube\bundles\programmer\2.23.0\bin\STM32_Programmer_CLI.exe'

function Note([string]$t) { $t | Out-File -Append -Encoding utf8 $log }
function R32([string]$a, [int]$n) { return ((& $p -c port=SWD mode=hotplug -r32 $a $n 2>&1 | Select-String '^0x' | Out-String).Trim()) }

'=== BUILD ===' | Out-File -Encoding utf8 $log
(& $cmake --build 'build\Debug' 2>&1 | Select-String 'error|warning|Linking|RAM:|FLASH:|ninja:') | Out-File -Append -Encoding utf8 $log
Note ('BUILD EXIT = ' + $LASTEXITCODE)

'=== FLASH ===' | Out-File -Append -Encoding utf8 $log
(& $p -c port=SWD -w 'build\Debug\TestDemo.elf' -v -rst 2>&1 | Select-String 'Download verified|Error|Warning|Size') | Out-File -Append -Encoding utf8 $log
Start-Sleep -Milliseconds 2000

'=== REGISTERS AFTER RESET ===' | Out-File -Append -Encoding utf8 $log
Note ('TIM1 CR1                : ' + (R32 0x40012C00 4))
Note ('TIM1 CCER/CNT/PSC/ARR   : ' + (R32 0x40012C20 16))
Note ('TIM1 CCR2               : ' + (R32 0x40012C38 4))
Note ('GPIOA_CRH (PA9)         : ' + (R32 0x40010804 4))
Note ('GPIOB_CRL (PB4/PB5)     : ' + (R32 0x40010C00 4))
Note ('GPIOA_IDR (PA9 level)   : ' + (R32 0x40010808 4))
for ($i = 0; $i -lt 4; $i++) {
    Note ("GPIOB_IDR (LED) sample $i : " + (R32 0x40010C08 4))
    Start-Sleep -Milliseconds 250
}
'=== DONE ===' | Out-File -Append -Encoding utf8 $log
