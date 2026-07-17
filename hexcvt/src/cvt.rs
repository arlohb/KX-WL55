use crate::args::CvtCmd;

use std::io::{Error, Write};

fn parse_nibble(c: char) -> u8 {
    if c >= 'A' {
        (c as u8) - ('A' as u8) + 10
    } else {
        (c as u8) - ('0' as u8)
    }
}

fn parse_byte(l: char, r: char) -> u8 {
    (parse_nibble(l) << 4) | parse_nibble(r)
}

pub fn cvt(config: CvtCmd) -> Result<(), Error> {
    let hex = std::fs::read_to_string(config.in_file)?;
    
    let mut out = std::fs::File::create_new(config.out_file)?;
    
    for line in hex.lines() {
        let iter = line.split_whitespace().skip(2);
        let bytes = iter.map(|str| {
            let mut chars = str.chars();
            let l = chars.next()?;
            let r = chars.next()?;
            Some(parse_byte(l, r))
        }).flatten().collect::<Vec<_>>();
        out.write_all(&bytes)?;
    }

    Ok(())
}
