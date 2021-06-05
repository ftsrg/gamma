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
package hu.bme.mit.gamma.scenario.statechart.generator.serializer;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.statechart.contract.ScenarioContractAnnotation;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.language.ui.serializer.StatechartLanguageSerializer;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory;

public class StatechartSerializer {

	protected InterfaceModelFactory interfacefactory = InterfaceModelFactory.eINSTANCE;
	protected StatechartModelFactory factory = StatechartModelFactory.eINSTANCE;
	protected final IFile file;
	protected final String projectLocation;

	public StatechartSerializer(IFile file) {
		this.file = file;
		this.projectLocation = file.getProject().getLocation().toString();
	}

	public void saveStatechart(StatechartDefinition st, List<Package> interfaces, String path) {
		Package p = interfacefactory.createPackage();
		p.getComponents().add(st);
		p.setName(st.getName().toLowerCase());
		p.getImports().addAll(interfaces);

		if (st.getAnnotation() instanceof ScenarioContractAnnotation) {
			Component monitoredComponent = ((ScenarioContractAnnotation) st.getAnnotation()).getMonitoredComponent();
			p.getImports().add((Package) monitoredComponent.eContainer());
		}
		try {
			saveModel(p, path, st.getName() + "Statechart.gcd");
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	protected void saveModel(EObject rootElem, String parentFolder, String fileName) throws IOException {
		try {
			if (rootElem instanceof Package) {
				serializeStatechart(rootElem, parentFolder, fileName);
				return;
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		new File(parentFolder + File.separator + fileName).delete();
	}

	private void serializeStatechart(EObject rootElem, String parentFolder, String fileName) throws IOException {
		StatechartLanguageSerializer serializer = new StatechartLanguageSerializer();
		serializer.serialize(rootElem, parentFolder, fileName);
	}
}
