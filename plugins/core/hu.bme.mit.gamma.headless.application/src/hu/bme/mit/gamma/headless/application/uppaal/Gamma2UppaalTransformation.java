/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.headless.application.uppaal;

import java.io.File;
import java.util.Arrays;

import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;
import org.eclipse.emf.common.util.URI;

import hu.bme.mit.gamma.headless.application.util.ModelPersistenceUtil;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.uppaal.composition.transformation.api.util.DefaultCompositionToUppaalTransformer;
import hu.bme.mit.gamma.uppaal.composition.transformation.api.util.DefaultCompositionToUppaalTransformer.Result;

public class Gamma2UppaalTransformation {

	private static final Logger LOGGER = LogManager.getLogger(Gamma2UppaalTransformation.class);

	private final Package wrappedGammaStatechart;
	private final Package interfacesPkg;

	private final SynchronousComponentInstance sci;

	public Gamma2UppaalTransformation(Package normalGammaStatechart, Package wrappedGammaStatechart) {
		this.interfacesPkg = normalGammaStatechart.getImports().get(0);
		this.wrappedGammaStatechart = wrappedGammaStatechart;
		this.sci = StatechartModelDerivedFeatures.getAllSimpleInstances(wrappedGammaStatechart.getComponents().get(0))
				.get(0);
	}

	public Package getInterfacesPkg() {
		return interfacesPkg;
	}

	public SynchronousComponentInstance getSynchronousComponentInstance() {
		return sci;
	}

	public Result createUppaalModel() {
		URI persistedResourcesUri = ModelPersistenceUtil.saveInOneResource("verificationPreprocessing", "gamma",
				Arrays.asList(interfacesPkg));
		String persistedResourcesPath = persistedResourcesUri.toFileString();
		File persistedModels = new File(persistedResourcesPath);
		LOGGER.info(String.format("Persisted gamma models: %s", persistedResourcesPath));

		DefaultCompositionToUppaalTransformer transformer = new DefaultCompositionToUppaalTransformer();
		Result result = transformer.transformComponent(wrappedGammaStatechart, persistedModels);

		File ntaFile = result.getModelFile();
		LOGGER.info(String.format("NTA file: %s", ntaFile));
		File queryFile = result.getQueryFile();
		LOGGER.info(String.format("UPPAAL query file: %s", queryFile));

		return result;
	}

}
