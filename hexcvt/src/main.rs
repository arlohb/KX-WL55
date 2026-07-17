mod args;
mod cvt;
mod gen_test;

use clap::Parser;
use args::Commands;

fn main() {
    let args = Commands::parse();
    
    match args {
        Commands::Cvt(config) => {
            cvt::cvt(config).unwrap();
        },
        Commands::GenTest(config) => {
            gen_test::gen_test(config).unwrap();
        },
    }
}
