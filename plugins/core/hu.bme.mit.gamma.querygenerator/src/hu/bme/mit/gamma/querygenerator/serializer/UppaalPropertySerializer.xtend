package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.property.model.AtomicFormula
import hu.bme.mit.gamma.property.model.BinaryLogicalOperator
import hu.bme.mit.gamma.property.model.BinaryOperandLogicalPathFormula
import hu.bme.mit.gamma.property.model.PathQuantifier
import hu.bme.mit.gamma.property.model.QuantifiedFormula
import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.property.model.UnaryOperandPathFormula
import hu.bme.mit.gamma.property.model.UnaryPathOperator

import static com.google.common.base.Preconditions.checkArgument
import static hu.bme.mit.gamma.uppaal.util.Namings.*

class UppaalPropertySerializer extends PropertySerializer {
	// Singleton
	public static final UppaalPropertySerializer INSTANCE = new UppaalPropertySerializer
	protected new() {
		super(new PropertyExpressionSerializer(UppaalReferenceSerializer.INSTANCE))
	}
	//
	
	override serialize(StateFormula formula) {
		val leadsToOperands = formula.checkLeadsTo
		if (leadsToOperands !== null) {
			// Either a leads to
			val left = leadsToOperands.key
			val right = leadsToOperands.value
			return '''(«left.serializeFormula») && «isStableVariableName» --> («right.serializeFormula») && «isStableVariableName»'''
		}
		// Or a simple CTL
		val serializedFormula = formula.serializeFormula
		checkArgument(formula.isSimpleCTL, serializedFormula)
		return serializedFormula
	}
	
	protected def isSimpleCTL(StateFormula formula) {
		if (formula instanceof QuantifiedFormula) {
			// A or E
			val quantifiedFormula = formula.formula
			if (quantifiedFormula instanceof UnaryOperandPathFormula) {
				val operator = quantifiedFormula.operator
				val pathFormula = quantifiedFormula.operand
				if (operator == UnaryPathOperator.GLOBAL || operator == UnaryPathOperator.FUTURE) {
					// G or F
					if (pathFormula instanceof AtomicFormula) {
						return true
					}
				}
			}
		}
		return false
	}
	
	protected def checkLeadsTo(StateFormula formula) {
		if (formula instanceof QuantifiedFormula) {
			val quantifier = formula.quantifier
			if (quantifier == PathQuantifier.FORALL) {
				// A
				val quantifiedFormula = formula.formula
				if (quantifiedFormula instanceof UnaryOperandPathFormula) {
					val operator = quantifiedFormula.operator
					val pathFormula = quantifiedFormula.operand
					if (operator == UnaryPathOperator.GLOBAL) {
						// AG
						if (pathFormula instanceof BinaryOperandLogicalPathFormula) {
							val binaryOperator = pathFormula.operator
							if (binaryOperator == BinaryLogicalOperator.IMPLY) {
								// AG (... -> ...)
								val left = pathFormula.leftOperand
								val right = pathFormula.rightOperand
								if (left instanceof AtomicFormula) {
									// AG (atomic -> ...)
									if (right instanceof QuantifiedFormula) {
										val rightQuantifier = right.quantifier
										if (rightQuantifier == PathQuantifier.FORALL) {
											// AG (atomic -> A ...)
											val rightPathFormula = right.formula
											if (rightPathFormula instanceof UnaryOperandPathFormula) {
												val rightOperator = rightPathFormula.operator
												val rightFormula = rightPathFormula.operand
												if (rightOperator == UnaryPathOperator.FUTURE) {
													// AG (atomic -> AF ...)
													if (rightFormula instanceof AtomicFormula) {
														// AG (atomic -> AF atomic)
														return new Pair(left, rightFormula)
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
		return null
	}

	protected def dispatch String serializeFormula(AtomicFormula formula) {
		return formula.expression.serialize
	}
	
	protected def dispatch String serializeFormula(QuantifiedFormula formula) {
		val quantifier = formula.quantifier
		val pathFormula = formula.formula
		return '''«quantifier.transform»«pathFormula.serializeFormula»'''
	}
	
	protected def dispatch String serializeFormula(UnaryOperandPathFormula formula) {
		val operator = formula.operator
		val operand = formula.operand
		return '''«operator.transform» («operand.serializeFormula») «operator.addIsStable»'''
	}
	
	// Other CTL* formula expressions are not supported by UPPAAL
	
	protected def String transform(UnaryPathOperator operator) {
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
	
	protected def String transform(PathQuantifier quantifier) {
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
	
	protected def String addIsStable(UnaryPathOperator operator) {
		switch (operator) {
			case FUTURE: {
				return '''&& «isStableVariableName»'''
			}
			case GLOBAL: {
				return '''|| !«isStableVariableName»'''
			}
			default: 
				throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
}