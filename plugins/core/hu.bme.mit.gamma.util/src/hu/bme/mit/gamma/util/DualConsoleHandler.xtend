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
package hu.bme.mit.gamma.util

import java.util.logging.ConsoleHandler
import java.util.logging.Level
import java.util.logging.LogRecord
import java.util.logging.Logger
import java.util.logging.SimpleFormatter
import java.util.logging.StreamHandler

class DualConsoleHandler extends StreamHandler {

	protected final Level minimumLogLevel = Level.INFO
	protected final ConsoleHandler stderrHandler = new ConsoleHandler

	new() {
		super(System.out, new SimpleFormatter)
	}

	override synchronized publish(LogRecord record) {
		if (record.level.intValue <= minimumLogLevel.intValue) {
			super.publish(record)
			super.flush
		}
		else {
			stderrHandler.publish(record)
			stderrHandler.flush
		}
	}
	
	def static register(Logger logger) {
		logger.setUseParentHandlers(false)
		logger.addHandler(new DualConsoleHandler)
	}

}