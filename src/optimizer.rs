//! Module containing the `Optimizer` to optimize a flattened program.
//!
//! @file optimizer.rs
//! @author Dennis Kuhnert <dennis.kuhnert@campus.tu-berlin.de>
//! @author Jacob Eberhardt <jacob.eberhardt@tu-berlin.de>
//! @date 2017

use absy::*;
use field::Field;
use std::collections::{HashMap};

pub struct Optimizer {
	/// Map of renamings for reassigned variables while processing the program.
	substitution: HashMap<String,String>,
	/// Index of the next introduced variable while processing the program.
	next_var_idx: Counter
}

pub struct Counter {
	value: usize
}

impl Counter {
	fn increment(&mut self) -> usize {
		let index = self.value;
		self.value = self.value + 1;
		index
	}
}

impl Optimizer {
	pub fn new() -> Optimizer {
		Optimizer {
			substitution: HashMap::new(),
    		next_var_idx: Counter {
    			value: 0
    		}
		}
	}

	pub fn optimize_program<T: Field>(&mut self, prog: Prog<T>) -> Prog<T> {
		let optimized_program = Prog {
			functions: prog.functions.into_iter().filter_map(|func| {
				if func.id == "main" {
					return Some(self.optimize_function(func));
				}
				return None;
			}).collect()
		};
		optimized_program
	}

	pub fn optimize_function<T: Field>(&mut self, funct: Function<T>) -> Function<T> {

		// Add arguments to substitution map
		for arg in &funct.arguments {
			self.substitution.insert(arg.id.clone(), format!("_{}", self.next_var_idx.increment()));
		};

		// generate substitution map
		//
		//	(b = a, c = b) => ( b -> a, c -> a )
		// The first variable to appear is used for its synonyms.

		for statement in &funct.statements {
			match *statement {
				// Synonym definition
				// if the right side of the assignment is already being reassigned to `x`,
				// reassign the left side to `x` as well, otherwise reassign to a new variable
				Statement::Definition(ref left, Expression::Identifier(ref right)) => {
					let r = match self.substitution.get(right) {
						Some(value) => {
							value.clone()
						},
						None => {
							format!("_{}", self.next_var_idx.increment())
						}
					};
					self.substitution.insert(left.clone(), r);
				},
				// Other definitions
				Statement::Definition(ref left, _) => {
					self.substitution.insert(left.clone(), format!("_{}", self.next_var_idx.increment()));
				},
				// Compiler statements introduce variables before they are defined, so add them to the substitution
				Statement::Compiler(ref id, _) => {
					self.substitution.insert(id.clone(), format!("_{}", self.next_var_idx.increment()));
				},
				_ => ()
			}
		}

		// generate optimized statements by removing synonym declarations and renaming variables
		let optimized_statements = funct.statements.iter().filter_map(|statement| {
			match *statement {
				// filter out synonyms definitions
				Statement::Definition(_, Expression::Identifier(_)) => {
					None
				},
				// substitute all other statements
				_ => {
					Some(statement.apply_substitution(&self.substitution))
				}
			}
		}).collect();

		// generate optimized arguments by renaming them
		let optimized_arguments = funct.arguments.iter().map(|arg| arg.apply_substitution(&self.substitution)).collect();

		// clone function
		let mut optimized_funct = funct.clone();
		// update statements with optimized ones
		optimized_funct.statements = optimized_statements;
		optimized_funct.arguments = optimized_arguments;

		optimized_funct
	}
}

#[cfg(test)]
mod tests {
	use super::*;
	use field::FieldPrime;

