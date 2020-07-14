package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.property.model.AtomicFormula
import hu.bme.mit.gamma.property.model.PathQuantifier
import hu.bme.mit.gamma.property.model.QuantifiedFormula
import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.property.model.UnaryOperandPathFormula
import hu.bme.mit.gamma.property.model.UnaryPathOperator

import static com.google.common.base.Preconditions.checkArgument

class ThetaPropertySerializer extends PropertySerializer {
	// Singleton
	public static final ThetaPropertySerializer INSTANCE = new ThetaPropertySerializer
	protected new() {
		super(new PropertyExpressionSerializer(ThetaReferenceSerializer.INSTANCE))
	}
	//
	
	override serialize(StateFormula formula) {
		// A simple CTL
		val serializedFormula = formula.serializeFormula
		checkArgument(formula.isSimpleCTL, serializedFormula)
		return serializedFormula
	}
	
	protected def isSimpleCTL(StateFormula formula) {
		if (formula instanceof QuantifiedFormula) {
			// A or E
			val quantifier = formula.quantifier
			val quantifiedFormula = formula.formula
			if (quantifiedFormula instanceof UnaryOperandPathFormula) {
				val operator = quantifiedFormula.operator
				val pathFormula = quantifiedFormula.operand
				if (quantifier == PathQuantifier.FORALL && operator == UnaryPathOperator.GLOBAL ||
						quantifier == PathQuantifier.EXISTS && operator == UnaryPathOperator.FUTURE) {
					// AG or EF
					if (pathFormula instanceof AtomicFormula) {
						return true
					}
				}
			}
		}
		return false
	}

	def dispatch String serializeFormula(AtomicFormula formula) {
		return formula.expression.serialize
	}
	
	def dispatch String serializeFormula(QuantifiedFormula formula) {
		val quantifier = formula.quantifier
		val pathFormula = formula.formula
		return '''«quantifier.transform»«pathFormula.serializeFormula»'''
	}
	
	def dispatch String serializeFormula(UnaryOperandPathFormula formula) {
		val operator = formula.operator
		val operand = formula.operand
		return '''«operator.transform» «operand.serializeFormula»'''
	}
	
	// Other CTL* formula expressions are not supported by UPPAAL
	
	def String transform(UnaryPathOperator operator) {
		switch (operator) {
			case FUTURE: {
				return '''<>'''
			}
			case GLOBAL: {
				return '''[]'''
			}
			default: 
				throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
	def String transform(PathQuantifier quantifier) {
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