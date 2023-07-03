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
package hu.bme.mit.gamma.codegeneration.java

import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.interface_.Interface

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class PortInterfaceGenerator {

	protected final String PACKAGE_NAME
	//
	protected final extension TypeTransformer typeTransformer
	protected final extension EventDeclarationHandler gammaEventDeclarationHandler
	protected final extension NameGenerator nameGenerator

	new(String packageName, Trace trace) {
		this.PACKAGE_NAME = packageName
		this.typeTransformer = new TypeTransformer(trace)
		this.gammaEventDeclarationHandler = new EventDeclarationHandler(trace)
		this.nameGenerator = new NameGenerator(this.PACKAGE_NAME)
	}

	def generatePortInterfaces(Interface anInterface) '''
		package «anInterface.generateObjectPackageName»;
		
		import «PACKAGE_NAME».*;
		«FOR _package : anInterface.containingPackage.importsWithComponentsOrInterfacesOrTypes»
			import «_package.getPackageString(PACKAGE_NAME)».*;
		«ENDFOR»
		import java.util.List;
		
		public interface «anInterface.implementationName» {
			
			interface Provided extends Listener.Required {
				
				«anInterface.generateIsRaisedInterfaceMethods(EventDirection.IN)»
				
				void registerListener(Listener.Provided listener);
				List<Listener.Provided> getRegisteredListeners();
			}
			
			interface Required extends Listener.Provided {
				
				«anInterface.generateIsRaisedInterfaceMethods(EventDirection.OUT)»
				
				void registerListener(Listener.Required listener);
				List<Listener.Required> getRegisteredListeners();
			}
			
			interface Listener {
				
				interface Provided «IF !anInterface.parents.empty»extends «FOR parent : anInterface.parents
						SEPARATOR ', '»«parent.implementationName».Listener.Provided«ENDFOR»«ENDIF» {
					«FOR event : anInterface.getAllEvents(EventDirection.IN)»
						void raise«event.name.toFirstUpper»(«event.generateParameters»);
					«ENDFOR»
				}
				
				interface Required «IF !anInterface.parents.empty»extends «FOR parent : anInterface.parents
						SEPARATOR ', '»«parent.implementationName».Listener.Required«ENDFOR»«ENDIF» {
					«FOR event : anInterface.getAllEvents(EventDirection.OUT)»
						void raise«event.name.toFirstUpper»(«event.generateParameters»);
					«ENDFOR»
				}
				
			}
		}
	'''

	private def generateIsRaisedInterfaceMethods(Interface anInterface, EventDirection oppositeDirection) '''
«««		Simple flag checks
		«FOR event : anInterface.getAllEvents(oppositeDirection)»
			public boolean isRaised«event.name.toFirstUpper»();
«««			ValueOf checks	
			«FOR parameter : event.parameterDeclarations»
				public «parameter.type.transformType» get«parameter.name.toFirstUpper»();
			«ENDFOR»
		«ENDFOR»
	'''

}
