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

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.headless.application.IVerification;
import hu.bme.mit.gamma.headless.application.VerificationBridge;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.querygenerator.serializer.UppaalPropertySerializer;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.uppaal.composition.transformation.api.util.DefaultCompositionToUppaalTransformer.Result;
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean;

public class UppaalVerification implements IVerification {

	private static final Logger LOGGER = LogManager.getLogger(UppaalVerification.class);

	private final VerificationBridge bridge;

	private List<EObject> verifiedModels;
	private ExecutionTrace trace;

	public UppaalVerification(VerificationBridge bridge) {
		this.bridge = bridge;
	}

	@Override
	public List<EObject> getResultModels() {
		return verifiedModels;
	}

	@Override
	public ExecutionTrace getTrace() {
		return trace;
	}

	@Override
	public ThreeStateBoolean verify() throws IOException {
		Package wrappedGammaStatechart = bridge.getWrappedGammaStatechart();
		Package interfacesPkg = bridge.getNormalGammaStatechart().getImports().get(0);

		LOGGER.info("Transforming G2U.");
		Gamma2UppaalTransformation transformation = new Gamma2UppaalTransformation(interfacesPkg,
				wrappedGammaStatechart);
		Result uppaalTransformationResult = transformation.createUppaalModel();
		LOGGER.info("G2U transformation finished.");

		List<CommentableStateFormula> formulas = bridge.getFormulas();
		String ctlExpression = UppaalPropertySerializer.INSTANCE.serializeCommentableStateFormulas(formulas);
		LOGGER.info(String.format("CTL expression created from Gamma property model: %s", ctlExpression));

		LOGGER.info("Calling uppaal.");
		UppaalQueryRunner uppaalVerifier = new UppaalQueryRunner(uppaalTransformationResult, ctlExpression);
		ThreeStateBoolean verificationResult = uppaalVerifier.verify();
		LOGGER.info(String.format("Verification result from UPPAAL: %s", verificationResult));

		trace = uppaalVerifier.getUppaalTrace();
		if (trace != null) {
			Package flattenedGammaModel = (Package) uppaalTransformationResult.getTopComponent().eContainer();
			verifiedModels = Arrays.asList(flattenedGammaModel, interfacesPkg, trace);
		}

		return verificationResult;
	}
}
