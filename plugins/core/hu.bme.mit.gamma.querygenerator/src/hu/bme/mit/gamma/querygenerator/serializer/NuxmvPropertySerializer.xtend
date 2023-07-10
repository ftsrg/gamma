package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.property.model.BinaryOperandLogicalPathFormula
import hu.bme.mit.gamma.property.model.UnaryPathOperator
import hu.bme.mit.gamma.property.model.PathQuantifier
import hu.bme.mit.gamma.property.model.BinaryPathOperator

class NuxmvPropertySerializer extends ThetaPropertySerializer {
	//TODO
	public static final NuxmvPropertySerializer INSTANCE = new NuxmvPropertySerializer
	protected new() {
		super.serializer = new NuxmvPropertyExpressionSerializer(NuxmvReferenceSerializer.INSTANCE)
	}
	
	dispatch def String serializeFormula(BinaryOperandLogicalPathFormula formula) {
		val operator = formula.operator
		val leftOperand = formula.leftOperand.serializeFormula
		val rightOperand = formula.rightOperand.serializeFormula
		return switch (operator) {
			case AND: {
				'''(«leftOperand» & «rightOperand»)'''
			}
			case IMPLY: {
				'''((«leftOperand») -> («rightOperand»))'''
			}
			case OR: {
				'''(«leftOperand» | «rightOperand»)'''
			}
			case XOR: {
				'''((«leftOperand») xor («rightOperand»))'''
			}
			default: 
				throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
	protected override String transform(UnaryPathOperator operator) {
		switch (operator) {
			case FUTURE: {
				return '''F'''
			}
			case GLOBAL: {
				return '''G'''
			}
			case NEXT: {
				return '''X'''
			}
			default: 
				/* nuXmv supports several other path operators, but only the above ones are supported for now.
				 * See the nuXmv manual for more information.
				 * Y ltl_expr -- previous state
				 * O ltl_expr -- once
				 * H ltl_expr -- historically
				 */ 
				throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
	protected def String transform(BinaryPathOperator operator) {
		switch (operator) {
			case UNTIL: {
				return '''U'''
			}
			case RELEASE: {
				return '''V'''
			}
			default: 
				/* nuXmv supports several other path operators, but only the above ones are supported for now.
				 * See the nuXmv manual for more information.
				 * ltl_expr S ltl_expr -- since
				 * ltl_expr T ltl_expr -- triggered
				 */
				throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
	protected override String transform(PathQuantifier quantifier) {
		switch (quantifier) {
			case FORALL: {
				return '''A'''
			}
			case EXISTS: {
				return '''E'''
			}
			default: 
				throw new IllegalArgumentException("Not supported quantifier: " + quantifier)
		}
	}
}