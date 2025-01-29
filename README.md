# dumpf
Dump a file in an hexa format

Made in Rust and to generate hexa line to copy and paste it in an Apple 2 Emulator

```
$ dumpf --help
Let's dump a file with the hexa and ascii values | 2o25o129

Usage: dumpf [OPTIONS] <file>

Arguments:
  <file>
          Open file to dump

Options:
  -o, --org <origin>
          Origin of the file to dump (in decimal)

  -x, --hex <size_hexa>
          Number of byte in hex format to display by line
          [default: 16]

  -d, --display <display_format>
          Display in raw format with or without the adress and the ascii parts
                          0: Hexa without address and ascii parts
                          1: Hexa with address only
                          2: Hexa with address and ascii
          [default: 2]

  -h, --help
          Print help (see a summary with '-h')

  -V, --version
          Print version
```

```
$ dumpf invert_dasm.o -d1 -o768
File: invert_dasm.o - Origin: 768 - Length: 76

0300:A9 50 85 08 A9 01 0A 0A 85 07 A0 00 84 06 2C 10
0310:C0 20 38 03 C0 01 B0 15 AD 00 C0 30 09 20 3F 03
0320:C8 C0 28 D0 EC 88 2C 10 C0 20 38 03 60 98 48 88
0330:20 38 03 68 A8 4C 1D 03 B1 06 49 80 91 06 60 48
0340:A2 10 A5 08 20 A8 FC CA D0 F8 68 60

BSAVE INVERT_DASM,A$300,L$4C
```
