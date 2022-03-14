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

import hu.bme.mit.gamma.codegeneration.java.util.InterfaceCodeGenerator
import hu.bme.mit.gamma.statechart.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Port
import java.util.HashSet

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ComponentInterfaceGenerator {
	
	protected final String PACKAGE_NAME
	//
	protected final extension NameGenerator nameGenerator
	protected final extension InterfaceCodeGenerator interfaceCodeGenerator
	
	new(String packageName) {
		this.PACKAGE_NAME = packageName
		this.nameGenerator = new NameGenerator(this.PACKAGE_NAME)
		this.interfaceCodeGenerator = new InterfaceCodeGenerator(this.PACKAGE_NAME)
	}
	
	/**
	 * Generates the Java interface code (implemented by the component) of the given component.
	 */
	def generateComponentInterface(Component component) {
		var ports = new HashSet<Port>
		if (component instanceof CompositeComponent) {
			val composite = component as CompositeComponent
			ports += composite.ports
		}
		else if (component instanceof AsynchronousAdapter) {
			ports += component.allPorts
		}
		else {
			ports += component.ports
		}
		val interfaceCode = '''
			package «component.generateComponentPackageName»;
			
			import «PACKAGE_NAME».*;
			«FOR _interface : component.interfaces»
				import «_interface.getPackageString(PACKAGE_NAME)».«_interface.implementationName»;
			«ENDFOR»
			
			public interface «component.generatePortOwnerInterfaceName» {
				
				«FOR port : ports»
					«port.implementedInterfaceName» get«port.name.toFirstUpper»();
				«ENDFOR»
				
				void reset();
				
				«IF component instanceof SynchronousComponent»void runCycle();«ENDIF»
				«IF component instanceof AbstractSynchronousCompositeComponent»void runFullCycle();«ENDIF»
				«IF component instanceof AsynchronousComponent»void start();«ENDIF»
				
			}
		'''
		return interfaceCode
	}
	
	def generateReflectiveInterface() {
		interfaceCodeGenerator.createReflectiveInterface
	}
	
}