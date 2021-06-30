/********************************************************************************
 * Copyright (c) 2020-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.ui.util;

public class DefaultTaskHook implements TaskHook {
	// Singleton
	public static final DefaultTaskHook INSTANCE = new DefaultTaskHook();
	protected DefaultTaskHook() {}
	//
	
	public int getIterationCount() {
		return 1;
	}
	
	public void startTaskProcess(Object object) {
		
	}
	
	public void startIteration() {
		
	}
	
	public void endIteration() {
		
	}
	
	public void endTaskProcess() {
		
	}
		
}
