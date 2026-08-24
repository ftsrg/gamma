/********************************************************************************
 * Copyright (c) 2023-2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.genmodel.commandhandler;

import java.util.Map;
import java.util.concurrent.Future;
import java.util.logging.Logger;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;

public class CancelHandler extends AbstractHandler {
	
	protected final Logger logger = Logger.getLogger("GammaLogger");
	//
	
	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		Map<String, Future<?>> futures = CommandHandler.getFutures();
		String fullPath = CommandHandler.getFullPath(event);
		
		if (!futures.containsKey(fullPath)) {
			String infoMessage = "No task has been started for this path: " + fullPath;
			System.out.println(infoMessage);
			logger.info(infoMessage);
			
			return null;
		}
		
		Future<?> future = futures.get(fullPath);
		
		String cancelMessage = "Cancelling task for " + fullPath;
		if (future.isCancelled()) {
			cancelMessage += " again";
		}
		System.out.println(cancelMessage);
		logger.info(cancelMessage);
		
		future.cancel(true);
		
		return null;
	}

}