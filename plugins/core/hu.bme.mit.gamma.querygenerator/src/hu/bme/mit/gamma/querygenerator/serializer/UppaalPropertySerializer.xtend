package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.property.model.AtomicFormula
import hu.bme.mit.gamma.property.model.BinaryOperandPathFormula
import hu.bme.mit.gamma.property.model.QuantifiedFormula
import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.property.model.UnaryOperandPathFormula

class UppaalPropertySerializer implements PropertySerializer {
	// Singleton
	public static final ThetaPropertySerializer INSTANCE = new ThetaPropertySerializer
	protected new() {}
	//
	
	protected extension PropertyExpressionSerializer serializer =
		new PropertyExpressionSerializer(ThetaReferenceSerializer.INSTANCE) 
	
	override serialize(StateFormula formula) {
		formula.validate
		return formula.serializeFormula
	}
	
	protected def void validate(StateFormula formula) {
		
	}

	def dispatch String serializeFormula(AtomicFormula formula) {
		return formula.expression.serialize
	}
	
	def dispatch String serializeFormula(QuantifiedFormula formula) {
		val quantifier = formula.quantifier
		val pathFormula = formula.formula
		return '''«quantifier.literal»«pathFormula.serializeFormula»'''
	}
	
	def dispatch String serializeFormula(UnaryOperandPathFormula formula) {
		val operator = formula.operator
		val operand = formula.operand
		return '''«operator.literal» «operand.serializeFormula»'''
	}
	
	def dispatch String serializeFormula(BinaryOperandPathFormula formula) {
		val operator = formula.operator
		val left = formula.leftOperand
		val right = formula.rightOperand
		return '''«left.serializeFormula» «operator.literal» «right.serializeFormula»'''
	}
	
}