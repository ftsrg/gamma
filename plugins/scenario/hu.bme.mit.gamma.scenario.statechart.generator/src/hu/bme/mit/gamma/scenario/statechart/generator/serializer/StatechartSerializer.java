/********************************************************************************
 * Copyright (c) 2020-2022 Contributors to the Gamma project
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
import java.util.Collection;
import java.util.List;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.statechart.contract.ScenarioContractAnnotation;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.ComponentAnnotation;
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

	public void saveStatechart(StatechartDefinition statechart,
				Collection<? extends Package> interfaces, String path) {
		Package _package = interfacefactory.createPackage();
		_package.getComponents().add(statechart);
		_package.setName(statechart.getName().toLowerCase());
		_package.getImports().addAll(interfaces);

		List<ComponentAnnotation> annotations = statechart.getAnnotations();
		for (ComponentAnnotation annotation : annotations) {
			if (annotation instanceof ScenarioContractAnnotation) {
				ScenarioContractAnnotation scenarioContractAnnotation = (ScenarioContractAnnotation) annotation;
				Component monitoredComponent = scenarioContractAnnotation.getMonitoredComponent();
				Package containingPackage = StatechartModelDerivedFeatures.getContainingPackage(monitoredComponent);
				_package.getImports().add(containingPackage);
			}
		}
		try {
			saveModel(_package, path, statechart.getName() + ".gcd");
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
