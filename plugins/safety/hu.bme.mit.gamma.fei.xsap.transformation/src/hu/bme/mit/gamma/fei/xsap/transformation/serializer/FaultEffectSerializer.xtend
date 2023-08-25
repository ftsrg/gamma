/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.fei.xsap.transformation.serializer

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.fei.model.AbstractConditionalEffect
import hu.bme.mit.gamma.fei.model.BoundedEffect
import hu.bme.mit.gamma.fei.model.ConditionalEffect
import hu.bme.mit.gamma.fei.model.DeltaEffect
import hu.bme.mit.gamma.fei.model.DeltaInErroneousEffect
import hu.bme.mit.gamma.fei.model.DeltaInRandomEffect
import hu.bme.mit.gamma.fei.model.DeltaOutEffect
import hu.bme.mit.gamma.fei.model.DeltaUntilBoundEffect
import hu.bme.mit.gamma.fei.model.Effect
import hu.bme.mit.gamma.fei.model.ErroneousEffect
import hu.bme.mit.gamma.fei.model.FaultSlice
import hu.bme.mit.gamma.fei.model.FrozenEffect
import hu.bme.mit.gamma.fei.model.InvertedEffect
import hu.bme.mit.gamma.fei.model.NonDeterminismBooleanEffect
import hu.bme.mit.gamma.fei.model.NonDeterminismEffect
import hu.bme.mit.gamma.fei.model.NonParametricEffect
import hu.bme.mit.gamma.fei.model.OccurrenceSpecificEffect
import hu.bme.mit.gamma.fei.model.RampDownEffect
import hu.bme.mit.gamma.fei.model.RandomEffect
import hu.bme.mit.gamma.fei.model.SelfFixTemplate
import hu.bme.mit.gamma.fei.model.StuckAtEffect
import hu.bme.mit.gamma.fei.model.StuckAtFixedEffect
import hu.bme.mit.gamma.fei.model.Template
import hu.bme.mit.gamma.fei.model.TermEffect
import hu.bme.mit.gamma.fei.model.TermReferenceSpecificEffect
import hu.bme.mit.gamma.querygenerator.serializer.NuxmvReferenceSerializer
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression
import hu.bme.mit.gamma.util.GammaEcoreUtil

class FaultEffectSerializer {
	// Singleton
	public static FaultEffectSerializer INSTANCE = new FaultEffectSerializer
	protected new() {}
	//
	protected final extension NuxmvReferenceSerializer referenceSerializer = NuxmvReferenceSerializer.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	//
	
	def serializeEffect(Effect effect) '''
		«effect.serializeNamePrefix»«effect.serializeTermReferenceMode»«effect.serializeNameSuffix»«effect.serializeOccurrenceMode»(
			«effect.serializeParameters»
		)'''
	
	//
	
	protected def serializeNamePrefix(Effect effect) {
		return switch (effect) {
			StuckAtEffect : "StuckAt"
			FrozenEffect : "Frozen"
			NonDeterminismEffect : "NonDeterminism" // Has to be adjusted at the end
			NonDeterminismBooleanEffect : "NonDeterminism" // Has to be adjusted at the end
			ConditionalEffect : "Conditional" 
			RampDownEffect : "RampDown"
			InvertedEffect : "Inverted"
			StuckAtFixedEffect : "StuckAtFixed"
			RandomEffect : "Random"
			ErroneousEffect : "Erroneous"
			DeltaOutEffect : "DeltaOut"
			DeltaInRandomEffect : "DeltaInRandom"
			DeltaInErroneousEffect : "DeltaInErroneous"
			default : throw new IllegalArgumentException("Not expected effect: " + effect)
		}
	}
	
	protected def serializeNameSuffix(Effect effect) {
		return switch (effect) {
			NonDeterminismEffect : "_Num"
			NonDeterminismBooleanEffect : "_Bool"
			default : ""
		}
	}
	
