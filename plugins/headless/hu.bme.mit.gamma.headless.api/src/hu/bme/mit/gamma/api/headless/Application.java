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

import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;

public class Application implements IApplication {
	//
	protected Integer exitCode = IApplication.EXIT_OK;
	//
	protected final Logger logger = Logger.getLogger("GammaLogger");
	//
	@Override
	public Object start(final IApplicationContext context) throws Exception {
		// Use a terminal or git bash for invoking the headless application:
		final Map<?, ?> args = context.getArguments(); // ./eclipse.exe -data ./ws gamma info .../Genmodelfile.ggen
		final String[] appArgs = (String[]) args.get(IApplicationContext.APPLICATION_ARGS);
		
		try {
			if (appArgs.length == 0) {
				logger.warning("No argument given; use any of the following: " + serializeAcceptedArguments());
			}
			else {
				Level level = parseLogLevel(appArgs);
				HeadlessApplicationCommandHandler handler = createHandler(context, appArgs, level);
				handler.execute();
			}
		} catch (Throwable t) {
			// No duplicated error logging - logging must be done at a lower level
			
			exitCode = Integer.valueOf(1); // NOT 0 - could be refined in the future
		}
		// Manual stopping may be needed
		stop();
		//
		return exitCode;
	}

	@Override
	public void stop() {
		logger.info("Headless Gamma application stopped");
	}
	
	//
	
	protected HeadlessApplicationCommandHandler createHandler(
			IApplicationContext context, String[] appArgs, Level level) {
		String argument = appArgs[0];
		switch (argument) {
			case "workspace":
				return new WorkspaceGenerator(context, appArgs, level);
			case "import":
				return new ProjectImporter(context, appArgs, level);
			case "gamma":
				return new GammaEntryPoint(context, appArgs, level);
			default:
				throw new IllegalArgumentException("Invalid argument for operation type: " + argument +
						"; use one of the following: " + serializeAcceptedArguments());
		}
	}

	protected String[] getAcceptedArguments() {
		return new String[] { "workspace", "import", "gamma" };
	}
	
	private Level parseLogLevel(String[] appArgs) {
		if (appArgs.length > 1) {
			String levelString = appArgs[1].toUpperCase();
			try {
				return Level.parse(levelString);
			} catch (IllegalArgumentException e) {
				logger.warning("Invalid argument for setting log level: " + appArgs[1]);
			}
		}
		return Level.INFO;
	}
	
	private String serializeAcceptedArguments() {
		StringBuilder builder = new StringBuilder();
		for (String argument : getAcceptedArguments()) {
			builder.append("\"" + argument + "\", ");
		}
		builder.setLength(builder.length() - 2); // Deleting last ', '
		return builder.toString();
	}
	
}