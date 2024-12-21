# dumpf
Dump a file in an hexa format
Options:
  0: Hexa without address and ascii parts
  1: Hexa with address only
  2: Hexa with address and ascii

Made in Rust and to generate hexa line to copy and paste it in Applewin for Apple 2

$ dumpf --help
Let's dump a file with the hexa and ascii values | 2o241220

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
