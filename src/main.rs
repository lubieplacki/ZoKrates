//
// @file main.rs
// @author Jacob Eberhardt <jacob.eberhardt@tu-berlin.de>
// @author Dennis Kuhnert <dennis.kuhnert@campus.tu-berlin.de>
// @date 2017

#![feature(box_patterns, box_syntax)]

extern crate clap;
#[macro_use]
extern crate lazy_static;
extern crate num; // cli
extern crate serde; // serialization deserialization
#[macro_use]
extern crate serde_derive;
extern crate bincode;
extern crate regex;

mod absy;
mod parser;
mod imports;
mod semantics;
mod flatten;
mod compile;
mod optimizer;
mod r1cs;
mod field;
mod verification;
#[cfg(not(feature = "nolibsnark"))]
mod libsnark;

use std::fs::File;
use std::path::{Path, PathBuf};
use std::io::{BufWriter, Write, BufReader, BufRead, stdin};
use std::collections::HashMap;
use std::string::String;
use compile::compile;
use field::{Field, FieldPrime};
use absy::Prog;
use r1cs::r1cs_program;
use clap::{App, AppSettings, Arg, SubCommand};
#[cfg(not(feature = "nolibsnark"))]
use libsnark::{setup, generate_proof};
use bincode::{serialize_into, deserialize_from , Infinite};
use regex::Regex;
use verification::CONTRACT_TEMPLATE;

