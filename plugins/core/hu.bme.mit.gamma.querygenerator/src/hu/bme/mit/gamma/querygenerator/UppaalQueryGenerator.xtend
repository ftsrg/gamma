/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.querygenerator.operators.TemporalOperator
import hu.bme.mit.gamma.querygenerator.patterns.StatesToLocations
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.uppaal.util.Namings.*

class UppaalQueryGenerator extends AbstractQueryGenerator {
	
	new(G2UTrace trace) {
		super(trace.gammaPackage.firstComponent)
		val traceabilitySet = trace.eResource.resourceSet
		checkArgument(traceabilitySet !== null)
		val componentSet = component.eResource.resourceSet
		checkArgument(traceabilitySet === componentSet)
	}
	
	override String parseRegularQuery(String text, TemporalOperator operator) {
		checkArgument(!operator.equals(TemporalOperator.LEADS_TO))
		var result = text.parseIdentifiers
		if (!operator.equals(TemporalOperator.MIGHT_ALWAYS) && !operator.equals(TemporalOperator.MUST_ALWAYS)) {
			// It is pointless to add isStable in the case of A[] and E[]
			result += ''' && «isStableVariableName»'''
		}
		else {
			// Instead this is added
			result += ''' || !«isStableVariableName»'''
		}
		return operator.operator + " " + result
	}
	
	override String parseLeadsToQuery(String first, String second) {
		return '''«first.parseIdentifiers» && «isStableVariableName» --> «second.parseIdentifiers» && «isStableVariableName»'''
	}
	
	protected override String getTargetStateName(State state, Region parentRegion,
			SynchronousComponentInstance instance) {
		val templateName = parentRegion.getTemplateName(instance)
		val processName = templateName.processName
		val locationNames = new StringBuilder("(")
		for (String locationName : StatesToLocations.Matcher.on(engine).getAllValuesOflocationName(null,
				state.name,
				templateName /*Must define templateName too as there are states with the same (same statechart types)*/)) {
			val templateLocationName = processName +  "." + locationName
			if (locationNames.length == 1) {
				// First append
				locationNames.append(templateLocationName)
			}
			else {
				locationNames.append(" || " + templateLocationName)
			}
		}
		locationNames.append(")")
		if (parentRegion.subregion) {
			locationNames.append(" && " + processName + ".isActive") 
		}
		return locationNames.toString
	}
	
	override protected getTargetVariableNames(VariableDeclaration variable,
			SynchronousComponentInstance instance) {
		return #[getVariableName(variable, instance)]
	}
	
	override protected getTargetOutEventName(Event event, Port port,
			SynchronousComponentInstance instance) {
		return getOutEventName(event, port, instance)
	}
	
	override protected getTargetOutEventParameterNames(Event event, Port port,
			ParameterDeclaration parameter, SynchronousComponentInstance instance) {
		return #[getOutValueOfName(event, port, parameter, instance)]
	}
	
}