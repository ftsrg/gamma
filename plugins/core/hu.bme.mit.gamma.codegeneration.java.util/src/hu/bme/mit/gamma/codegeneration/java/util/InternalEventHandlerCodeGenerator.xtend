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
package hu.bme.mit.gamma.codegeneration.java.util

import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Port

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class InternalEventHandlerCodeGenerator {
	// Singleton
	public static final InternalEventHandlerCodeGenerator INSTANCE = new InternalEventHandlerCodeGenerator
	protected new() {}
	//
	
	def createInternalPortHandlingAttributes(Component component) '''
		«FOR internalPort : component.allInternalPorts»
			private boolean handle«internalPort.name.toFirstUpper» = true;
		«ENDFOR»
	'''
	
	def createInternalPortHandlingSettingCode(Component component) '''
		«FOR internalPort : component.allInternalPorts»
			«FOR subcomponent : component.instances»
				«FOR subport : subcomponent.derivedType.allInternalPorts.filter[it === internalPort || it.boundCompositePort === internalPort ||
						component.isBoundViaCompositePortBinding(subcomponent, it, internalPort)]»
					«subcomponent.name».handle«subport.name.toFirstUpper»(false);
				«ENDFOR»
			«ENDFOR»
		«ENDFOR»
	'''
	
	def createInternalPortHandlingSetters(Component component) '''
		«FOR internalPort : component.allInternalPorts»
			public void handle«internalPort.name.toFirstUpper»(boolean handle«internalPort.name.toFirstUpper») {
				this.handle«internalPort.name.toFirstUpper» = handle«internalPort.name.toFirstUpper»;
				«IF component instanceof CompositeComponent»
					if (handle«internalPort.name.toFirstUpper» == false) {
						«FOR portBinding : component.allUnfoldedPortBindings.filter[it.compositeSystemPort === internalPort]»
							«portBinding.instancePortReference.instance.name».handle«portBinding
									.instancePortReference.port.name.toFirstUpper»(handle«internalPort.name.toFirstUpper»);
						«ENDFOR»
					}
				«ENDIF»
			}
		«ENDFOR»
	'''
	
	def createInternalEventHandlingCode(Component component) '''
		«IF component.hasInternalPort»
			public void handleInternalEvents() {
				«FOR internalPort : component.allInternalPorts»
					«IF component.adapter»
						«internalPort.createInternalEventRaisings»
					«ELSE»
						if (handle«internalPort.name.toFirstUpper») {
							«internalPort.createInternalEventRaisings»
						}
					«ENDIF»
				«ENDFOR»
			}
		«ENDIF»
	'''
	
	/**
	 * Returns whether the given instance port is bound to the given system port by a composite port binding.
	 */
	protected def isBoundViaCompositePortBinding(Component component,
			ComponentInstance instance, Port instancePort, Port systemPort) {
		if (component instanceof CompositeComponent) {
			return component.compositePortBindings
				.map[it.unfoldedPortBindings].flatten
				.exists[it.compositeSystemPort === systemPort &&
					it.instancePortReference.instance === instance && it.instancePortReference.port === instancePort]
		}
		return false
	}
	
	protected def createInternalEventRaisings(Port internalPort) '''
		«FOR internalEvent : internalPort.internalEvents»
			if («internalPort.name.toFirstLower».isRaised«internalEvent.name.toFirstUpper»()) {
				«internalPort.name.toFirstLower».raise«internalEvent.name.toFirstUpper»(«FOR parameter : internalEvent.parameterDeclarations SEPARATOR ', '»«internalPort.name.toFirstLower».get«parameter.name.toFirstUpper»()«ENDFOR»);
			}
		«ENDFOR»
	'''
	
}