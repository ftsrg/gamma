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
package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class StatechartInterfaceCodeGenerator {
	
	final String BASE_PACKAGE_NAME
	final String STATECHART_PACKAGE_NAME
	final String INTERFACE_NAME
	
	final StatechartDefinition gammaStatechart
	
	new(String basePackageName, String statechartPackageName, StatechartDefinition gammaStatechart) {
		this.BASE_PACKAGE_NAME = basePackageName
		this.STATECHART_PACKAGE_NAME = statechartPackageName
		this.INTERFACE_NAME = gammaStatechart.name.toFirstUpper + "Interface"
		this.gammaStatechart = gammaStatechart
	}
	
	protected def createStatechartWrapperInterface() '''
		package «STATECHART_PACKAGE_NAME»;
		
		«FOR _package : gammaStatechart.containingPackage.importsWithComponentsOrInterfacesOrTypes.toSet»
			import «_package.getPackageString(BASE_PACKAGE_NAME)».*;
		«ENDFOR»
		
		public interface «INTERFACE_NAME» {
		
			«FOR port : gammaStatechart.ports»
				public «port.implementedInterfaceName» get«port.name.toFirstUpper»();
			«ENDFOR»
			
			void runCycle();
			void reset();
		
		}
	'''
	
	def getInterfaceName() {
		return INTERFACE_NAME
	}
	
}