fn main() {
    const FLATTENED_CODE_DEFAULT_PATH: &str = "out";
    const VERIFICATION_KEY_DEFAULT_PATH: &str = "verification.key";
    const PROVING_KEY_DEFAULT_PATH: &str = "proving.key";
    const VERIFICATION_CONTRACT_DEFAULT_PATH: &str = "verifier.sol";
    const WITNESS_DEFAULT_PATH: &str = "witness";
    const VARIABLES_INFORMATION_KEY_DEFAULT_PATH: &str = "variables.inf";

    // cli specification using clap library
    let matches = App::new("ZoKrates")
    .setting(AppSettings::SubcommandRequiredElseHelp)
    .version("0.1")
    .author("Jacob Eberhardt, Dennis Kuhnert")
    .about("Supports generation of zkSNARKs from high level language code including Smart Contracts for proof verification on the Ethereum Blockchain.\n'I know that I show nothing!'")
    .subcommand(SubCommand::with_name("compile")
                                    .about("Compiles into flattened conditions. Produces two files: human-readable '.code' file and binary file")
                                    .arg(Arg::with_name("input")
                                        .short("i")
                                        .long("input")
                                        .help("path of source code file to compile.")
                                        .value_name("FILE")
                                        .takes_value(true)
                                        .required(true)
                                    ).arg(Arg::with_name("output")
                                        .short("o")
                                        .long("output")
                                        .help("output file path.")
                                        .value_name("FILE")
                                        .takes_value(true)
                                        .required(false)
                                        .default_value(FLATTENED_CODE_DEFAULT_PATH)
                                    ).arg(Arg::with_name("optimized")
                                        .long("optimized")
                                        .help("perform optimization.")
                                        .required(false)
                                    )
                                 )
    .subcommand(SubCommand::with_name("setup")
        .about("Performs a trusted setup for a given constraint system.")
        .arg(Arg::with_name("input")
            .short("i")
            .long("input")
            .help("path of comiled code.")
            .value_name("FILE")
            .takes_value(true)
            .required(false)
            .default_value(FLATTENED_CODE_DEFAULT_PATH)
        )
        .arg(Arg::with_name("proving-key-path")
            .short("p")
            .long("proving-key-path")
            .help("Path of the generated proving key file.")
            .value_name("FILE")
            .takes_value(true)
            .required(false)
            .default_value(PROVING_KEY_DEFAULT_PATH)
        )
        .arg(Arg::with_name("verification-key-path")
            .short("v")
            .long("verification-key-path")
            .help("Path of the generated verification key file.")
            .value_name("FILE")
            .takes_value(true)
            .required(false)
            .default_value(VERIFICATION_KEY_DEFAULT_PATH)
        )
        .arg(Arg::with_name("meta-information")
            .short("m")
            .long("meta-information")
            .help("Path of file containing meta information for variable transformation.")
            .value_name("FILE")
            .takes_value(true)
            .required(false)
            .default_value(VARIABLES_INFORMATION_KEY_DEFAULT_PATH)
        )
    )
    .subcommand(SubCommand::with_name("export-verifier")
        .about("Exports a verifier as Solidity smart contract.")
        .arg(Arg::with_name("input")
            .short("i")
            .long("input")
            .help("path of verifier.")
            .value_name("FILE")
            .takes_value(true)
            .required(false)
            .default_value(VERIFICATION_KEY_DEFAULT_PATH)
        )
        .arg(Arg::with_name("output")
            .short("o")
            .long("output")
            .help("output file path.")
            .value_name("FILE")
            .takes_value(true)
            .required(false)
            .default_value(VERIFICATION_CONTRACT_DEFAULT_PATH)
        )
    )
    .subcommand(SubCommand::with_name("compute-witness")
        .about("Calculates a witness for a given constraint system, i.e., a variable assignment which satisfies all constraints. Private inputs are specified interactively.")
        .arg(Arg::with_name("input")
            .short("i")
            .long("input")
            .help("path of compiled code.")
            .value_name("FILE")
            .takes_value(true)
            .required(false)
            .default_value(FLATTENED_CODE_DEFAULT_PATH)
        ).arg(Arg::with_name("output")
            .short("o")
            .long("output")
            .help("output file path.")
            .value_name("FILE")
            .takes_value(true)
            .required(false)
            .default_value(WITNESS_DEFAULT_PATH)
        ).arg(Arg::with_name("arguments")
            .short("a")
            .long("arguments")
            .help("Arguments for the program's main method. Space separated list.")
            .takes_value(true)
            .multiple(true) // allows multiple values
            .required(false)
        ).arg(Arg::with_name("interactive")
            .long("interactive")
            .help("enter private inputs interactively.")
            .required(false)
        )
    )
    .subcommand(SubCommand::with_name("generate-proof")
        .about("Calculates a proof for a given constraint system and witness.")
        .arg(Arg::with_name("witness")
            .short("w")
            .long("witness")
            .help("Path of witness file.")
            .value_name("FILE")
            .takes_value(true)
            .required(false)
            .default_value(WITNESS_DEFAULT_PATH)
        ).arg(Arg::with_name("provingkey")
            .short("p")
            .long("provingkey")
            .help("Path of proving key file.")
            .value_name("FILE")
            .takes_value(true)
            .required(false)
            .default_value(PROVING_KEY_DEFAULT_PATH)
        ).arg(Arg::with_name("meta-information")
            .short("i")
            .long("meta-information")
            .help("Path of file containing meta information for variable transformation.")
            .value_name("FILE")
            .takes_value(true)
            .required(false)
            .default_value(VARIABLES_INFORMATION_KEY_DEFAULT_PATH)
        )
    )
    .get_matches();

    match matches.subcommand() {
        ("compile", Some(sub_matches)) => {
            println!("Compiling {}", sub_matches.value_of("input").unwrap());

            let path = PathBuf::from(sub_matches.value_of("input").unwrap());

            let should_optimize = sub_matches.occurrences_of("optimized") > 0;

            let program_flattened: Prog<FieldPrime> = match compile(path, should_optimize) {
                Ok(p) => p,
                Err(why) => panic!("Compilation failed: {}", why)
            };

            // number of constraints the flattened program will translate to.
            let num_constraints = &program_flattened.functions
            .iter()
            .find(|x| x.id == "main")
            .unwrap().statements.len();

            // serialize flattened program and write to binary file
            let bin_output_path = Path::new(sub_matches.value_of("output").unwrap());
            let mut bin_output_file = match File::create(&bin_output_path) {
                Ok(file) => file,
                Err(why) => panic!("couldn't create {}: {}", bin_output_path.display(), why),
            };

            serialize_into(&mut bin_output_file, &program_flattened, Infinite).expect("Unable to write data to file.");

            // write human-readable output file
            let hr_output_path = bin_output_path.to_path_buf().with_extension("code");

            let hr_output_file = match File::create(&hr_output_path) {
                Ok(file) => file,
                Err(why) => panic!("couldn't create {}: {}", hr_output_path.display(), why),
            };

            let mut hrofb = BufWriter::new(hr_output_file);
            write!(&mut hrofb, "{}\n", program_flattened).expect("Unable to write data to file.");
            hrofb.flush().expect("Unable to flush buffer.");

            // debugging output
            // println!("Compiled program:\n{}", program_flattened);

            println!(
                "Compiled code written to '{}', \nHuman readable code to '{}'. \nNumber of constraints: {}",
                "",
                "",
                num_constraints
            );
        }
        ("compute-witness", Some(sub_matches)) => {
            println!("Computing witness for:");

            // read compiled program
            let path = Path::new(sub_matches.value_of("input").unwrap());
            let mut file = match File::open(&path) {
                Ok(file) => file,
                Err(why) => panic!("couldn't open {}: {}", path.display(), why),
            };

            let program_ast: Prog<FieldPrime> = match deserialize_from(&mut file, Infinite) {
                Ok(x) => x,
                Err(why) => {
                    println!("{:?}", why);
                    std::process::exit(1);
                }
            };

            // make sure the input program is actually flattened.
            let main_flattened = program_ast
                .functions
                .iter()
                .find(|x| x.id == "main")
                .unwrap();
            for stat in main_flattened.statements.clone() {
                assert!(
                    stat.is_flattened(),
                    format!("Input conditions not flattened: {}", &stat)
                );
            }

            // print deserialized flattened program
            println!("{}", main_flattened);

            // validate #arguments
            let mut cli_arguments: Vec<FieldPrime> = Vec::new();
            match sub_matches.values_of("arguments"){
                Some(p) => {
                    let arg_strings: Vec<&str> = p.collect();
                    cli_arguments = arg_strings.into_iter().map(|x| FieldPrime::from(x)).collect();
                },
                None => {
                }
            }

            // handle interactive and non-interactive modes
            let is_interactive = sub_matches.occurrences_of("interactive") > 0;

            // in interactive mode, only public inputs are expected
            let expected_cli_args_count = main_flattened.arguments.iter().filter(|x| !(x.private && is_interactive)).count();

            if cli_arguments.len() != expected_cli_args_count {
                println!("Wrong number of arguments. Given: {}, Required: {}.", cli_arguments.len(), expected_cli_args_count);
                std::process::exit(1);
            }

            let mut cli_arguments_iter = cli_arguments.into_iter();
            let arguments = main_flattened.arguments.clone().into_iter().map(|x| {
                match x.private && is_interactive {
                    // private inputs are passed interactively when the flag is present
                    true => {
                        println!("Please enter a value for {:?}:", x.id);
                        let mut input = String::new();
                        let stdin = stdin();
                        stdin
                            .lock()
                            .read_line(&mut input)
                            .expect("Did not enter a correct String");
                        FieldPrime::from(input.trim())
                    }
                    // otherwise, they are taken from the CLI arguments
                    false => {
                        match cli_arguments_iter.next() {
                            Some(x) => x,
                            None => {
                                std::process::exit(1);
                            }
                        }
                    }
                }
            }).collect();

            let witness_map = main_flattened.get_witness(arguments);
            // let witness_map: HashMap<String, FieldPrime> = main_flattened.get_witness(args);
            println!("Witness: {:?}", witness_map);

            // write witness to file
            let output_path = Path::new(sub_matches.value_of("output").unwrap());
            let output_file = match File::create(&output_path) {
                Ok(file) => file,
                Err(why) => panic!("couldn't create {}: {}", output_path.display(), why),
            };
            let mut bw = BufWriter::new(output_file);
            for (var, val) in &witness_map {
                // println!("{}:{:?}",var, val.to_dec_string());
                write!(&mut bw, "{} {}\n", var, val.to_dec_string()).expect("Unable to write data to file.");
            }
            bw.flush().expect("Unable to flush buffer.");
        }
        ("setup", Some(sub_matches)) => {
            println!("Performing setup...");

            let path = Path::new(sub_matches.value_of("input").unwrap());
            let mut file = match File::open(&path) {
                Ok(file) => file,
                Err(why) => panic!("couldn't open {}: {}", path.display(), why),
            };

            let program_ast: Prog<FieldPrime> = match deserialize_from(&mut file, Infinite) {
                Ok(x) => x,
                Err(why) => {
                    println!("{:?}", why);
                    std::process::exit(1);
                }
            };

            // make sure the input program is actually flattened.
            let main_flattened = program_ast
                .functions
                .iter()
                .find(|x| x.id == "main")
                .unwrap();
            for stat in main_flattened.statements.clone() {
                assert!(
                    stat.is_flattened(),
                    format!("Input conditions not flattened: {}", &stat)
                );
            }

            // print deserialized flattened program
            println!("{}", main_flattened);

            // transform to R1CS
            let (variables, private_inputs_offset, a, b, c) = r1cs_program(&program_ast);

            // write variables meta information to file
            let var_inf_path = Path::new(sub_matches.value_of("meta-information").unwrap());
            let var_inf_file = match File::create(&var_inf_path) {
                Ok(file) => file,
                Err(why) => panic!("couldn't open {}: {}", var_inf_path.display(), why),
            };
            let mut bw = BufWriter::new(var_inf_file);
                write!(&mut bw, "Private inputs offset:\n{}\n", private_inputs_offset).expect("Unable to write data to file.");
                write!(&mut bw, "R1CS variable order:\n").expect("Unable to write data to file.");
            for var in &variables {
                write!(&mut bw, "{} ", var).expect("Unable to write data to file.");
            }
            write!(&mut bw, "\n").expect("Unable to write data to file.");
            bw.flush().expect("Unable to flush buffer.");


            // get paths for proving and verification keys
            let pk_path = sub_matches.value_of("proving-key-path").unwrap();
            let vk_path = sub_matches.value_of("verification-key-path").unwrap();

            // run setup phase
            #[cfg(not(feature="nolibsnark"))]{
                // number of inputs in the zkSNARK sense, i.e., input variables + output variables
                let num_inputs = main_flattened.arguments.iter().filter(|x| !x.private).count() + main_flattened.return_count;
                println!("setup successful: {:?}", setup(variables, a, b, c, num_inputs, pk_path, vk_path));
            }
        }
        ("export-verifier", Some(sub_matches)) => {
            println!("Exporting verifier...");
            // read vk file
            let input_path = Path::new(sub_matches.value_of("input").unwrap());
            let input_file = match File::open(&input_path) {
                Ok(input_file) => input_file,
                Err(why) => panic!("couldn't open {}: {}", input_path.display(), why),
            };
            let reader = BufReader::new(input_file);
            let mut lines = reader.lines();

            let mut template_text = String::from(CONTRACT_TEMPLATE);
            let ic_template = String::from("vk.IC[index] = Pairing.G1Point(points);");      //copy this for each entry

            //replace things in template
            let vk_regex = Regex::new(r#"(<%vk_[^i%]*%>)"#).unwrap();
            let vk_ic_len_regex = Regex::new(r#"(<%vk_ic_length%>)"#).unwrap();
            let vk_ic_index_regex = Regex::new(r#"index"#).unwrap();
            let vk_ic_points_regex = Regex::new(r#"points"#).unwrap();
            let vk_ic_repeat_regex = Regex::new(r#"(<%vk_ic_pts%>)"#).unwrap();
            let vk_input_len_regex = Regex::new(r#"(<%vk_input_length%>)"#).unwrap();

            for _ in 0..7 {
                let current_line: String = lines.next().expect("Unexpected end of file in verification key!").unwrap();
                let current_line_split: Vec<&str> = current_line.split("=").collect();
                assert_eq!(current_line_split.len(), 2);
                template_text = vk_regex.replace(template_text.as_str(), current_line_split[1].trim()).into_owned();
            }

            let current_line: String = lines.next().expect("Unexpected end of file in verification key!").unwrap();
            let current_line_split: Vec<&str> = current_line.split("=").collect();
            assert_eq!(current_line_split.len(), 2);
            let ic_count: i32 = current_line_split[1].trim().parse().unwrap();

            template_text = vk_ic_len_regex.replace(template_text.as_str(), format!("{}", ic_count).as_str()).into_owned();
            template_text = vk_input_len_regex.replace(template_text.as_str(), format!("{}", ic_count-1).as_str()).into_owned();

            let mut ic_repeat_text = String::new();
            for x in 0..ic_count {
                let mut curr_template = ic_template.clone();
                let current_line: String = lines.next().expect("Unexpected end of file in verification key!").unwrap();
                let current_line_split: Vec<&str> = current_line.split("=").collect();
                assert_eq!(current_line_split.len(), 2);
                curr_template = vk_ic_index_regex.replace(curr_template.as_str(), format!("{}", x).as_str()).into_owned();
                curr_template = vk_ic_points_regex.replace(curr_template.as_str(), current_line_split[1].trim()).into_owned();
                ic_repeat_text.push_str(curr_template.as_str());
                if x < ic_count - 1 {
                    ic_repeat_text.push_str("\n        ");
                }
            }
            template_text = vk_ic_repeat_regex.replace(template_text.as_str(), ic_repeat_text.as_str()).into_owned();

            //write output file
            let output_path = Path::new(sub_matches.value_of("output").unwrap());
            let mut output_file = match File::create(&output_path) {
                Ok(file) => file,
                Err(why) => panic!("couldn't create {}: {}", output_path.display(), why),
            };
            output_file.write_all(&template_text.as_bytes()).expect("Failed writing output to file.");
            println!("Finished exporting verifier.");
        }
        ("generate-proof", Some(sub_matches)) => {
            println!("Generating proof...");

            // deserialize witness
            let witness_path = Path::new(sub_matches.value_of("witness").unwrap());
            let witness_file = match File::open(&witness_path) {
                Ok(file) => file,
                Err(why) => panic!("couldn't open {}: {}", witness_path.display(), why),
            };

            let reader = BufReader::new(witness_file);
            let mut lines = reader.lines();
            let mut witness_map = HashMap::new();

            loop {
                match lines.next() {
                    Some(Ok(ref x)) => {
                        let pairs: Vec<&str> = x.split_whitespace().collect();
                        witness_map.insert(pairs[0].to_string(),FieldPrime::from_dec_string(pairs[1].to_string()));
                    },
                    None => break,
                    Some(Err(err)) => panic!("Error reading witness: {}", err),
                }
            }

            // determine variable order
            let var_inf_path = Path::new(sub_matches.value_of("meta-information").unwrap());
            let var_inf_file = match File::open(&var_inf_path) {
                Ok(file) => file,
                Err(why) => panic!("couldn't open {}: {}", var_inf_path.display(), why),
            };
            let var_reader = BufReader::new(var_inf_file);
            let mut var_lines = var_reader.lines();

            // get private inputs offset
            let private_inputs_offset;
            if let Some(Ok(ref o)) = var_lines.nth(1){ // consumes first 2 lines
                private_inputs_offset = o.parse().expect("Failed parsing private inputs offset");
            } else {
                panic!("Error reading private inputs offset");
            }

            // get variables vector
            let mut variables: Vec<String> = Vec::new();
            if let Some(Ok(ref v)) = var_lines.nth(1){
                let iter = v.split_whitespace();
                for i in iter {
                        variables.push(i.to_string());
                }
            } else {
                panic!("Error reading variables.");
            }

            println!("Using Witness: {:?}", witness_map);

            let witness: Vec<_> = variables.iter().map(|x| witness_map[x].clone()).collect();

            // split witness into public and private inputs at offset
            let mut public_inputs: Vec<_>= witness.clone();
            let private_inputs: Vec<_> = public_inputs.split_off(private_inputs_offset);

            println!("Public inputs: {:?}", public_inputs);
            println!("Private inputs: {:?}", private_inputs);

            let pk_path = sub_matches.value_of("provingkey").unwrap();

            // run libsnark
            #[cfg(not(feature="nolibsnark"))]{
                println!("generate-proof successful: {:?}", generate_proof(pk_path, public_inputs, private_inputs));
            }

        }
        _ => unimplemented!(), // Either no subcommand or one not tested for...
    }

}

#[cfg(test)]
mod tests {
    extern crate glob;
    use super::*;
    use num::Zero;
    use self::glob::glob;

    #[test]
    fn examples() {
        for p in glob("./examples/*.code").expect("Failed to read glob pattern") {
            let path = match p {
                Ok(x) => x,
                Err(why) => panic!("Error: {:?}", why),
            };

            println!("Testing {:?}", path);

            let program_flattened: Prog<FieldPrime> =
                compile(path, false).unwrap();

            let (..) = r1cs_program(&program_flattened);
        }
    }

    #[test]
    fn examples_with_input() {
        for p in glob("./examples/test*.code").expect("Failed to read glob pattern") {
            let path = match p {
                Ok(x) => x,
                Err(why) => panic!("Error: {:?}", why),
            };
            println!("Testing {:?}", path);

            let program_flattened: Prog<FieldPrime> =
                compile(path, false).unwrap();

            let (..) = r1cs_program(&program_flattened);
            let _ = program_flattened.get_witness(vec![FieldPrime::zero()]);
        }
    }
}
