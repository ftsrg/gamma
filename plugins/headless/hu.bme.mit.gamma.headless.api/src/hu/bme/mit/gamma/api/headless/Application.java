/********************************************************************************
 * Copyright (c) 2024-2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.api.headless;

import java.util.Arrays;
import java.util.Map;
import java.util.Scanner;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;

import hu.bme.mit.gamma.util.DualConsoleHandler;

public class Application implements IApplication {
	//
	protected Integer exitCode = IApplication.EXIT_OK;
	protected final String WORKSPACE_ARG = "workspace";
	protected final String SESSION_ARG = "session";
	protected final String EXIT_SESSION_ARG = "exit";
	protected final String HELP_ARG = "help";
	protected final String _H_ARG = "-h";
	protected final String _HELP_ARG = "--help";
	//
	protected final Logger logger = Logger.getLogger("GammaLogger");
	//
	
	@Override
	public Object start(final IApplicationContext context) throws Exception {
		// Use a terminal or git bash for invoking the headless application:
		final Map<?, ?> args = context.getArguments(); // ./eclipse.exe -data ./ws gamma info .../Genmodelfile.ggen
		String[] appArgs = (String[]) args.get(IApplicationContext.APPLICATION_ARGS);
		
		DualConsoleHandler.register(logger);
		Scanner scanner = null;
		try {
			if (appArgs.length == 0) {
				logger.warning("No argument given; use any of the following: " + serializeAcceptedArguments());
			}
			else {
				boolean runSession = SESSION_ARG.equals(appArgs[0]);
				do {
					if (runSession) {
						if (scanner == null) {
							// First iteration: creating the workspace
							logAndPrintln("Session mode started...");
							scanner = new Scanner(System.in);
							appArgs = new String[] { WORKSPACE_ARG };
						}
						else {
							// Reading new command
							logAndPrintln("Waiting for input...");
							String line = scanner.nextLine();
							appArgs = line.split("\\s+");
							String firstArg = appArgs[0];
							runSession = !firstArg.equals(EXIT_SESSION_ARG) &&
									Arrays.asList(getAcceptedArguments()).contains(firstArg); // If false, then "DummyHandler" will be selected later
						}
					}
					
					try {
						Level level = parseLogLevel(appArgs);
						var handler = createHandler(context, appArgs, level);
						handler.execute();
					} catch (Throwable t) {
						// Staying in the session even if an exception occurs
						if (!runSession) {
							throw t;
						}
					}
				} while (runSession);
			}
		} catch (Throwable t) {
			// No duplicated error logging - logging must be done at a lower level
			
			exitCode = Integer.valueOf(1); // NOT 0 - could be refined in the future
		} finally {
			if (scanner != null) {
				scanner.close();
			}
		}
		// Manual stopping may be needed
		stop();
		
		return exitCode;
	}

	@Override
	public void stop() {
		logAndPrintln("Headless Gamma application stopped");
	}
	
	protected void logAndPrintln(String string) {
		logAndPrintln(Level.INFO, string);
	}
	
	protected void logAndPrintln(Level level, String string) {
		logger.log(level, string);
		System.out.println(string); // Needed for communication with a caller process
	}
	
	protected HeadlessApplicationCommandHandler createHandler(
			IApplicationContext context, String[] appArgs, Level level) {
		String argument = appArgs[0];
		switch (argument) {
			case HELP_ARG, _HELP_ARG, _H_ARG:
				return new HelpHandler(context, appArgs, level);
			case WORKSPACE_ARG:
				return new WorkspaceGenerator(context, appArgs, level);
			case "import":
				return new ProjectImporter(context, appArgs, level);
			case "gamma":
				return new GammaEntryPoint(context, appArgs, level);
			case "exit":
				return new DummyHandler(context, appArgs, level);
			default:
				String message = "Invalid argument for operation type: " + argument +"; use one of the following: " + serializeAcceptedArguments();
				System.err.println(message);
				throw new IllegalArgumentException(message);
		}
	}

	protected String[] getAcceptedArguments() {
		return new String[] { WORKSPACE_ARG, "import", "gamma", SESSION_ARG, EXIT_SESSION_ARG, HELP_ARG };
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