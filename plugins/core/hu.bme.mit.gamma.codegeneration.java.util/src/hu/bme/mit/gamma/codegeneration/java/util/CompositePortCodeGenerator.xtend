/********************************************************************************
 * Copyright (c) 2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.codegeneration.java.util

import hu.bme.mit.gamma.statechart.interface_.AbstractPort
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.CompositePort
import hu.bme.mit.gamma.statechart.interface_.Port

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

/**
 * Generates the Java representation of composite ports: a nested interface in the port owner interface
 * of the component, and an implementing inner class in the component class. Both of them provide getters
 * for the contained (simple or composite) ports, returning the very same port objects as the
 * getters of the component, e.g., component.getExecuteB().getExecute() == component.getExecute().
 *
 * Used for every component kind (statecharts, composite components and adapters); it relies on the following
 * conventions: the component class is named {@link Namings#getComponentClassName}, the port owner interface
 * is named by suffixing it with "Interface", and the port fields of the class are named after the ports.
 */
class CompositePortCodeGenerator {
	// Singleton
	public static final CompositePortCodeGenerator INSTANCE = new CompositePortCodeGenerator
	protected new() {}
	//

	/**
	 * Generates the composite port getter declarations of the port owner interface.
	 */
	def generateCompositePortGetterDeclarations(Component component) '''
		«FOR compositePort : component.allCompositePorts»
			«compositePort.compositePortTypeName» get«compositePort.name.toFirstUpper»();
		«ENDFOR»
	'''

	/**
	 * Generates the nested interfaces of the port owner interface representing the composite ports.
	 */
	def generateCompositePortInterfaces(Component component) '''
		«FOR compositePort : component.allCompositePorts SEPARATOR System.lineSeparator»
			/** Composite port «compositePort.name» of «compositePort.ports.map[it.name].join(", ")». */
			interface «compositePort.compositePortTypeName» {
				«FOR port : compositePort.containedPorts»
					«port.portTypeName» get«port.name.toFirstUpper»();
				«ENDFOR»
			}
		«ENDFOR»
	'''

	/**
	 * Generates the composite port field declarations of the component class,
	 * to be instantiated using {@link #generateCompositePortInstantiations}.
	 */
	def generateCompositePortFields(Component component) '''
		«IF !component.allCompositePorts.empty»
			// Composite port instances
		«ENDIF»
		«FOR compositePort : component.allCompositePorts»
			private «compositePort.compositePortTypeName» «compositePort.name.toFirstLower»;
		«ENDFOR»
	'''

	/**
	 * Generates the composite port field declarations of the component class with inline instantiation,
	 * for component classes whose (simple) port fields are instantiated inline, too.
	 */
	def generateInitializedCompositePortFields(Component component) '''
		«IF !component.allCompositePorts.empty»
			// Composite port instances
		«ENDIF»
		«FOR compositePort : component.allCompositePorts»
			private «compositePort.compositePortTypeName» «compositePort.name.toFirstLower» = new «compositePort.compositePortTypeName»();
		«ENDFOR»
	'''

	/**
	 * Generates the inner classes (and their getters) of the component class representing the composite ports.
	 */
	def generateCompositePortClasses(Component component) '''
		«FOR compositePort : component.allCompositePorts SEPARATOR System.lineSeparator»
			«val typeName = compositePort.compositePortTypeName»
			public class «typeName» implements «component.portOwnerInterfaceName».«typeName» {
				«FOR port : compositePort.containedPorts SEPARATOR System.lineSeparator»
					@Override
					public «port.name.toFirstUpper» get«port.name.toFirstUpper»() {
						return «component.componentClassName».this.«port.name.toFirstLower»;
					}
				«ENDFOR»
			}

			@Override
			public «typeName» get«compositePort.name.toFirstUpper»() {
				return «compositePort.name.toFirstLower»;
			}
		«ENDFOR»
	'''

	//

	def getCompositePortTypeName(CompositePort compositePort) {
		return compositePort.name.toFirstUpper
	}

	protected def getPortOwnerInterfaceName(Component component) {
		return component.componentClassName + "Interface"
	}

	protected def getContainedPorts(CompositePort compositePort) {
		return compositePort.ports.toSet // Broadcast ports can be contained multiple times
	}

	protected def String getPortTypeName(AbstractPort port) {
		if (port instanceof Port) {
			return port.implementedInterfaceName
		}
		if (port instanceof CompositePort) {
			return port.compositePortTypeName
		}
		throw new IllegalArgumentException("Not known port: " + port)
	}

}
