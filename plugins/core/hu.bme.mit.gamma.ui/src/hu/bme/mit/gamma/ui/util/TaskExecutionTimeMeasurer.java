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
package hu.bme.mit.gamma.ui.util;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.logging.Logger;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;

import hu.bme.mit.gamma.util.FileUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class TaskExecutionTimeMeasurer implements TaskHook {
	
	private final int iterationCount;
	private long startTime;
	
	private final boolean considerJit;
	
	private boolean isFirst = true;
	private final List<Double> elapsedTimes = new ArrayList<Double>();
	
	private final Calculator<Double> calculator;
	private final String fileName;
	private final TimeUnit unit;
	private File targetFile;
	
	private final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	private final FileUtil fileUtil = FileUtil.INSTANCE;
	
	protected final Logger logger = Logger.getLogger("GammaLogger");
	
	public TaskExecutionTimeMeasurer(Calculator<Double> calculator, String fileName) {
		this(1, false, calculator, fileName, TimeUnit.SECONDS);
	}
	
	public TaskExecutionTimeMeasurer(int iterationCount, boolean considerJit,
			Calculator<Double> calculator, String fileName, TimeUnit unit) {
		this.iterationCount = iterationCount +
				(considerJit ? 1 : 0); // Due to Java JIT, we do not count the first one
		this.considerJit = considerJit;
		this.calculator = calculator;
		this.fileName = fileName;
		this.unit = unit;
	}
	
	public void startTaskProcess(Object object) {
		// Setting target file
		if (object instanceof EObject) {
			EObject eObject = (EObject) object;
			Resource resource = eObject.eResource();
			File siblingFile = ecoreUtil.getFile(resource);
			String parentUri = siblingFile.getParent();
			this.targetFile = new File(parentUri + File.separator + fileName);
		}
		
		isFirst = true;
		elapsedTimes.clear();
		logger.info("Starting measurement");
	}
	
	public int getIterationCount() {
		return iterationCount;
	}
	
	public void startIteration() {
		logger.info("Starting iteration " + (elapsedTimes.size() + 1));
		startTime = System.nanoTime();
	}
	
	public void endIteration() {
		long endTime = System.nanoTime();
		double time = (endTime - startTime) / getDivisor();
		if (isFirst && considerJit) {
			isFirst = false;
			logger.info("First (not considered) iteration has been finished");
		}
		else {
			elapsedTimes.add(time);
			logger.info("Finished iteration " + elapsedTimes.size() + ", result is " + time + " " + unit);
		}
	}
	
	public void endTaskProcess() {
		StringBuilder builder = new StringBuilder();
		for (Double value : elapsedTimes) {
			builder.append(value + " " + unit + System.lineSeparator());
		}
		double median = calculator.calculate(elapsedTimes);
		builder.append("Median: " + median + " " + unit);
		
		fileUtil.saveString(targetFile, builder.toString());
		logger.info("Saved results in " + targetFile.getAbsolutePath());
		
		logger.info("Finished measurement");
	}
	
	private double getDivisor() {
		switch (this.unit) {
			case MILLISECONDS:
				return 1000000.0;
			case SECONDS:
				return 1000000000.0;
			default:
				throw new IllegalArgumentException("Not known time unit: " + this.unit);
		}
	}

}
