/********************************************************************************
 * Copyright (c) 2025 Contributors to the Gamma project
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

public class DummyHandler extends HeadlessApplicationCommandHandler {

	public DummyHandler(IApplicationContext context, String[] appArgs, Level level) {
		super(context, appArgs, level);
	}

	@Override
	public void execute() throws Throwable {
		// Left empty intentionally
	}

}
