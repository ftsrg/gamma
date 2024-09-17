/********************************************************************************
 * Copyright (c) 2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.api.headless;

import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.equinox.app.IApplicationContext;

// Abstract class for all Headless Gamma application options
public abstract class HeadlessApplicationCommandHandler {
	//
	final IApplicationContext context;
	final String[] appArgs;
	final Level level;
	//
	protected Logger logger = Logger.getLogger("GammaLogger");
	//

	public HeadlessApplicationCommandHandler(IApplicationContext context, String[] appArgs, Level level) {
		this.context = context;
		this.appArgs = appArgs;
		this.level = level;
	}

	public abstract void execute() throws Exception;
	
}
