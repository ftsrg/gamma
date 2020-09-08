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
package hu.bme.mit.gamma.headless.application;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

import org.apache.log4j.Level;
import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;
import org.apache.log4j.varia.LevelRangeFilter;
import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;

import hu.bme.mit.gamma.headless.application.modes.IExecutionMode;
import hu.bme.mit.gamma.headless.application.modes.ModelWithCtlMode;
import hu.bme.mit.gamma.headless.application.modes.SerializedRequestMode;
import hu.bme.mit.gamma.headless.application.util.StringUtil;

public class Application implements IApplication {

	private static final Logger LOGGER;
	private static final String APPLICATION_ARGS;
	private static final boolean LOG_STARTUP_TIME;

	static {
		PropertyConfigurator.configure(Application.class.getResource("/resources/log4j.properties"));

		// HACK: this should be in log4j.properties
		// however,
		// log4j.appender.stdout.filter.a=org.apache.log4j.varia.LevelRangeFilter
		// log4j.appender.stdout.filter.a.LevelMax=WARN
		// did not work.
		LevelRangeFilter filter = new LevelRangeFilter();
		filter.setLevelMax(Level.WARN);
		LogManager.getRootLogger().getAppender("stdout").addFilter(filter);

		LOGGER = LogManager.getLogger(Application.class);
		APPLICATION_ARGS = IApplicationContext.APPLICATION_ARGS;
		LOG_STARTUP_TIME = false;
	}

	/**
	 *@formatter:off
	 *
	 * start: ./eclipse serializedRequest <path-of-serialized-request-file>
	 * 
	 * start: ./eclipse modelWithCtl <file-uri-of-models> <file-uri-of-ctl-expression-model>
	 * 
	 *@formatter:on
	 */
	@Override
	public Object start(IApplicationContext context) throws Exception {
		if (LOG_STARTUP_TIME) {
			DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss:A");
			LocalDateTime now = LocalDateTime.now();
			LOGGER.debug(String.format("Eclipse stared at %s", dtf.format(now)));
		}

		IExecutionMode executionMode = null;
		try {
			executionMode = getExecutionMode(context);

			if (executionMode != null) {
				Verification verification = new Verification(executionMode);
				verification.verify();
				executionMode.finish();
				return 0;
			} else {
				String unknownStartParamsError = String.format(
						"Unknown start parameters. Use either: \"%s <path-of-serialized-request-file>\" or \"%s <file-uri-of-models> <ctl-expression>\"",
						IExecutionMode.SERIALIZED_REQUEST_MODE, IExecutionMode.MODEL_WITH_CTL_MODE);
				LOGGER.error(unknownStartParamsError);
				return 1;
			}
		} catch (Exception ex) {
			if (executionMode != null) {
				executionMode.handleError(ex);
			}
			LOGGER.error(ex.getMessage(), ex);
			return 2;
		}
	}

	@Override
	public void stop() {
	}

	public IExecutionMode getExecutionMode(IApplicationContext context) {
		@SuppressWarnings("unchecked")
		String[] args = (String[]) context.getArguments().getOrDefault(APPLICATION_ARGS, new String[0]);
		List<String> arguments = Arrays.asList(args).stream().map(StringUtil::removeQuotes)
				.collect(Collectors.toList());

		if (arguments.size() > 1) {
			String modeStr = arguments.get(0);
			if (IExecutionMode.SERIALIZED_REQUEST_MODE.equals(modeStr) && arguments.size() == 2) {
				return new SerializedRequestMode(arguments.get(1));
			} else if (IExecutionMode.MODEL_WITH_CTL_MODE.equals(modeStr) && arguments.size() == 3) {
				return new ModelWithCtlMode(arguments.get(1), arguments.get(2));
			}
		}

		return null;
	}

}
