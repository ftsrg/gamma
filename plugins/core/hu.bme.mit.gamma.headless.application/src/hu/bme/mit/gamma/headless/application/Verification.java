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
package hu.bme.mit.gamma.headless.application;

import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.headless.application.modes.IExecutionMode;
import hu.bme.mit.gamma.headless.application.uppaal.Gamma2UppaalTransformation;
import hu.bme.mit.gamma.headless.application.uppaal.PropertySpecificationTransformation;
import hu.bme.mit.gamma.headless.application.uppaal.UppaalQueryRunner;
import hu.bme.mit.gamma.headless.application.util.gamma.PlantUmlVisualizer;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.uppaal.composition.transformation.api.util.DefaultCompositionToUppaalTransformer.Result;
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace;
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean;

public class Verification {

	private static final Logger LOGGER = LogManager.getLogger(Verification.class);

	private IExecutionMode executionMode;

	public Verification(IExecutionMode mode) {
		this.executionMode = mode;
	}

	public void verify() throws IOException {
		Package wrappedGammaStatechart = executionMode.getWrappedGammaStatechart();
		Package normalGammaStatechart = executionMode.getNormalGammaStatechart();
		PropertySpecification propertySpecification = executionMode.getPropertySpecification();

		LOGGER.info("Transforming G2U.");
		Gamma2UppaalTransformation transformation = new Gamma2UppaalTransformation(normalGammaStatechart,
				wrappedGammaStatechart);
		Result uppaalTransformationResult = transformation.createUppaalModel();

		G2UTrace g2uTrace = uppaalTransformationResult.getTrace();
		SynchronousComponentInstance sci = transformation.getSynchronousComponentInstance();
		LOGGER.info("G2U transformation finished.");

		PropertySpecificationTransformation propertyTransformation = new PropertySpecificationTransformation(
				propertySpecification, sci);
		String ctlExpression = propertyTransformation.getCtlExpression(g2uTrace);
		LOGGER.info("CTL expression is created from property specification.");

		LOGGER.info("Calling uppaal.");
		UppaalQueryRunner uppaalVerifier = new UppaalQueryRunner(uppaalTransformationResult, ctlExpression);
		ThreeStateBoolean verificationResult = uppaalVerifier.verify();
		LOGGER.info(String.format("Verification result from UPPAAL: %s", verificationResult));

		ExecutionTrace uppaalTrace = uppaalVerifier.getUppaalTrace();
		if (uppaalTrace != null) {
			Package flattenedGammaModel = (Package) uppaalTransformationResult.getTopComponent().eContainer();
			Package interfacesPkg = transformation.getInterfacesPkg();
			List<EObject> resultModels = Arrays.asList(flattenedGammaModel, interfacesPkg, uppaalTrace);

			String visualization = PlantUmlVisualizer.toSvg(uppaalTrace);
			executionMode.setVerificationResult(verificationResult, resultModels, visualization);
		} else {
			executionMode.setVerificationResult(verificationResult, Collections.emptyList(), "");
		}
	}

}
