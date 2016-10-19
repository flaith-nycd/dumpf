# dumpf
Disassembling/Dumping a file in an x86 hexa format

It's a simple version of disassembler, just a try actually :)

Made with purebasic (www.purebasic.com)

The file "dumpf.1.gz" if the man page for GNU/Linux

## Usage
```
dumpf [OPTION] file
  Option :
    -h               : this help
    -v               : program version
    -l               : print the licence

    -t [VAL]         : Dump to [VAL] bytes per line (default = 16)
    -d               : Disassemble
    -d 0x00F00501... : Disassemble immediate value
                       (It's important to start with "0x")
```

## Example
```
dumpf -d 0x0500012501000300C9C3
    00000000:05 00 01                     ADD  AX,0100
    00000003:25 01 00 03 00               AND  EAX,00030001
    00000008:C9                           LEAVE
    00000009:C3                           RET
    
$dumpf -d dumpf > dumpf.asm
$cat dumpf.asm
    ...
    000006E6:04 08                        ADD  AL,08
    000006E8:07                           POP  ES
    000006E9:1F                           POP  DS
    000006EA:00 00                        ADD  [EAX],AL
    000006EC:55                           PUSH EBP
    000006ED:89 E5                        MOV  EBP,ESP
    000006EF:83 EC 08                     SUB  ESP,08
    000006F2:E8 ED 01 00 00               CALL 000008E4
    000006F7:E8 44 02 00 00               CALL 00000940
    000006FC:E8 0F 4E 00 00               CALL 00005510
    00000701:C9                           LEAVE
    00000702:C3                           RET
    ...
```
