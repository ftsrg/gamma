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

import hu.bme.mit.gamma.codegeneration.java.util.Namings
import hu.bme.mit.gamma.statechart.interface_.Interface

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*

class ChannelInterfaceGenerator {
	
	protected final String PACKAGE_NAME
	//
	protected final extension NameGenerator nameGenerator
	
	new(String packageName) {
		this.PACKAGE_NAME = packageName
		this.nameGenerator = new NameGenerator(this.PACKAGE_NAME)
	}
	
	 /**
	 * Returns the Java interface code of the Channel class.
	 */
	protected def createChannelInterfaceCode(Interface _interface) '''
		package «PACKAGE_NAME».«Namings.CHANNEL_PACKAGE_POSTFIX»;
		
		import «_interface.getPackageString(PACKAGE_NAME)».«_interface.implementationName»;
		
		public interface «_interface.generateChannelInterfaceName» {			
			
			void registerPort(«_interface.implementationName».Provided providedPort);
			
			void registerPort(«_interface.implementationName».Required requiredPort);
		
		}
	'''
}