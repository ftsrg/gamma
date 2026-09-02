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

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.logging.Level;

import org.eclipse.equinox.app.IApplicationContext;

public class HelpHandler extends HeadlessApplicationCommandHandler {
	
	public HelpHandler(IApplicationContext context, String[] appArgs, Level level) {
		super(context, appArgs, level);
	}
	
	public void execute() throws Throwable {
		InputStream inputStream = HelpHandler.class.getClassLoader().getResourceAsStream("docs/headless-gamma-arguments.md");
		try (BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8))) {
			String line = null;
			while ((line = reader.readLine()) != null) {
				System.out.println(line);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
}
