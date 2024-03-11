/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.expression.model.NamedElement
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import java.util.List
import org.eclipse.emf.ecore.EObject

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class Namings {
	
	private static def String addAsynchronousStatechartName(ComponentInstanceReferenceExpression instance) { return instance.lastInstance.addAsynchronousStatechartName }
	private static def String addAsynchronousStatechartName(ComponentInstance instance) '''«IF instance.asynchronousStatechart»_«instance.derivedType.wrapperInstanceName»«ENDIF»'''
	
	
//	def static String getFQN(List<ComponentInstance> instances) '''«FOR instance : instances SEPARATOR '_'»«instance.name»«IF instance.asynchronousStatechart»_«instance.derivedType.wrapperInstanceName»«ENDIF»«ENDFOR»'''
	def static String getFQN(List<ComponentInstance> instances) '''«FOR instance : instances SEPARATOR '_'»«instance.name»«ENDFOR»'''
	def static String getFQN(ComponentInstanceReferenceExpression instance) '''«instance.componentInstanceChain.FQN»«instance.addAsynchronousStatechartName»'''
	def static String getFQN(ComponentInstance instance) '''«instance.componentInstanceChain.FQN»'''
	
	def static String getFQN(StateNode node) '''«node.parentRegion.FQN»_«node.name»'''
	def static String getFQN(Region region) {
		val container = region.eContainer
		val name = region.name
		if (container instanceof StateNode) {
			return '''«container.FQN»_«name»'''
		}
		if (container instanceof StatechartDefinition) {
			return '''«container.name»_«name»'''
		}
		throw new IllegalArgumentException("Not known container: " + container)
	}
	
	def static String getFQNUpToComponent(EObject element) {
		if (element instanceof Component) {
			return element.name
		}
		val parent = element.eContainer
		val parentFqn = parent.FQNUpToComponent
		if (element instanceof NamedElement) {
			return '''«parentFqn»_«element.name»'''
		}
		return parentFqn
	}
	
}