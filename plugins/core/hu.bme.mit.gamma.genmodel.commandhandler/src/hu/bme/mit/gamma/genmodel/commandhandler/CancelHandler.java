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

import java.lang.Thread.State;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;

public class CancelHandler extends AbstractHandler {
	
	protected final Logger logger = Logger.getLogger("GammaLogger");

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		Thread thread = CommandHandler.getThread();
		
		State threadState = thread.getState();
		boolean isInterruptible = threadState == State.BLOCKED || threadState == State.WAITING;
		if (!isInterruptible) {
			System.out.println("The thread is not in an interruptable state: " + threadState);
			logger.log(Level.INFO, "The thread is not in an interruptable state: " + threadState);
			
			return null;
		}
		
		thread.interrupt();
		
		System.out.println("Cancelling thread " + thread.getName());
		logger.log(Level.INFO, "Cancelling thread " + thread.getName());
		
		return null;
	}

}
