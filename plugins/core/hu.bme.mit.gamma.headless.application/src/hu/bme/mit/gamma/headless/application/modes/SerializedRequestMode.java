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
package hu.bme.mit.gamma.headless.application.modes;

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
import hu.bme.mit.gamma.headless.application.io.VerificationRequest;
import hu.bme.mit.gamma.headless.application.io.VerificationResponse;
import hu.bme.mit.gamma.headless.application.io.VerificationResult;
import hu.bme.mit.gamma.headless.application.util.FileUtil;
import hu.bme.mit.gamma.headless.application.util.ModelPersistenceUtil;
import hu.bme.mit.gamma.headless.application.util.gamma.PropertySpecificationSerializationUtil;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean;

public class SerializedRequestMode implements IExecutionMode {

	private static final Logger LOGGER = LogManager.getLogger(SerializedRequestMode.class);

	private String inputFilePath;

	private Resource statechartModelsResource;
	private PropertySpecification propertySpecification;

	private ThreeStateBoolean verificationResult;
	private List<EObject> resultModels;
	private String visualization;

	public SerializedRequestMode(String inputFilePath) {
		this.inputFilePath = inputFilePath;
	}

	private void load() {
		if (statechartModelsResource == null && propertySpecification == null) {
			LOGGER.info("Deserializing request.");
			File inputFile = new File(inputFilePath);
			try (ObjectInputStream ois = new ObjectInputStream(new FileInputStream(inputFile))) {
				VerificationRequest request = (VerificationRequest) ois.readObject();
				LOGGER.info("Deserialization finished.");

				ResourceSet resourceSet = new ResourceSetImpl();
				LOGGER.info("Loading statechart model from resource.");
				statechartModelsResource = ModelPersistenceUtil.loadResourceWithSerializedUri(request.getModels(), resourceSet);
				LOGGER.info("Statechart model loaded.");

				LOGGER.info("Loading property specification from resource.");
				Resource resource = ModelPersistenceUtil.loadResourceWithSerializedUri(request.getExpression(), resourceSet);
				propertySpecification = (PropertySpecification) resource.getContents().get(0);
				// do not remove this call, otherwise model will not be loaded
				PropertySpecificationSerializationUtil.serialize(propertySpecification);
				LOGGER.info("Property specification loaded.");
			} catch (IOException | ClassNotFoundException e) {
				throw new RuntimeException(e);
			}
		}
	}

	@Override
	public Package getWrappedGammaStatechart() {
		load();
		return getPackage(0);
	}

	@Override
	public Package getNormalGammaStatechart() {
		load();
		return getPackage(1);
	}

	@Override
	public PropertySpecification getPropertySpecification() {
		load();
		return propertySpecification;
	}

	@Override
	public void setVerificationResult(ThreeStateBoolean result, List<EObject> models, String visualization) {
		this.verificationResult = result;
		this.resultModels = models;
		this.visualization = visualization;
	}

	@Override
	public void handleError(Exception ex) {
		VerificationResponse result = new VerificationResponse(new ErrorResult(ex.getMessage(), ex.getStackTrace()));
		printSerializedPath(result);
	}

	@Override
	public void finish() {
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
		ModelPersistenceUtil.saveInOneResource("gammatrace", resultModels);

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
			File outputFile = FileUtil.createTempFile("out", true);
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
