/********************************************************************************
 * Copyright (c) 2024-2025 Contributors to the Gamma project
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

import hu.bme.mit.gamma.util.DualConsoleHandler;
import hu.bme.mit.gamma.util.FileUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

// Abstract class for all Headless Gamma application options
public abstract class HeadlessApplicationCommandHandler {
	//
	final protected IApplicationContext context;
	final protected String[] appArgs;
	final protected Level level;
	//
	protected final FileUtil fileUtil = FileUtil.INSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final Logger logger = Logger.getLogger("GammaLogger");
	//

	public HeadlessApplicationCommandHandler(IApplicationContext context, String[] appArgs, Level level) {
		this.context = context;
		this.appArgs = appArgs;
		this.level = level;
		setupLogger();
	}

	public abstract void execute() throws Exception;
	
	protected void setupLogger() {
		logger.setLevel(level);
		
		logger.setUseParentHandlers(false);
		logger.addHandler(
				new DualConsoleHandler());
	}
	
}
