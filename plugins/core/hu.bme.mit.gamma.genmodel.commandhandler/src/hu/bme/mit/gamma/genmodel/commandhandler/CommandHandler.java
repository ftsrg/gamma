/********************************************************************************
 * Copyright (c) 2018-2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.genmodel.commandhandler;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.logging.Logger;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.resources.IFile;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import hu.bme.mit.gamma.dialog.DialogUtil;
import hu.bme.mit.gamma.ui.GammaApi;

public class CommandHandler extends AbstractHandler {
	
	protected static Map<String, Future<?>> futures = new HashMap<String, Future<?>>();
	protected static ExecutorService executor = Executors.newFixedThreadPool(
			Runtime.getRuntime().availableProcessors());
	
	protected final Logger logger = Logger.getLogger("GammaLogger");
	
	//
	
	@Override
	public Object execute(ExecutionEvent event) {
		String fullPath = getFullPath(event);
		
		if (futures.containsKey(fullPath)) {
			Future<?> future = futures.get(fullPath);
			if (future.isDone()) {
				futures.remove(fullPath);
			}
			else {
				String info = fullPath + " is still running";
				System.out.println(info);
				logger.info(info);
				return null;
			}
		}
		
		if (!futures.containsKey(fullPath)) {
			Runnable callable = new Runnable() {
				public void run() {
					start(event);
				}
			};
			Future<?> future = executor.submit(callable);
			futures.put(fullPath, future);
		}
		
		return null;
	}
	
	protected void start(ExecutionEvent event) {
		try {
			String fullPath = getFullPath(event);
			if (fullPath != null) {
				GammaApi gammaApi = new GammaApi();
				gammaApi.run(fullPath);
				// new TaskExecutionTimeMeasurer(10, false, MedianCalculator.INSTANCE, "time.txt", TimeUnit.SECONDS)
			}
		} catch (Throwable exception) {
			exception.printStackTrace();
			String message = exception.getMessage();
			logger.severe(message);
			DialogUtil.showErrorWithStackTrace(message, exception);
		}
	}
	
	//
	
	public static String getFullPath(ExecutionEvent event) {
		ISelection sel = HandlerUtil.getActiveMenuSelection(event);
		if (sel instanceof IStructuredSelection selection) {
			Object firstElement = selection.getFirstElement();
			if (firstElement != null) {
				if (firstElement instanceof IFile file) {
					String fullPath = file.getFullPath().toString();
					return fullPath;
				}
			}
		}
		return null;
	}
	
	public static Map<String, Future<?>> getFutures() {
		return futures;
	}
	
}