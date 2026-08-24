/********************************************************************************
 * Copyright (c) 2018-2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.codegeneration.java

import hu.bme.mit.gamma.expression.model.NamedElement
import hu.bme.mit.gamma.expression.model.ParametricElement
import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.interface_.Interface
import java.util.Collections
import java.util.HashSet
import java.util.Set

class EventDeclarationHandler {
	//	
	protected final extension TypeTransformer typeTransformer
	//
	protected final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
	//
	
	new(Trace trace) {
		this.typeTransformer = new TypeTransformer(trace)
	}
	
	/**
	 * Returns the parameter type and name of the given event declaration, e.g., long value.
	 */
	def generateParameters(ParametricElement element) '''«FOR parameter : element.parameterDeclarations SEPARATOR ", "»«parameter.type.transformType» «parameter.generateName»«ENDFOR»'''
	def generateNativeParameters(ParametricElement element) '''«FOR parameter : element.parameterDeclarations SEPARATOR ", "»«val nativeTypes = parameter.nativeTypes»«FOR type : nativeTypes SEPARATOR ", "»«type.transformType» «parameter.generateName»_«nativeTypes.indexOf(type)»«ENDFOR»«ENDFOR»'''
	
	def generateArguments(ParametricElement element) '''«FOR parameter : element.parameterDeclarations SEPARATOR ", "»«parameter.generateName»«ENDFOR»'''
	def generateNativeArguments(ParametricElement element) '''«FOR parameter : element.parameterDeclarations SEPARATOR ", "»«val nativeTypes = parameter.nativeTypes»«FOR type : nativeTypes SEPARATOR ", "»«parameter.generateName»_«nativeTypes.indexOf(type)»«ENDFOR»«ENDFOR»'''
	
	def generateName(NamedElement element) '''«element.name.toFirstLower»'''
	
	/** 
	 * Returns all events of a given interface whose direction is not oppositeDirection.
	 * The parent interfaces are taken into considerations as well.
	 */ 
	 protected def Set<Event> getAllEvents(Interface anInterface, EventDirection oppositeDirection) {
		if (anInterface === null) {
			return Collections.EMPTY_SET
		}
		val eventSet = new HashSet<Event>
		for (parentInterface : anInterface.parents) {
			eventSet.addAll(parentInterface.getAllEvents(oppositeDirection))
		}
		for (event : anInterface.eventDeclarations
				.filter[it.direction != oppositeDirection]
				.map[it.event]) {
			eventSet.add(event)
		}
		return eventSet
	}
	
}