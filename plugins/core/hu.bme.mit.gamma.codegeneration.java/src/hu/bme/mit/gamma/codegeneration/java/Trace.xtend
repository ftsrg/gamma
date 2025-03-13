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
package hu.bme.mit.gamma.codegeneration.java

import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

class Trace {
	
	protected final ViatraQueryEngine engine
	
	new(ViatraQueryEngine engine) {
		this.engine = engine
	}
	
	def getEngine() {
		return this.engine
	}
	
//	/**
//	 * Returns a Set of EObjects that are created of the given "from" object.
//	 */
//	protected def getAllValuesOfTo(EObject from) {
//		return engine.getMatcher(Traces.instance).getAllValuesOfto(null, from)		
//	}
//	
//	/**
//	 * Returns a Set of EObjects that the given "to" object is created of.
//	 */
//	protected def getAllValuesOfFrom(EObject to) {
//		return engine.getMatcher(Traces.instance).getAllValuesOffrom(null, to)
//	}
//	
//	/**
//	 * Returns the Yakindu event the given Gamma event is generated from.
//	 */
//	protected def Event toYakinduEvent(hu.bme.mit.gamma.statechart.interface_.Event event, Port port) {
//		val yEvents = EventToEvent.Matcher.on(engine).getAllValuesOfyEvent(port, event)
//		if (yEvents.size != 1) {
//			val component = port.eContainer as Component
//			throw new IllegalArgumentException("Not one Yakindu event mapped to Gamma event. Gamma component: " + component.name + ". Gamma port: " + port.name + ". " + "Gamma event: " + event.name + ". Yakindu event size: " + yEvents.size + ". Yakindu events:" + yEvents)
//		}
//		return yEvents.head
//	}
	
}