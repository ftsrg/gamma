/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.application;

import org.eclipse.core.resources.IFile;

// Application class
// This class includes the entry point of the application
public class AppMain  {
	
	public void start(IFile file) {
		try {
			View frame = new View(file);
			frame.setTitle("UPPAAL Query Generator");
			frame.setVisible(true);
			frame.setResizable(false);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

}
