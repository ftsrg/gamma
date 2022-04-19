package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.property.model.QuantifiedFormula
import hu.bme.mit.gamma.property.model.UnaryOperandPathFormula
import hu.bme.mit.gamma.property.model.UnaryPathOperator
import hu.bme.mit.gamma.property.model.BinaryPathOperator

import static com.google.common.base.Preconditions.checkArgument
import hu.bme.mit.gamma.util.GammaEcoreUtil

class PromelaPropertySerializer extends ThetaPropertySerializer {
	// Singleton
	public static final PromelaPropertySerializer INSTANCE = new PromelaPropertySerializer
	protected new() {
		super.serializer = new PromelaPropertyExpressionSerializer(PromelaReferenceSerializer.INSTANCE)
	}
	//
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	override serialize(StateFormula formula) {
		// A simple LTL
		val serializedFormula = formula.serializeFormula
		checkArgument(formula.isValidFormula, serializedFormula)
		return serializedFormula
	}
	
	override protected isValidFormula(StateFormula stateFormula) {
		val list = stateFormula.getSelfAndAllContentsOfType(QuantifiedFormula)
		if (list.size > 1) {
			return false
		}
		if (stateFormula instanceof QuantifiedFormula) {
			val quantifiedFormula = stateFormula.formula
			if (quantifiedFormula instanceof UnaryOperandPathFormula) {
				val operator = quantifiedFormula.operator
				if (operator == UnaryPathOperator.NEXT) {
					return false
				}
			}
		}
		return true
	}
	
	protected def String transform(BinaryPathOperator operator) {
		switch (operator) {
			case RELEASE: {
				return '''V'''
			}
			case UNTIL: {
				return '''U'''
			}
			default: 
				throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
}