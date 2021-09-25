/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.genmodel.commandhandler;

import java.util.logging.Level;
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
	
	protected Thread thread = null;
	protected final Logger logger = Logger.getLogger("GammaLogger");

	@Override
	public Object execute(ExecutionEvent event) {
		if (thread == null || !thread.isAlive()) {
			thread = new Thread(
				new Runnable() {
					public void run() {
						try {
							ISelection sel = HandlerUtil.getActiveMenuSelection(event);
							if (sel instanceof IStructuredSelection) {
								IStructuredSelection selection = (IStructuredSelection) sel;
								if (selection.getFirstElement() != null) {
									if (selection.getFirstElement() instanceof IFile) {
										IFile file = (IFile) selection.getFirstElement();
										GammaApi gammaApi = new GammaApi();
										gammaApi.run(file.getFullPath().toString());
									}
								}
							}
						} catch (Exception exception) {
							exception.printStackTrace();
							logger.log(Level.SEVERE, exception.getMessage());
							DialogUtil.showErrorWithStackTrace(exception.getMessage(), exception);
						}
					}
				}
			);
			thread.start();
		}
		else {
			System.out.println(thread.getName() + " is still running");
			logger.log(Level.INFO, thread.getName() + " is still running");
		}
		return null;
	}
	
}