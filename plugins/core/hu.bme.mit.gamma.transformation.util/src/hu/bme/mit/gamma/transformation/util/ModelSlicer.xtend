/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.property.model.AtomicFormula
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.transformation.util.reducer.SystemOutEventReducer
import hu.bme.mit.gamma.transformation.util.reducer.WrittenOnlyVariableReducer
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.AbstractMap.SimpleEntry
import java.util.Collection
import java.util.Map.Entry

class ModelSlicer {
		
	protected final PropertyPackage propertyPackage
	protected final boolean removeOutEventRaisings
	
	protected GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new(PropertyPackage propertyPackage) {
		this(propertyPackage, false)
	}
	
	new(PropertyPackage propertyPackage, boolean removeOutEventRaisings) {
		this.propertyPackage = propertyPackage
		this.removeOutEventRaisings = removeOutEventRaisings
	}
	
	def void execute() {
		val component = propertyPackage.component
		val containingPackage = StatechartModelDerivedFeatures.getContainingPackage(component)
		val atomicFormulas = ecoreUtil.getAllContentsOfType(propertyPackage, AtomicFormula)
		
		// Variable removal
		val Collection<VariableDeclaration> relevantVariables = newHashSet
		for (atomicFormula : atomicFormulas) {
			val variableReferences =
					ecoreUtil.getAllContentsOfType(atomicFormula, ComponentInstanceVariableReferenceExpression)
			for (variableReference : variableReferences) {
				relevantVariables += variableReference.variableDeclaration
			}
		}
		val variableReducer = new WrittenOnlyVariableReducer(containingPackage, relevantVariables)
		variableReducer.execute
		
		// Out-event and out-event parameter raising removal
		if (removeOutEventRaisings) {
			val Collection<Entry<Port, Event>> relevantEvents = newHashSet
			for (atomicFormula : atomicFormulas) {
				val eventReferences =
						ecoreUtil.getAllContentsOfType(atomicFormula, ComponentInstanceEventReferenceExpression)
				for (eventReference : eventReferences) {
					relevantEvents += new SimpleEntry<Port, Event>(eventReference.port, eventReference.event)
				}
				val parameterReferences =
						ecoreUtil.getAllContentsOfType(atomicFormula, ComponentInstanceEventParameterReferenceExpression)
				for (parameterReference : parameterReferences) {
					relevantEvents += 
							new SimpleEntry<Port, Event>(parameterReference.port, parameterReference.event)
				}
			}
			val systemOutEventReducer = new SystemOutEventReducer(component, relevantEvents)
			systemOutEventReducer.execute
		}
	}
	
}