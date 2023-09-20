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
package hu.bme.mit.gamma.ui.taskhandler;

import java.io.IOException;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.genmodel.model.FmeaTableGeneration;
import hu.bme.mit.gamma.genmodel.model.SafetyAssessment;

public class FmeaTableGenerationHandler extends SafetyAssessmentHandler {
	//
	protected int cardinality = -1;
	protected int bmcBound = -1;
	//
	public FmeaTableGenerationHandler(IFile file) {
		super(file);
	}

	@Override
	public void execute(SafetyAssessment safetyAssessment) throws IOException {
		// Saving the cardinality
		FmeaTableGeneration fmeaTableGeneration = (FmeaTableGeneration) safetyAssessment;
		Expression cardinality = fmeaTableGeneration.getCardinality();
		this.cardinality = (cardinality != null) ? expressionEvaluator.evaluateInteger(cardinality) : 1;
		Expression bmcBound = fmeaTableGeneration.getBmcBound();
		this.bmcBound = (bmcBound != null) ? expressionEvaluator.evaluateInteger(bmcBound) : this.bmcBound;
		//
		super.execute(safetyAssessment);
	}
	
	@Override
	String getCommand() {
		String bmcBoundArgument = (bmcBound > 0) ? " -k " + bmcBound : "";
		return "go_msat" + System.lineSeparator() +
				"compute_fmea_table_msat_bmc -N " + cardinality + bmcBoundArgument; // And this line is extended by super
	}
	
	@Override
	String getCommandFileNamePrefix() {
		return "generate_fmea";
	}
	
}
