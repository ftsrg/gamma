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

class TimerInterfaceGenerator {
	
	protected final String PACKAGE_NAME
	
	new(String packageName) {
		this.PACKAGE_NAME = packageName
	}
	
	def createITimerInterfaceCode() '''
		package «PACKAGE_NAME»;
		
		public interface «Namings.YAKINDU_TIMER_INTERFACE» {
			
			void setTimer(«Namings.TIMER_CALLBACK_INTERFACE» callback, int eventID, long time, boolean isPeriodic);
			void unsetTimer(«Namings.TIMER_CALLBACK_INTERFACE» callback, int eventID);
			
		}
	'''
	
	def createGammaTimerInterfaceCode() '''
		package «PACKAGE_NAME»;
		
		public interface «Namings.GAMMA_TIMER_INTERFACE» {
			
			public void saveTime(Object object);
			public long getElapsedTime(Object object, TimeUnit timeUnit);
			
			public enum TimeUnit {
				SECOND, MILLISECOND, MICROSECOND, NANOSECOND
			}
			
		}
	'''
	
	def createUnifiedTimerInterfaceCode() '''
		package «PACKAGE_NAME»;
		
		public interface «Namings.UNIFIED_TIMER_INTERFACE» extends «Namings.YAKINDU_TIMER_INTERFACE», «Namings.GAMMA_TIMER_INTERFACE» {
			
		}
	'''
	
	def getYakinduInterfaceName() {
		return Namings.YAKINDU_TIMER_INTERFACE
	}
	
	def getGammaInterfaceName() {
		return Namings.GAMMA_TIMER_INTERFACE
	}
	
	def getUnifiedInterfaceName() {
		return Namings.UNIFIED_TIMER_INTERFACE
	}
	
}