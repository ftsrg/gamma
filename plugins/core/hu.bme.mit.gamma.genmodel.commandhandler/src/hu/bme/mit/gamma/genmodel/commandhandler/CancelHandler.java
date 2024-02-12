/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.genmodel.commandhandler;

import java.util.logging.Logger;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;

import hu.bme.mit.gamma.util.ThreadRacer;

public class CancelHandler extends AbstractHandler {
	//
	protected final Logger logger = Logger.getLogger("GammaLogger");
	//
	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		ThreadRacer<Void> threadRacer = CommandHandler.getThreadRacer();
		Thread thread = CommandHandler.getThread();
		
		if (threadRacer == null || threadRacer.isTerminated()) {
			String infoMessage = "No task has been started";
			System.out.println(infoMessage);
			logger.info(infoMessage);
			
			return null;
		}
		
		String cancelMessage = "Cancelling thread";
		System.out.println(cancelMessage);
		logger.info(cancelMessage);
		
		threadRacer.shutdown();
		thread.setDaemon(true);
		
		return null;
	}

}
