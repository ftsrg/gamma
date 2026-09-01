/********************************************************************************
 * Copyright (c) 2026 Contributors to the Gamma project
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

public class HelpHandler extends HeadlessApplicationCommandHandler {

	public HelpHandler(IApplicationContext context, String[] appArgs, Level level) {
		super(context, appArgs, level);
	}

	public void execute() throws Throwable {
		final String message = """
			Use: 'eclipse -data workspace-folder scope log-level ggen-file [task] [backend]', e.g., './eclipse.exe -data ./ws gamma info ./Genmodelfile.ggen'
		""";
		System.out.println(message);
	}
}
