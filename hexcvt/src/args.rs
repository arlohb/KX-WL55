use clap::{Parser, Args};

#[derive(Args, Debug)]
pub struct CvtCmd {
    pub in_file: String,
    pub out_file: String,
}

#[derive(Args, Debug)]
pub struct GenTestCmd {
    pub out_file: String,
    pub size: u32,
}

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
pub enum Commands {
    Cvt(CvtCmd),
    GenTest(GenTestCmd),
}