	protected def serializeTermReferenceMode(Effect effect) {
		if (effect instanceof TermReferenceSpecificEffect) {
			val mode = effect.termReferenceMode
			return "By" + switch (mode) {
				case REFERENCE: "Reference"
				case VALUE: "Value"
				default: throw new IllegalArgumentException("Not expected term reference mode: " + mode)
			}
		}
		
		return ""
	}
	
	protected def serializeOccurrenceMode(Effect effect) {
		if (effect instanceof OccurrenceSpecificEffect) {
			val occurrence = effect.occurrence
			return "_" + switch (occurrence) {
				case DELAYED: "D"
				case INSTANTANEOUS: "I"
				default: throw new IllegalArgumentException("Not expected occurrence: " + occurrence)
			}
		}
		
		return ""
	}
	
	//
	
	protected def serializeParameters(Effect effect) {
		val slice = effect.getContainerOfType(FaultSlice)
		val affectedElements = slice.affectedElements
		val affectedElement = affectedElements.head
		
		val input = effect.input
		val varout = effect.varout
		val failure = effect.failureEvent
		
		return '''
			«effect.serializeSpecialParameters»
			data input << «IF input !== null»«input.serializeId»«ELSE»«affectedElement.serializeId»«ENDIF»,
			data varout >> «IF varout !== null»«varout.serializeId»«ELSE»«affectedElement.serializeId»«ENDIF»,
			event failure >> «IF failure !== null»«failure.serializeId»«ENDIF /*TODO add some kind of default value*/»
			«FOR template : effect.template»
				, «template.serializeTemplate»
			«ENDFOR»
		'''
	}
	
	//
	
	protected def dispatch serializeTemplate(Template template) {
		throw new IllegalArgumentException("Not known template: " + template)
	}
	
	protected def dispatch serializeTemplate(SelfFixTemplate template) {
		val selfFixEvent = template.selfFixEvent
		
		return '''
			template self_fix = self_fixed,
			event self_fixed >> «IF selfFixEvent !== null»«selfFixEvent.serializeId»«ENDIF /*TODO add some kind of default value*/»
		'''
	}
	
	//
	
	protected def dispatch String serializeSpecialParameters(TermReferenceSpecificEffect effect) {
		return '''''' // This is basically the "else" branch for unhandled effects
	}
	
	protected def dispatch String serializeSpecialParameters(NonParametricEffect effect) {
		return ''''''
	}
	
	protected def dispatch String serializeSpecialParameters(TermEffect effect) {
		val term = effect.term
		return '''data term << «term.serializeExpression»,'''
	}
	
	protected def dispatch String serializeSpecialParameters(DeltaEffect effect) {
		val delta = effect.delta
		return '''data delta << «delta.serializeExpression»,'''
	}
	
	protected def dispatch String serializeSpecialParameters(AbstractConditionalEffect effect) {
		val condition = effect.condition
		val then = effect.then
		val _else = effect.^else
		return '''
			data condition << «condition.serializeExpression»,
			data then_term << «then.serializeExpression»,
			data else_term << «_else.serializeExpression»,
		'''
	}
	
	protected def dispatch String serializeSpecialParameters(BoundedEffect effect) {
		val minimum = effect.minimum
		val maximum = effect.maximum
		return '''
			data min_bound << «minimum.serializeExpression»,
			data max_bound << «maximum.serializeExpression»,
		'''
	}
	
	protected def dispatch String serializeSpecialParameters(DeltaUntilBoundEffect effect) {
		val delta = effect.delta
		val bound = effect.bound
		return '''
			data decr << «delta.serializeExpression»,
			data end_value << «bound.serializeExpression»,
		'''
	}
	
	//
	
	protected def serializeExpression(Expression expression) {
		if (expression instanceof ComponentInstanceElementReferenceExpression) {
			return expression.serializeId
		}
		return expression.evaluateDecimal.toString
	}
	
	protected def serializeId(ComponentInstanceElementReferenceExpression reference) {
		return reference.singleIdWithoutState
	}
	
}