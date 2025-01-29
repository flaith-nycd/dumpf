use std::fs::OpenOptions;
use std::io::{BufReader, Error};
use std::io::prelude::*;
use std::process::exit;
use clap::{Arg, command};

const TOTAL_BYTE_DISPLAY: &str = "16";
const ORIGIN: &str = "0";
/*
 0: Hexa without address and ascii parts
 1: Hexa with address only
 2: Hexa with address and ascii
 */
const DISPLAY_FORMAT: &str = "2";

enum KindOfDisplay {
    HexaOnly = 0,
    HexaAddress,
    HexaAddressAscii,
}

fn load_file(filename: &str) -> Vec<u8> {
    // Open a shared file (Windows only)
    // https://stackoverflow.com/questions/75608860/opening-file-in-share-mode-as-in-winapi
    let file = match OpenOptions::new().read(true).open(&filename) {
        Ok(file) => file,
        Err(error) => {
            match error.kind() {
                std::io::ErrorKind::NotFound => {
                    println!("File \"{filename}\" not found !");
                    exit(-2)
                },
                _ => {
                    println!("Error: {} !", error.kind());
                    exit(-3)
                }
            };
        },
    };

    let file_size: u64 = file.metadata().unwrap().len();
 
    if file_size > 0 {
        let buf_reader = BufReader::new(file);
        // Create a buffer to load data into.
        let mut buffer = Vec::with_capacity(file_size as usize);
        let mut part_reader = buf_reader.take(file_size);
        // Read into the buffer
        part_reader.read_to_end(&mut buffer).unwrap();

        buffer
    } else { 
        println!("ERROR *** File \"{}\" cannot be dumped with nothing inside !", filename);
        exit(-1)
    }
}

fn main() -> Result<(), Error> {
    // Handle args
    let file = Arg::new("file")
        .help("Open file to dump")
        .required(true);

    let origin = Arg::new("origin")
        .short('o')
        .long("org")
        .help("Origin of the file to dump (in decimal)")
        .required_unless_present("file");

    let size_hexa = Arg::new("size_hexa")
        .default_value(TOTAL_BYTE_DISPLAY)
        .short('x')
        .long("hex")
        .help("Number of byte in hex format to display by line")
        .required_unless_present("file");

    let display_format = Arg::new("display_format")
        .default_value(DISPLAY_FORMAT)
        .short('d')
        .long("display")
        .help("Display format")
        .long_help(
            "Display in raw format with or without the adress and the ascii parts
                0: Hexa without address and ascii parts
                1: Hexa with address only
                2: Hexa with address and ascii 
            ")
        .required_unless_present("file");

    let matches = command!() // requires `cargo` feature
        .arg(file)
        .arg(origin)
        .arg(size_hexa)
        .arg(display_format)
        .get_matches();

    let filename = if let Some(file) = matches.get_one::<String>("file") {
        file
    } else {
        ""
    };

    let size: usize = if let Some(size_hexa) = matches.get_one::<String>("size_hexa") {
        size_hexa.parse().unwrap()
    } else {
        TOTAL_BYTE_DISPLAY.parse::<usize>().unwrap_or_else(|_| 16)
    };

    let org: usize = if let Some(origin) = matches.get_one::<String>("origin") {
        origin.parse().unwrap()
    } else {
        ORIGIN.parse::<usize>().unwrap_or_else(|_| 0)
    };

    let display: u32 = if let Some(display_format) = matches.get_one::<String>("display_format") {
        match display_format.parse::<u32>() {
            Ok(valid) => valid,
            _ => KindOfDisplay::HexaAddressAscii as u32,
        }
    } else {
        DISPLAY_FORMAT.parse::<u32>().unwrap_or_else(|_| KindOfDisplay::HexaAddressAscii as u32)
    };

    // Load file to dump
    let file_to_dump = load_file(filename);

    let total_byte_display = size;
    let mut index = 0;
    let mut counter = 0;
    let length = file_to_dump.len();

    // Start here
    let mut width = 8;      // For the length of each line addresses
    let mut hex_line = String::new();
    let mut ascii_line = String::new();

    let mut one_byte = file_to_dump[index] & 0xFF;
    
    if org + length <= 0xFFFF {
      width = 4;
    }

    if display == KindOfDisplay::HexaAddressAscii as u32 {
        if one_byte > 31 && one_byte < 127 {
            ascii_line.push(one_byte as char);
        } else {
            ascii_line.push_str(".");
        }
    }

    hex_line.push_str(&format!("{:02X} ", one_byte));

    index += 1;

    while index < length {
        // Index at position total_byte_display ?
        if index % total_byte_display == 0 {
            // Print the new line
            match display {
                display if display == KindOfDisplay::HexaOnly as u32 => println!("{}", hex_line),
                display if display == KindOfDisplay::HexaAddress as u32 => println!("{:0>width$X}:{}", counter + org, hex_line),
                display if display == KindOfDisplay::HexaAddressAscii as u32 => println!("{:0>width$X}:{}- {}", counter + org, hex_line, ascii_line),
                _ => (),
            }
            hex_line = String::new();
            ascii_line = String::new();
            counter = index;
        }
        // Then continue to add values in the current line
        one_byte = file_to_dump[index] & 0xFF;  // get the byte

        if display == KindOfDisplay::HexaAddressAscii as u32 {
            if one_byte > 31 && one_byte < 127 {
                ascii_line.push(one_byte as char);
            } else {
                ascii_line.push_str(".");
            }
        }

        // Add the value to the string
        hex_line.push_str(&format!("{:02X} ", one_byte));

        // Next byte
        index += 1;
    }

    match display {
        display if display == KindOfDisplay::HexaOnly as u32 => println!("{}", hex_line),
        display if display == KindOfDisplay::HexaAddress as u32 => println!("{:0>width$X}:{}", counter + org, hex_line),
        display if display == KindOfDisplay::HexaAddressAscii as u32 => {
            // Handle the space between hex and ascii strings
            let space_at_the_end = total_byte_display - (length - counter);
            let space_string = " ".repeat(space_at_the_end + space_at_the_end * 2);
            hex_line.push_str(space_string.as_str());

            // Print the last line if we're not at the at the position total_byte_display
            println!("{:0>width$X}:{}- {} ", counter + org, hex_line, ascii_line);
        }
        _ => (),
    }

    println!();
    //println!("File: {},A${:X},L${:X}", &filename, org, length);
    println!("File: {}", &filename);
    println!(" ORG: {} (${:X})", org, org);
    println!(" LEN: {} (${:X})", length, length);

    Ok(())
}