	#[test]
	fn remove_synonyms() {
		let f: Function<FieldPrime> = Function {
            id: "foo".to_string(),
            arguments: vec![Parameter {id: "a".to_string(), private: false}],
            statements: vec![
            	Statement::Definition("b".to_string(), Expression::Identifier("a".to_string())),
            	Statement::Definition("c".to_string(), Expression::Identifier("b".to_string())),
            	Statement::Return(ExpressionList {
            		expressions: vec![Expression::Identifier("c".to_string())]
            	})
            ],
            return_count: 1
        };

        let optimized: Function<FieldPrime> = Function {
            id: "foo".to_string(),
        	arguments: vec![Parameter {id: "_0".to_string(), private: false}],
        	statements: vec![
        		Statement::Return(ExpressionList {
            		expressions: vec![Expression::Identifier("_0".to_string())]
            	})
        	],
        	return_count: 1
        };

        let mut optimizer = Optimizer::new();
        assert_eq!(optimizer.optimize_function(f), optimized);
	}


	#[test]
	fn remove_multiple_synonyms() {
		let f: Function<FieldPrime> = Function {
            id: "foo".to_string(),
            arguments: vec![Parameter {id: "a".to_string(), private: false}],
            statements: vec![
            	Statement::Definition("b".to_string(), Expression::Identifier("a".to_string())),
            	Statement::Definition("d".to_string(), Expression::Number(FieldPrime::from(1))),
            	Statement::Definition("c".to_string(), Expression::Identifier("b".to_string())),
            	Statement::Definition("e".to_string(), Expression::Identifier("d".to_string())),
            	Statement::Return(ExpressionList {
            		expressions: vec![Expression::Identifier("c".to_string()), Expression::Identifier("e".to_string())]
            	})
            ],
            return_count: 2
        };

        let optimized: Function<FieldPrime> = Function {
            id: "foo".to_string(),
        	arguments: vec![Parameter {id: "_0".to_string(), private: false}],
        	statements: vec![
            	Statement::Definition("_1".to_string(), Expression::Number(FieldPrime::from(1))),
        		Statement::Return(ExpressionList {
            		expressions: vec![Expression::Identifier("_0".to_string()), Expression::Identifier("_1".to_string())]
            	})
        	],
        	return_count: 2
        };

        let mut optimizer = Optimizer::new();
        assert_eq!(optimizer.optimize_function(f), optimized);
	}
}

["0xd58b5825fc49de27708322ad3b0cbaacfc23e26f483563e32684b46f209f751", "0x14dd424699d230bafc8d3648ffbb870d84e6f8a0c4dc3e6fe097067ae1fa1002"],["0x118ae5f5704fa2c8936acb64be3617db05b1c39794e1c86dd4943e88e918f057", "0x64c0263e854de74773fa575243b40e3cebcf779112fbc4a10a9e385c5e181d2"],[["0x1842d49818286337842779e758f010d001815c6a648a53d3cfadf5259c2d7fe3", "0x13575e1fcf068eb6549d7db36c581c268294f2f9b481ce76ac87022ec5ccae6c"], ["0x7bd2991d49555f578cd45e722c232562f22fb15b695f8d564cc58cc92f46726", "0x1b0a30f650b4d78bb146b5268061260aed1552dc30615c35c4e90d8d4b289368"]],["0x265214081be8a344b3112fb00f4e3fe7e4d44e96a4280836abc6b5f337272d33", "0x6764ff0c6e4e1db68ce38e01016b4425a23450c3969552b6aac130d6ea703ba"],["0x273a17f370e20ad80dbe9b295dc724f2d667c11bb5fae6ae595963d955e6632a", "0x14392ddfa1fa0bd95c4366621d5e614535412b4080a0ffa3d7dec6df916a2ff5"],["0x1b85c5335cd28d419cbd5e53634b0b9b676f2b8896fdcb5849d1cab96469c7d0", "0x18435c034fcecd7992cf871ce4d2cd87beabc4811ee4ad155bf6a52d65763e4e"],["0x15d46eed240f78b63ebeeef1e53c60d7b5e80a5e106cc87afb49ae630e445e2c", "0x1e8431322189b6ca4c33b099b911e9e790cbdf427370c40625a4a63309ce0749"],["0x1fc19522983f12976b2f125f118c0ac8a6863c34fb8728d76dd11f287774acc2", "0xef8fa711c712784d1c27bd3b3a97d5c81eaa1489467ea7300575fb4c73d37cb"],[1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 1]