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
package hu.bme.mit.gamma.scenario.statechart.commandhandler;

import java.util.ArrayList;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration;
import hu.bme.mit.gamma.scenario.model.ScenarioDefinition;
import hu.bme.mit.gamma.scenario.reduction.SimpleScenarioGenerator;
import hu.bme.mit.gamma.scenario.statechart.generator.StatechartGenerator;
import hu.bme.mit.gamma.scenario.statechart.generator.serializer.StatechartSerializer;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;

public class CommandHandler extends AbstractHandler {

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		ISelection sel = HandlerUtil.getActiveMenuSelection(event);
		if (sel instanceof IStructuredSelection) {
			IStructuredSelection selection = (IStructuredSelection) sel;
			if (selection.size() == 1) {
				if (selection.getFirstElement() instanceof IFile) {
					IFile firstElement = (IFile) selection.getFirstElement();
					ResourceSet resSet = new ResourceSetImpl();

					URI compositeSystemURI = URI.createPlatformResourceURI(firstElement.getFullPath().toString(), true);

					Resource resource = resSet.getResource(compositeSystemURI, true);

					ScenarioDeclaration scenariodekl = (ScenarioDeclaration) resource.getContents().get(0);
					Component comp = scenariodekl.getComponent();
					ArrayList<Interface> is = new ArrayList<>();
					for (Port p : comp.getPorts()) {
						is.add(p.getInterfaceRealization().getInterface());
					}
					StatechartSerializer statechartSerializer = new StatechartSerializer(firstElement);
					hu.bme.mit.gamma.statechart.interface_.Package interfaces = statechartSerializer.saveInterfaces(is,
							firstElement.getParent().getLocation().toString(), comp.getName());
					for (int i = 0; i < scenariodekl.getScenarios().size(); i++) {
						SimpleScenarioGenerator simpleGenerator = new SimpleScenarioGenerator();
						ScenarioDefinition sdef = simpleGenerator.generateSimple(scenariodekl.getScenarios().get(i));
						StatechartGenerator statechartGenerator = new StatechartGenerator(true);
						StatechartDefinition statechart = statechartGenerator.generateStatechart(sdef, comp);
						statechartSerializer.saveStatechart(statechart, interfaces,
								firstElement.getParent().getLocation().toString());
					}
				}
			}
		}
		return null;
	}
}
