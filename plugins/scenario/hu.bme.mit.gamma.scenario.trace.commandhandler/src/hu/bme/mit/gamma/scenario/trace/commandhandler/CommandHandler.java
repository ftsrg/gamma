/********************************************************************************
 * Copyright (c) 2020-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.trace.commandhandler;

import java.io.File;
import java.util.List;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import hu.bme.mit.gamma.scenario.trace.generator.ScenarioStatechartTraceGenerator;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class CommandHandler extends AbstractHandler {

	@Override
	public Object execute(ExecutionEvent event) {
		ISelection sel = HandlerUtil.getActiveMenuSelection(event);
		if (sel instanceof IStructuredSelection) {
			IStructuredSelection selection = (IStructuredSelection) sel;
			if (selection.size() == 1) {
				if (selection.getFirstElement() instanceof IFile) {
					IFile firstElement = (IFile) selection.getFirstElement();
					ResourceSet resSet = new ResourceSetImpl();
					URI compositeSystemURI = URI.createPlatformResourceURI(firstElement.getFullPath().toString(), true);
					Resource resource = resSet.getResource(compositeSystemURI, true);
					Package p = (Package) resource.getContents().get(0);
					StatechartDefinition scd = (StatechartDefinition) p.getComponents().get(0);
					String absoluteParentFolder = firstElement.getParent().getLocation().toString();
					ScenarioStatechartTraceGenerator validator = new ScenarioStatechartTraceGenerator(scd,0);
					List<ExecutionTrace> result = validator.execute();
					for (ExecutionTrace e : result) {
						URI uri = URI.createFileURI(URI.decode(absoluteParentFolder + File.separator + "trace"
								+ File.separator + e.getName() + ".get"));
						GammaEcoreUtil.INSTANCE.normalSave(e, uri);
					}
				}
			}
		}
		return null;
	}
}
