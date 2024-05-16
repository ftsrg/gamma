/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
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
import org.eclipse.core.resources.IFile;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import hu.bme.mit.gamma.dialog.DialogUtil;
import hu.bme.mit.gamma.ui.GammaApi;
import hu.bme.mit.gamma.util.InterruptableCallable;
import hu.bme.mit.gamma.util.ThreadRacer;

public class CommandHandler extends AbstractHandler {
	//
	protected static Thread thread = null;
	protected static ThreadRacer<Void> threadRacer = null;
	//
	protected final Logger logger = Logger.getLogger("GammaLogger");
	//
	@Override
	public Object execute(ExecutionEvent event) {
		if (threadRacer == null || threadRacer.isTerminated()) {
			threadRacer = new ThreadRacer<Void>(
				new InterruptableCallable<Void>() {
					public Void call() throws Exception {
						start(event);
						return null;
					}
					public void cancel() {
						// No operation
					}
				}
			);
			thread = new Thread(
				new Runnable() {
					public void run() {
						threadRacer.execute();
					}
				}
			);
			thread.start();
		}
		else {
			String name = thread.getName();
			String info = name + " is still running";
			System.out.println(info);
			logger.info(info);
		}
		
		return null;
	}
	
	protected void start(ExecutionEvent event) {
		try {
			ISelection sel = HandlerUtil.getActiveMenuSelection(event);
			if (sel instanceof IStructuredSelection selection) {
				Object firstElement = selection.getFirstElement();
				if (firstElement != null) {
					if (firstElement instanceof IFile file) {
						GammaApi gammaApi = new GammaApi();
						gammaApi.run(
								file.getFullPath().toString());
						// new TaskExecutionTimeMeasurer(10, false, MedianCalculator.INSTANCE, "time.txt", TimeUnit.SECONDS)
					}
				}
			}
		} catch (Exception exception) {
			exception.printStackTrace();
			String message = exception.getMessage();
			logger.severe(message);
			DialogUtil.showErrorWithStackTrace(message, exception);
		}
	}
	
	//
	
	public static Thread getThread() {
		return thread;
	}
	
	public static ThreadRacer<Void> getThreadRacer() {
		return threadRacer;
	}
	
}