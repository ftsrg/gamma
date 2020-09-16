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
package hu.bme.mit.gamma.headless.application.xsts;

import java.io.File;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;

import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.headless.application.IVerification;
import hu.bme.mit.gamma.headless.application.VerificationBridge;
import hu.bme.mit.gamma.headless.application.util.ModelPersistenceUtil;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.querygenerator.serializer.ThetaPropertySerializer;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.theta.verification.ThetaVerifier;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.util.FileUtil;
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean;
import hu.bme.mit.gamma.verification.util.AbstractVerifier;
import hu.bme.mit.gamma.xsts.transformation.GammaToXSTSTransformer;

public class XstsVerification implements IVerification {

	private static final Logger LOGGER = LogManager.getLogger(XstsVerification.class);

	private final VerificationBridge bridge;

	private List<EObject> verifiedModels;
	private ExecutionTrace trace;

	public XstsVerification(VerificationBridge bridge) {
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

	public ThreeStateBoolean verify() throws IOException {
		Package wrappedGammaStatechart = bridge.getWrappedGammaStatechart();
		Package interfacesPkg = bridge.getNormalGammaStatechart().getImports().get(0);

		// prepare transform
		File persistedModels = ModelPersistenceUtil.saveInFile("xstsVerifPreprocessing", "gamma",
				Arrays.asList(interfacesPkg));
		LOGGER.info(String.format("Persisted Gamma models: %s", persistedModels));

		// transform
		LOGGER.info("Transforming G2XSTS.");
		GammaToXSTSTransformer transformer = new GammaToXSTSTransformer();
		String xstsModel = transformer.preprocessAndExecuteAndSerialize(wrappedGammaStatechart, persistedModels);
		File xstsFile = hu.bme.mit.gamma.headless.application.util.FileUtil.createThetaTempFile("xsts");
		FileUtil.INSTANCE.saveString(xstsFile, xstsModel);
		LOGGER.info(String.format("XSTS model: %s", xstsFile));

		// create query
		List<CommentableStateFormula> formulas = bridge.getFormulas();
		String expression = ThetaPropertySerializer.INSTANCE.serializeCommentableStateFormulas(formulas);
		LOGGER.info(String.format("Checkable expression created from Gamma property model: %s", expression));

		// verify
		AbstractVerifier verifier = new ThetaVerifier();
		trace = verifier.verifyQuery(wrappedGammaStatechart, "", xstsFile, expression, false, false);
		if (trace != null) {
			verifiedModels = Arrays.asList(wrappedGammaStatechart, interfacesPkg, trace);
		}

		ThreeStateBoolean verificationResult = verifier.getResult();
		LOGGER.info(String.format("Verification result from UPPAAL: %s", verificationResult));

		return verificationResult;
	}

}