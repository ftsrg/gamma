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
import org.eclipse.core.commands.Command;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;

public class CancelHandler extends AbstractHandler {
	
	protected final Logger logger = Logger.getLogger("GammaLogger");

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		Thread thread = CommandHandler.getThread();
		if (thread == null) {
			System.out.println("No task has been started");
			logger.log(Level.INFO, "No task has been started");
			
			return null;
		}
		
		Command command = event.getCommand();
		String name = command.getId();
		boolean isForceCancel = name.equals("hu.bme.mit.gamma.ui.cancel.force");
		
		State threadState = thread.getState();
		boolean isInterruptible = threadState == State.BLOCKED || threadState == State.WAITING;
		
		boolean toBeCancelled = isForceCancel || isInterruptible;
		if (!toBeCancelled) {
			System.out.println("The thread is not in an interruptable state: " + threadState);
			logger.log(Level.INFO, "The thread is not in an interruptable state: " + threadState);
			
			return null;
		}
		
		thread.interrupt();
		
		String threadName = thread.getName();
		System.out.println("Cancelling thread " + threadName);
		logger.log(Level.INFO, "Cancelling thread " + threadName);
		
		return null;
	}

}
