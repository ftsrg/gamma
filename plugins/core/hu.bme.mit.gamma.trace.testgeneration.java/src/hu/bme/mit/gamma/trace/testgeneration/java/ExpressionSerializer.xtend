/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.testgeneration.java

import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression
import hu.bme.mit.gamma.expression.model.GreaterExpression
import hu.bme.mit.gamma.expression.model.LessEqualExpression
import hu.bme.mit.gamma.expression.model.LessExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ExpressionSerializer extends hu.bme.mit.gamma.codegeneration.java.util.ExpressionSerializer {
	
	protected final String testInstanceName
	protected final Component component
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	//
	
	new(Component component, String testInstanceName) {
		this.testInstanceName = testInstanceName
		this.component = component
	}
	
	//
	
	override dispatch String serialize(EqualityExpression expression) '''Objects.deepEquals(«expression.leftOperand.serialize», «expression.rightOperand.serialize»)'''
	
	override dispatch String serialize(LessExpression expression)
		'''Objects.compare(«expression.leftOperand.serialize», «expression.rightOperand.serialize»,
			«comparator») < 0'''
	override dispatch String serialize(LessEqualExpression expression)
		'''Objects.compare(«expression.leftOperand.serialize», «expression.rightOperand.serialize»,
			«comparator») <= 0'''
	override dispatch String serialize(GreaterExpression expression)
		'''Objects.compare(«expression.leftOperand.serialize», «expression.rightOperand.serialize»,
			«comparator») > 0'''
	override dispatch String serialize(GreaterEqualExpression expression)
		'''Objects.compare(«expression.leftOperand.serialize», «expression.rightOperand.serialize»,
			«comparator») >= 0'''
	
	protected def String comparator() '''(a, b) -> Double.compare((((Number) a).doubleValue()), ((Number) b).doubleValue())''' // Could be refined; now we "cast" to double
	
	//
	
	def dispatch String serialize(RaiseEventAct assert) '''
		«testInstanceName».isRaisedEvent("«assert.port.name»", "«assert.event.name»"«IF
				!assert.arguments.empty», new Object[] {«FOR argument : assert.arguments BEFORE " " SEPARATOR ", " AFTER " "»«argument.serialize»«ENDFOR»}«ENDIF»)'''

	def dispatch String serialize(EventParameterReferenceExpression assert) {
		val parameter = assert.parameter
		'''«testInstanceName».getEventParameterValues("«assert.port.name»", "«assert.event.name»")[«parameter.index»]'''
	}

	def dispatch String serialize(ComponentInstanceStateReferenceExpression assert) {
		val instance = assert.instance
		'''«instance.serializeInstanceReference».isStateActive("«assert.state.parentRegion.name»", "«assert.state.name»")'''
	}
	
	def dispatch String serialize(ComponentInstanceVariableReferenceExpression assert) {
		val instance = assert.instance
		val variable = assert.variableDeclaration
		'''«instance.serializeInstanceReference».getValue("«variable.name»")'''
	}
	
	//
	
	def String serializeInstanceReference(ComponentInstanceReferenceExpression instance) {
		val separator = (instance === null) ? '' : '.'
		return '''«testInstanceName»«separator»«instance.fullContainmentHierarchy»'''
	}
	
	//
	
	
	protected def getFullContainmentHierarchy(ComponentInstanceReferenceExpression instanceReference) {
		val instanceNames = newArrayList
		if (instanceReference !== null) {
			val instances = instanceReference.componentInstanceChain
			if (component.unfolded) {
				// If only a single instance is given, we explore the containment chain
				if (instances.size == 1) {
					val instance = instances.remove(0) // So the original list becomes empty
					instances += instance.componentInstanceChain
				}
				
				var ComponentInstance previousInstance = null
				for (instance : instances) {
					val instanceName = instance.name
					if (previousInstance === null) {
						instanceNames += instanceName
					}
					else {
						instanceNames += instanceName.substring(previousInstance.name.length + 1) // "_" is counted too
					}
					previousInstance = instance
				}
			}
			else {
				// Original component instance references
				instanceNames += instances.map[it.name]
			}
		}
		return '''«FOR instanceName : instanceNames SEPARATOR '.'»getComponent("«instanceName»")«ENDFOR»'''
	}
	
}
