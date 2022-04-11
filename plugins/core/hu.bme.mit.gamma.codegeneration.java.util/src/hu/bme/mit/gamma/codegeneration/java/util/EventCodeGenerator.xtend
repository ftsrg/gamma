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

class EventCodeGenerator {
	
	protected final String PACKAGE_NAME
	protected final String CLASS_NAME = Namings.GAMMA_EVENT_CLASS
	
	new(String packageName) {
		this.PACKAGE_NAME = packageName
	}
	
	def createEventClass() '''
		package «PACKAGE_NAME»;
		
		public class «CLASS_NAME» {
			private String event;
			private Object[] value;
			
			public Event(String event) {
				this.event = event;
			}
			
			public Event(String event, Object... value) {
				this.event = event;
				this.value = value;
			}
			
			public String getEvent() {
				return event;
			}
			
			public Object[] getValue() {
				return value;
			}
		}
	'''
	
	def getClassName() {
		return CLASS_NAME
	}
	
}