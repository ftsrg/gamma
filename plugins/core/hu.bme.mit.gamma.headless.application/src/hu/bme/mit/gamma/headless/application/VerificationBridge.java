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

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.List;

import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;

import hu.bme.mit.gamma.headless.application.io.ErrorResult;
import hu.bme.mit.gamma.headless.application.io.PropertyHoldsEnum;
import hu.bme.mit.gamma.headless.application.io.VerificationBackend;
import hu.bme.mit.gamma.headless.application.io.VerificationRequest;
import hu.bme.mit.gamma.headless.application.io.VerificationResponse;
import hu.bme.mit.gamma.headless.application.io.VerificationResult;
import hu.bme.mit.gamma.headless.application.util.FileUtil;
import hu.bme.mit.gamma.headless.application.util.ModelPersistenceUtil;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean;

public class VerificationBridge {

	private static final Logger LOGGER = LogManager.getLogger(VerificationBridge.class);

	private String inputFilePath;

	private Resource statechartModelsResource;
	private PropertyPackage propertyPackage;
	private VerificationBackend backend;

	private ThreeStateBoolean verificationResult;
	private List<EObject> resultModels;
	private String visualization;

	public VerificationBridge(String inputFilePath) {
		this.inputFilePath = inputFilePath;
	}

	private void load() {
		if (statechartModelsResource == null && propertyPackage == null) {
			LOGGER.info("Deserializing request.");
			try (ObjectInputStream ois = new ObjectInputStream(new FileInputStream(inputFilePath))) {
				VerificationRequest request = (VerificationRequest) ois.readObject();
				backend = request.getBackend();
				LOGGER.info("Deserialization finished.");

				ResourceSet resourceSet = new ResourceSetImpl();
				LOGGER.info("Loading statechart model from resource.");
				statechartModelsResource = ModelPersistenceUtil.loadResourceWithSerializedUri(request.getModels(),
						resourceSet);
				LOGGER.info("Statechart model loaded.");

				LOGGER.info("Loading property specification from resource.");
				Resource resource = ModelPersistenceUtil.loadResourceWithSerializedUri(request.getExpression(),
						resourceSet);
				propertyPackage = (PropertyPackage) resource.getContents().get(0);
				LOGGER.info("Property specification loaded.");
			} catch (IOException | ClassNotFoundException e) {
				throw new RuntimeException(e);
			}
		}
	}

	public Package getWrappedGammaStatechart() {
		load();
		return getPackage(0);
	}

	public Package getNormalGammaStatechart() {
		load();
		return getPackage(1);
	}

	public List<CommentableStateFormula> getFormulas() {
		load();
		return propertyPackage.getFormulas();
	}

	public VerificationBackend getBackend() {
		load();
		return backend;
	}

	public void setVerificationResult(ThreeStateBoolean result, List<EObject> models, String visualization) {
		this.verificationResult = result;
		this.resultModels = models;
		this.visualization = visualization;
	}

	public void handleError(Exception ex) {
		VerificationResponse result = new VerificationResponse(new ErrorResult(ex.getMessage(), ex.getStackTrace()));
		printSerializedPath(result);
	}

	public void submitResult() {
		PropertyHoldsEnum checkedProperty = null;
		switch (verificationResult) {
		case TRUE:
			checkedProperty = PropertyHoldsEnum.SATISFIED;
			break;
		case FALSE:
			checkedProperty = PropertyHoldsEnum.VIOLATED;
			break;
		default:
			checkedProperty = PropertyHoldsEnum.INCONCLUSIVE;
		}

		LOGGER.info("Persisting result model into String.");
		String resultModel = ModelPersistenceUtil.serializeIntoOneResource(resultModels);
		LOGGER.info("Persisting finished.");

		VerificationResult result = new VerificationResult(checkedProperty, resultModel, visualization);
		VerificationResponse response = new VerificationResponse(result);
		printSerializedPath(response);
	}

	private Package getPackage(int index) {
		return (Package) statechartModelsResource.getContents().get(index);
	}

	private void printSerializedPath(VerificationResponse result) {
		File output = serialize(result);
		// Warning: do not change LOGGER.info, because client reads the standard output
		LOGGER.info(String.format("Result:%s", output.getAbsolutePath()));
	}

	private File serialize(VerificationResponse response) {
		try {
			LOGGER.info("Serializing model into file.");
			File outputFile = FileUtil.createTempFile("verifresult", "out", true);
			try (ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream(outputFile))) {
				oos.writeObject(response);
			}
			LOGGER.info("Serialization finished.");
			return outputFile;
		} catch (IOException ex) {
			LOGGER.error(ex.getMessage(), ex);
			return null;
		}
	}

}