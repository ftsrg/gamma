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

import java.io.File;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

import org.apache.log4j.Level;
import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;
import org.apache.log4j.varia.LevelRangeFilter;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;

import hu.bme.mit.gamma.headless.application.io.VerificationBackend;
import hu.bme.mit.gamma.headless.application.uppaal.UppaalVerification;
import hu.bme.mit.gamma.headless.application.util.PlantUmlVisualizer;
import hu.bme.mit.gamma.headless.application.xsts.XstsVerification;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean;

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
	 * start: ./eclipse <path-of-serialized-request-file>
	 * 
	 * @see serialized request is a persisted {VerificationRequest} object
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

		VerificationBridge bridge = null;
		try {
			bridge = new VerificationBridge(getRequestPath(context));
			VerificationBackend backend = bridge.getBackend();

			IVerification verification = null;
			switch (backend) {
			case UPPAAL:
				verification = new UppaalVerification(bridge);
				break;
			case THETA:
				verification = new XstsVerification(bridge);
				break;
			default:
				throw new IllegalArgumentException(String.format("Unsupported verification backend: %s", backend));
			}

			ThreeStateBoolean verificationResult = verification.verify();
			ExecutionTrace trace = verification.getTrace();
			if (trace != null) {
				String visualization = PlantUmlVisualizer.toSvg(trace);
				List<EObject> resultModels = verification.getResultModels();
				bridge.setVerificationResult(verificationResult, resultModels, visualization);
			} else {
				bridge.setVerificationResult(verificationResult, Collections.emptyList(), "");
			}

			bridge.submitResult();

			return 0;
		} catch (Exception ex) {
			LOGGER.error(ex.getMessage(), ex);

			if (bridge != null) {
				bridge.handleError(ex);
				return 2;
			} else {
				return 1;
			}
		}
	}

	@Override
	public void stop() {
	}

	public String getRequestPath(IApplicationContext context) throws IOException {
		@SuppressWarnings("unchecked")
		String[] args = (String[]) context.getArguments().getOrDefault(APPLICATION_ARGS, new String[0]);
		List<String> arguments = Arrays.asList(args).stream().map(it -> it.replace("\"", ""))
				.collect(Collectors.toList());

		if (!arguments.isEmpty()) {
			String pathParam = arguments.get(0);
			File file = new File(pathParam);
			if (file.exists()) {
				return pathParam;
			}
		}

		throw new IOException("First argument does not refer to a persisted verification request.");
	}

}
