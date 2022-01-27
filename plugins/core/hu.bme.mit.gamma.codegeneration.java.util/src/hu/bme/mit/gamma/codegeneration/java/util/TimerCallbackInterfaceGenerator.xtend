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
package hu.bme.mit.gamma.codegeneration.java.util

import hu.bme.mit.gamma.codegeneration.java.util.Namings

class TimerCallbackInterfaceGenerator {
		
	protected final String PACKAGE_NAME
	protected final String INTERFACE_NAME = Namings.TIMER_CALLBACK_INTERFACE
	
	new(String packageName) {
		this.PACKAGE_NAME = packageName
	}
	
	def createITimerCallbackInterfaceCode() '''
		package «PACKAGE_NAME»;
		
		public interface «INTERFACE_NAME» {
			
			void timeElapsed(int eventID);
			
		}
	'''
	
	def getInterfaceName() {
		return INTERFACE_NAME
	}
	
}
