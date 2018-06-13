
use std::collections::{BTreeMap, HashSet};
use flat_absy::{FlatStatement, FlatExpression, FlatFunction, FlatExpressionList};
use field::Field;
use executable::Sha256Libsnark;
use parameter::Parameter;

// for r1cs import, can be moved.
// r1cs data strucutre reflecting JSON standard format:
//{variables:["a","b", ... ],
//constraints:[
// [{offset_1:value_a1,offset2:value_a2,...},{offset1:value_b1,offset2:value_b2,...},{offset1:value_c1,offset2:value_c2,...}]
//]}
#[derive(Serialize, Deserialize, Debug)]
pub struct R1CS {
	pub input_count: usize, // # of inputs to pass
	pub outputs: Vec<usize>, // indices of the outputs in the witness
    pub constraints: Vec<Constraint>, // constraints verified by the witness
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Witness {
    pub variables: Vec<usize>
}

#[derive(Serialize, Deserialize, Debug, PartialEq)]
pub struct Constraint {
	a: BTreeMap<String, String>,
	b: BTreeMap<String, String>,
	c: BTreeMap<String, String>,
}

impl<T: Field> Into<FlatStatement<T>> for Constraint {
	fn into(self: Constraint) -> FlatStatement<T> {
		let lhs_a = self.a.iter()
			.map(|(key, val)| FlatExpression::Mult(box FlatExpression::Number(T::from_dec_string(val.to_string())), box FlatExpression::Identifier(format!("inter{}",key.clone()))))
			.fold(FlatExpression::Number(T::zero()), |acc, e| FlatExpression::Add(box acc, box e));
		
		let lhs_b = self.b.iter()
			.map(|(key, val)| FlatExpression::Mult(box FlatExpression::Number(T::from_dec_string(val.to_string())), box FlatExpression::Identifier(format!("inter{}",key.clone()))))
			.fold(FlatExpression::Number(T::zero()), |acc, e| FlatExpression::Add(box acc, box e));
		
		let rhs = self.c.iter()
			.map(|(key, val)| FlatExpression::Mult(box FlatExpression::Number(T::from_dec_string(val.to_string())), box FlatExpression::Identifier(format!("inter{}",key.clone()))))
			.fold(FlatExpression::Number(T::zero()), |acc, e| FlatExpression::Add(box acc, box e));

		FlatStatement::Condition(FlatExpression::Mult(box lhs_a, box lhs_b), rhs)
	}
}

impl<T: Field> Into<FlatFunction<T>> for R1CS {
	fn into(self: R1CS) -> FlatFunction<T> {

		// determine the number of variables, assuming there is no i so that column i is only zeroes in a, b and c
        let mut variables_set = HashSet::new();
        for constraint in self.constraints.iter() {
        	for (key, _) in &constraint.a {
        		variables_set.insert(key.clone());
        	}
        	for (key, _) in &constraint.b {
        		variables_set.insert(key.clone());
        	}
        	for (key, _) in &constraint.c {
        		variables_set.insert(key.clone());
        	}
        }

        let variables_count = variables_set.len();

		// insert flattened statements to represent constraints
        let mut statements: Vec<FlatStatement<T>> = self.constraints.into_iter().map(|c| c.into()).collect();

        // define the entire witness
        let variables = vec![0; variables_count].iter().enumerate().map(|(i, _)| format!("inter{}", i)).collect();

        // define the inputs with dummy variables: arguments to the function and to the directive
        let inputs: Vec<String> = vec![0; self.input_count].iter().enumerate().map(|(i, _)| format!("input{}", i)).collect();
        let input_parameters = inputs.iter().map(|i| Parameter { id: i.clone(), private: true }).collect();

        // define which subset of the witness is returned
        let outputs: Vec<FlatExpression<T>> = self.outputs.iter()
         				.map(|o| FlatExpression::Identifier(format!("inter{}", o))).collect();

        let return_count = outputs.len();

        // insert a directive to set the witness based on the inputs
        statements.insert(0, FlatStatement::Directive(variables, inputs, Sha256Libsnark::new(self.input_count, variables_count)));

        // insert a statement to return the subset of the witness
        statements.push(FlatStatement::Return(
        	FlatExpressionList {
        		expressions: outputs
         	})
        );
        
        FlatFunction { 
            id: "main".to_owned(), 
            arguments: input_parameters, 
            statements: statements, 
            return_count: return_count
        }
	}
} 

#[cfg(test)]
mod tests {
	use super::*;
	use field::FieldPrime;
	use serde_json;

	#[test]
	fn deserialize_constraint() {
		let constraint = r#"[{"2026": "1"}, {"0": "1", "2026": "1751751751751751751751751751751751751751751"}, {"0": "0"}]"#;
		let _c: Constraint = serde_json::from_str(constraint).unwrap();
	}

	#[test]
	fn constraint_into_flat_statement() {
		let constraint = r#"[{"2026": "1"}, {"0": "1", "2026": "1751751751751751751751751751751751751751751"}, {"0": "0"}]"#;
		let c: Constraint = serde_json::from_str(constraint).unwrap();
		let _statement: FlatStatement<FieldPrime> = c.into();
	}
}

