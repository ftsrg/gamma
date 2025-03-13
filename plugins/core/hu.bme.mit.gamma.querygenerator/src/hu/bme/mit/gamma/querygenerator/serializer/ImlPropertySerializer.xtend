/********************************************************************************
 * Copyright (c) 2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.Comment
import hu.bme.mit.gamma.property.model.AtomicFormula
import hu.bme.mit.gamma.property.model.BinaryLogicalOperator
import hu.bme.mit.gamma.property.model.BinaryOperandPathFormula
import hu.bme.mit.gamma.property.model.PathFormula
import hu.bme.mit.gamma.property.model.PathQuantifier
import hu.bme.mit.gamma.property.model.QuantifiedFormula
import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.property.model.TemporalPathFormula
import hu.bme.mit.gamma.property.model.UnaryLogicalOperator
import hu.bme.mit.gamma.property.model.UnaryOperandPathFormula
import hu.bme.mit.gamma.property.model.UnaryPathOperator
import hu.bme.mit.gamma.xsts.iml.transformation.util.Namings

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.property.derivedfeatures.PropertyModelDerivedFeatures.*

class ImlPropertySerializer extends ThetaPropertySerializer {
	//
	public static final ImlPropertySerializer INSTANCE = new ImlPropertySerializer
	protected new() {
		super.serializer = new ImlPropertyExpressionSerializer(ImlReferenceSerializer.INSTANCE)
	}
	//
	
	protected override isValidFormula(StateFormula formula) {
		return formula.ltl
	}
	
	override serialize(Comment comment) '''(* «comment.comment» *)'''
	
	override serialize(StateFormula formula) {
		val nnfFormula = formula.createNegationNormalForm
		
		val serializedFormula = nnfFormula.serializeFormula
		
		if (!formula.helperEquals(nnfFormula)) {
			logger.info("Transformed property into negation normal form (NNF): " + serializedFormula)
		}
		checkArgument(nnfFormula.validFormula, "Unsupported property specification: " + serializedFormula)
		
		return serializedFormula
	}
	
	//
	
	protected override dispatch String serializeFormula(AtomicFormula formula) {
		return formula.expression.serialize
	}
	
	protected override dispatch String serializeFormula(QuantifiedFormula formula) {
		val quantifier = formula.quantifier // A or E
		val imandraCall = (quantifier == PathQuantifier.FORALL) ? "verify" : "instance"
		val singlePathConstraintOperator = (quantifier == PathQuantifier.FORALL) ? "==>" : "&&"
		
		val pathFormula = formula.formula
		val inputtableFormulas = formula.relevantTemporalPathFormulas
		return '''«imandraCall»(fun«FOR e : inputtableFormulas» «e.inputId»«ENDFOR» -> («
				formula.singlePathConstraint») «singlePathConstraintOperator» let «
				recordId» = «Namings.INIT_FUNCTION_IDENTIFIER» in «pathFormula.serializeFormula»)'''
	}
	
	protected override dispatch String serializeFormula(UnaryOperandPathFormula formula) {
		val operator = formula.operator // G, F or X
		val operand = formula.operand
		if (formula.isAQuantifiedTransitively) {
			return switch (operator) {
				case NEXT: '''let «recordId» = «Namings.SINGLE_RUN_FUNCTION_IDENTIFIER» «recordId» «formula.inputId» in «operand.serializeFormula»'''
				case GLOBAL: '''let «recordId» = «Namings.RUN_FUNCTION_IDENTIFIER» «recordId» «formula.inputId» in «operand.serializeFormula»'''
				case FUTURE: '''((«endsInLoopName» «recordId» «formula.inputId») ==> «
						existsRealPrefixName» «recordId» «formula.inputId» (fun «recordId» -> «operand.serializeFormula»))'''
				default: throw new IllegalArgumentException("Not supported operator")
			}
		}
		else { // E
			return switch (operator) {
				case NEXT: '''let «recordId» = «Namings.SINGLE_RUN_FUNCTION_IDENTIFIER» «recordId» «formula.inputId» in «operand.serializeFormula»'''
				case FUTURE: '''let «recordId» = «Namings.RUN_FUNCTION_IDENTIFIER» «recordId» «formula.inputId» in «operand.serializeFormula»'''
				case GLOBAL: '''((«endsInLoopName» «recordId» «formula.inputId») ==> «
						forallRealPrefixName» «recordId» «formula.inputId» (fun «recordId» -> «operand.serializeFormula»))'''
				default: throw new IllegalArgumentException("Not supported operator")
			}
		}
	}
	
	protected override dispatch String serializeFormula(BinaryOperandPathFormula formula) {
		val operator = formula.operator
		val lhsOperand = formula.leftOperand
		val rhsOperand = formula.rightOperand
		if (formula.isAQuantifiedTransitively) {
			return switch (operator) {
				case RELEASE:
					'''((let «recordId» = «Namings.RUN_FUNCTION_IDENTIFIER» «recordId» «
							formula.inputId» in «rhsOperand.serializeFormula») || («
								existsPrefixName» «recordId» «formula.inputId» (fun «recordId» -> «lhsOperand.serializeFormula» && «rhsOperand.serializeFormula»)))'''
				case WEAK_UNTIL:
					'''((let «recordId» = «Namings.RUN_FUNCTION_IDENTIFIER» «recordId» «
							formula.inputId» in «lhsOperand.serializeFormula») || («
								existsPrefixName» «recordId» «formula.inputId» (fun «recordId» -> «rhsOperand.serializeFormula»)))'''
				case UNTIL:
					'''((«endsInLoopName» «recordId» «formula.inputId») ==> let _«recordId» = «recordId» in «
							existsRealPrefixName» «recordId» «formula.inputId» (fun «recordId» -> «rhsOperand.serializeFormula» && («
								forallRealPrefixName» _«recordId» («EPrefixLeadingToName» _«recordId» «formula.inputId» «recordId») (fun «recordId» -> «lhsOperand.serializeFormula»))))'''
				case STRONG_RELEASE:
					'''((«endsInLoopName» «recordId» «formula.inputId») ==> let _«recordId» = «recordId» in «
							existsRealPrefixName» «recordId» «formula.inputId» (fun «recordId» -> «lhsOperand.serializeFormula» && «rhsOperand.serializeFormula» && («
								forallRealPrefixName» _«recordId» («EPrefixLeadingToName» _«recordId» «formula.inputId» «recordId») (fun «recordId» -> «rhsOperand.serializeFormula»))))'''
				default: throw new IllegalArgumentException("Not supported operator: " + operator)
			}
		}
		else { // E
			return switch (operator) {
				case UNTIL:
					'''((let «recordId» = «Namings.RUN_FUNCTION_IDENTIFIER» «recordId» «
							formula.inputId» in «rhsOperand.serializeFormula») && («
								forallRealPrefixName» «recordId» «formula.inputId» (fun «recordId» -> «lhsOperand.serializeFormula»)))'''
				case STRONG_RELEASE:
					'''((let «recordId» = «Namings.RUN_FUNCTION_IDENTIFIER» «recordId» «
							formula.inputId» in («lhsOperand.serializeFormula» && «rhsOperand.serializeFormula»)) && («
								forallRealPrefixName» «recordId» «formula.inputId» (fun «recordId» -> «rhsOperand.serializeFormula»)))'''
				case RELEASE:
					'''((«endsInLoopName» «recordId» «formula.inputId») ==> let _«recordId» = «recordId» in «
							forallRealPrefixName» «recordId» «formula.inputId» (fun «recordId» -> «rhsOperand.serializeFormula» || («
								existsPrefixName» _«recordId» («EPrefixLeadingToName» _«recordId» «formula.inputId» «recordId») (fun «recordId» -> «lhsOperand.serializeFormula» && «rhsOperand.serializeFormula»))))'''
				case WEAK_UNTIL:
					'''((«endsInLoopName» «recordId» «formula.inputId») ==> let _«recordId» = «recordId» in «
							forallRealPrefixName» «recordId» «formula.inputId» (fun «recordId» -> «lhsOperand.serializeFormula» || («
								existsPrefixName» _«recordId» («EPrefixLeadingToName» _«recordId» «formula.inputId» «recordId») (fun «recordId» -> «rhsOperand.serializeFormula»))))'''
				default: throw new IllegalArgumentException("Not supported operator: " + operator)
			}
		}
	}
	
	//
	
	protected override transform(UnaryLogicalOperator operator) {
		switch (operator) {
			case NOT: "not"
			default: throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
	protected override transform(BinaryLogicalOperator operator) {
		switch (operator) {
			case AND: "&&"
			case IMPLY: "==>"
			case OR: "||"
			case XOR: "<>"
			default: throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
	//
	
//	protected def tailorFormula(QuantifiedFormula formula) {
//		if (formula instanceof QuantifiedFormula) {
//			val clonedFormula = formula.clone // So no side-effect
//			val pathFormulas = clonedFormula.relevantTemporalPathFormulas
//			val unaryOperandPathFormulas = pathFormulas.filter(UnaryOperandPathFormula)
//			val quantifier = clonedFormula.quantifier
//			//
//			if (quantifier == PathQuantifier.EXISTS) { // E
//				val globals = unaryOperandPathFormulas.filter[it.operator == UnaryPathOperator.GLOBAL]
//				for (global : globals) { // G cannot be after E, but: G p === !F!p
//					global.changeToDual
//				}
//				return clonedFormula
//			}
//			else { // A
//				val futures = unaryOperandPathFormulas.filter[it.operator == UnaryPathOperator.FUTURE]
//				for (future : futures) { // F cannot be after A, but: F p === !G!p
//					future.changeToDual
//				}
//				return clonedFormula
//			}
//		}
//		return formula
//	}
	
	//
	
	protected def getRelevantTemporalPathFormulas(PathFormula formula) {
		// We consider levels of F, G, X and U operators in-between A and E quantifiers
		// to support multiple level of A/E nesting (CTL*)
		return formula.getAllContentsOfTypeBetweenTypes(QuantifiedFormula, TemporalPathFormula)
	}
	
	protected def getRecordId() {
		return ImlReferenceSerializer.recordIdentifier
	}
	
	protected def getInputId() {
		return "e"
	}
	
	protected def getPostfix(TemporalPathFormula formula) {
		val unaryOperandPathFormulas = formula.relevantTemporalPathFormulas
		val containingTemporalPathFormulas = formula.getAllContainersOfType(TemporalPathFormula)
		
		val operator = if (formula instanceof UnaryOperandPathFormula) {
			formula.operator.seriliaze
		}
		else if (formula instanceof BinaryOperandPathFormula) {
			formula.operator.seriliaze
		}
		else {
			throw new IllegalArgumentException("Not known formula: " + formula)
		}
		
		val postfix = '''_«containingTemporalPathFormulas.size»_«operator»_«unaryOperandPathFormulas.indexOf(formula)»''' // This format is depended on elsewhere...
		
		return postfix
	}
	
	protected def getInputId(TemporalPathFormula formula) {
		return inputId + formula.postfix
	}
	
	protected def getSinglePathConstraint(QuantifiedFormula formula) {
		val builder = new StringBuilder("true") // Placeholder, works with && and ==>, too
		
		val formulas = formula.relevantTemporalPathFormulas
		val sameLevelFormulasMap = formulas.groupBy[
				it.getAllContainersOfType(TemporalPathFormula).size] // Same-level operators
		for (sameLevelFormulas : sameLevelFormulasMap.values) {
			val nexts = sameLevelFormulas.filter(UnaryOperandPathFormula).filter[it.operator == UnaryPathOperator.NEXT]
			val nonNexts = sameLevelFormulas.reject[nexts.contains(it)]
			
			val next = nexts.head
			if (nexts.size > 1) {
				// The single input elements (next input) shall be the same
				builder.append(''' && («FOR otherNext : nexts SEPARATOR " && "»«next.inputId» = «otherNext.inputId»«ENDFOR»)''')
			}
			if (nonNexts.size > 1) {
				// The non-empty lists' first element shall be the same as 'next'
				if (next !== null) {
					builder.append(''' && («FOR other : nonNexts SEPARATOR " && "»((«other.inputId» <> []) ==> List.hd «other.inputId» = «next.inputId»)«ENDFOR»)''')
				}
				// The lists shall be each other's prefixes // Should work for paths ending in loops (e.g., A F or E G), too
				val otherPairs = nonNexts.pairs
				builder.append(''' && («FOR otherPair : otherPairs SEPARATOR " && "»(«isOnePrefixOfOtherName» «otherPair.key.inputId» «otherPair.value.inputId»)«ENDFOR»)''')
			}
		}
		
		return builder.toString
	}
	
	//
	
	protected def getForallPrefixName() '''forall_prefix'''
	protected def getExistsPrefixName() '''exists_prefix'''
	protected def getForallRealPrefixName() '''forall_real_prefix'''
	protected def getExistsRealPrefixName() '''exists_real_prefix'''
	protected def getIsOnePrefixOfOtherName() '''is_one_prefix_of_other'''
	protected def getEndsInLoopName() '''ends_in_loop'''
	protected def getEndsInRealLoopName() '''ends_in_real_loop'''
	protected def getEPrefixLeadingToName() '''get_e_prefix_leading_to'''
	
}