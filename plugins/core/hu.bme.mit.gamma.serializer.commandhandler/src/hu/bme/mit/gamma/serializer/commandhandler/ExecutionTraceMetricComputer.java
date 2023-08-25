/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.serializer.commandhandler;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IFolder;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.transformation.util.GammaFileNamer;
import hu.bme.mit.gamma.util.FileUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ExecutionTraceMetricComputer extends AbstractHandler {

	protected final Map<ExecutionTrace, Integer> traceMetrics = new HashMap<ExecutionTrace, Integer>();
	//
	protected final FileUtil fileUtil = FileUtil.INSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		try {
			ISelection sel = HandlerUtil.getActiveMenuSelection(event);
			if (sel instanceof IStructuredSelection) {
				IStructuredSelection selection = (IStructuredSelection) sel;
				Object firstElement = selection.getFirstElement();
				if (firstElement != null) {
					if (firstElement instanceof IResource) {
						IResource resource = (IResource) firstElement;
						traceMetrics.clear();
						computeMetrics(resource);
					}
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		calculate();
		
		
		return null;
	}
	
	protected void computeMetrics(IResource resource) throws CoreException {
		if (resource instanceof IFolder) {
			IFolder folder = (IFolder) resource;
			IResource[] members = folder.members();
			if (members != null) {
				for (IResource member : members) {
					computeMetrics(member);
				}
			}
		}
		if (resource instanceof IFile) {
			IFile file = (IFile) resource;
			String fileExtension = file.getFileExtension();
			if (fileExtension.equals(GammaFileNamer.EXECUTION_XTEXT_EXTENSION) ||
					fileExtension.equals(GammaFileNamer.EXECUTION_EMF_EXTENSION)) {
				ExecutionTrace trace = (ExecutionTrace) ecoreUtil.normalLoad(
						fileUtil.getFile(file));
				int stepCount = getStepCount(trace);
				
				traceMetrics.put(trace, stepCount);
			}
		}
	}

	protected int getStepCount(ExecutionTrace trace) {
		return trace.getSteps()
				.size();
	}
	
	//
	
	protected void calculate() {
		List<Integer> values = new ArrayList<Integer>(traceMetrics.values());
		if (values.size() > 0) {
			Collections.sort(values);
		
			System.out.println("Size: " + values.size());
			System.out.println("Median: " + calculateMedian(values));
			System.out.println("Average: " + calculateAverage(values));
			System.out.println("Max: " + calculateMax(values));
			System.out.println("Sum: " + calculateSum(values));
		}
	}
	
	public double calculateMax(List<Integer> values) {
		// values is sorted
		return values.get(values.size() - 1);
	}
	
	public double calculateAverage(List<Integer> values) {
		int size = values.size();
		int sum = values.stream()
				.reduce((a, b) -> a + b)
				.get();
		
		return sum / size;
	}
	
	public double calculateMedian(List<Integer> values) {
		// values is sorted
		int size = values.size();
		int halfSize = size / 2;
		if (size % 2 == 0) {
			double median = (values.get(halfSize - 1) + values.get(halfSize)) / 2.0;
			return median;
		}
		else {
			return values.get(halfSize);
		}
	}
	
	public double calculateSum(Collection<Integer> values) {
		int sum = 0;
		
		for (Integer value : values) {
			sum += value;
		}
		
		return sum;
	}
	
}
