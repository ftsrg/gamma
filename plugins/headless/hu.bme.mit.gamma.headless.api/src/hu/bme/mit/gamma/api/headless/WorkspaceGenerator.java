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

import org.eclipse.core.resources.IWorkspace;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.equinox.app.IApplicationContext;

// Creates a workspace
public class WorkspaceGenerator extends HeadlessApplicationCommandHandler {

	public WorkspaceGenerator(IApplicationContext context, String[] appArgs, Level level) {
		super(context, appArgs, level);
		logger.setLevel(level);
	}

	public void execute() throws Exception {
		// The workspace will be generated at the destination specified after the -data argument
		IWorkspace workspace = ResourcesPlugin.getWorkspace();
		logger.info("Workspace generated successfully");
	}
}
