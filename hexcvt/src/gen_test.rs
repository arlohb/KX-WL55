use std::io::{Error, Write};

use crate::args::GenTestCmd;


pub fn gen_test(config: GenTestCmd) -> Result<(), Error> {
    let mut out = std::fs::File::create_new(config.out_file)?;
    
    for i in 0..config.size {
        let value = (255f32 * (i as f32 / config.size as f32)) as u8;
        out.write(&[value])?;
    }
    
    Ok(())
}
