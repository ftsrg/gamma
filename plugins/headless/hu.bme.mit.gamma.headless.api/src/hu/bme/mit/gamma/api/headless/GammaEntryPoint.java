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

import org.eclipse.equinox.app.IApplicationContext;
import org.eclipse.xtext.ISetup;

import hu.bme.mit.gamma.statechart.language.StatechartLanguageStandaloneSetupGenerated;
import hu.bme.mit.gamma.ui.GammaApi;

// This is the entry point for the Headless Gamma
public class GammaEntryPoint extends AbstractEntryPoint {

	public GammaEntryPoint(IApplicationContext context, String[] appArgs, Level level) {
		super(context, appArgs, level);
		logger.setLevel(level);
	}
	
	@Override
	protected void run(String fileWorkspaceRelativePath) throws Exception {
		GammaApi gammaApi = new GammaApi();
		gammaApi.run(fileWorkspaceRelativePath, createResourceSetCreator());
	}

	@Override
	protected ISetup getLanguageSetup() {
		return new StatechartLanguageStandaloneSetupGenerated();
	}

	@Override
	protected void setupXtext()  {
		setupGammaXtext();
	}

	@Override
	protected void setup() {}
	
}