/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.controller;

import java.io.File;
import java.io.IOException;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;

import hu.bme.mit.gamma.querygenerator.UppaalQueryGenerator;
import hu.bme.mit.gamma.querygenerator.application.View;
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace;
import hu.bme.mit.gamma.uppaal.verification.UppaalVerifier;
import hu.bme.mit.gamma.verification.util.AbstractVerifier;

public class UppaalController extends AbstractController {
	
	public UppaalController(View view, IFile file) throws IOException {
		this.file = file;
		this.view = view;
		this.queryGenerator = new UppaalQueryGenerator((G2UTrace) getTraceability()); // For state-location
	}
	
	private String getTraceabilityFile() {
		return getParentFolder() + File.separator + "." + getCompositeSystemName() + ".g2u"; 
	}
	
	@Override
	public String getGeneratedQueryFile() {
		return getParentFolder() + File.separator + getCompositeSystemName() + ".q"; 
	}
	
	@Override
	public String getModelFile() {
		return getLocation(file).substring(0, getLocation(file).lastIndexOf(".")) + ".xml";
	}
	
	@Override
	public Object getTraceability() {
		URI fileURI = URI.createFileURI(getTraceabilityFile());
		return ecoreUtil.normalLoad(fileURI);
	}
	
	@Override
	public AbstractVerifier createVerifier() {
		return new UppaalVerifier();
	}
	
    @Override
	public String getParameters() {
		return getStateSpaceRepresentation() + " " + getSearchOrder() + " " + getDiagnosticTrace() + " " +
				getResuseStateSpace() + " " +	" " + getHashtableSize() + " " + getStateSpaceReduction();
	}
	
	private String getSearchOrder() {
		final String paremterName = "-o ";
		switch (view.getSelectedSearchOrder()) {
		case "Breadth First":
			return paremterName + "0";
		case "Depth First":
			return paremterName + "1";
		case "Random Depth First":
			return paremterName + "2";
		case "Optimal First":
			if (view.getSelectedTrace().equals("Shortest") || view.getSelectedTrace().equals("Fastest")) {
				return paremterName + "3";	
			}
			// BFS
			return paremterName + "0"; 
		case "Random Optimal Depth First":
			if (view.getSelectedTrace().equals("Shortest") || view.getSelectedTrace().equals("Fastest")) {
				return paremterName + "4";
			}
			// BFS
			return paremterName + "0"; 
		default:
			throw new IllegalArgumentException("Not known option: " + view.getSelectedSearchOrder());
		}
	}
	
	private String getStateSpaceRepresentation() {
		switch (view.getStateSpaceRepresentation()) {
		case "DBM":
			return "-C";
		case "Over Approximation":
			return "-A";
		case "Under Approximation":
			return "-Z";
		default:
			throw new IllegalArgumentException("Not known option: " + view.getStateSpaceRepresentation());
		}
	}
	
	private String getHashtableSize() {
		/* -H n
	      Set hash table size for bit state hashing to 2**n
	      (default = 27)
		 */
		final String paremterName = "-H ";
		final int value = view.getHashTableSize();
		final int exponent = 20 + (int) Math.floor(Math.log10(value) / Math.log10(2)); // log2(value)
		return paremterName + exponent;
	}
	
	private String getStateSpaceReduction() {
		final String paremterName = "-S ";
		switch (view.getStateSpaceReduction()) {
		case "None":
			// BFS
			return paremterName + "0";
		case "Conservative":
			// DFS
			return paremterName + "1";
		case "Aggressive":
			// Random DFS
			return paremterName + "2";			
		default:
			throw new IllegalArgumentException("Not known option: " + view.getStateSpaceReduction());
		}
	}
	
	private String getResuseStateSpace() {
		if (view.isReuseStateSpace()) {
			return "-T";
		}
		return "";
	}
	
	private String getDiagnosticTrace() {
		switch (view.getSelectedTrace()) {
		case "Some":
			// Some trace
			return "-t0";
		case "Shortest":
			// Shortest trace
			return "-t1";
		case "Fastest":
			// Fastest trace
			return "-t2";			
		default:
			throw new IllegalArgumentException("Not known option: " + view.getSelectedTrace());
		}
	}
    
}