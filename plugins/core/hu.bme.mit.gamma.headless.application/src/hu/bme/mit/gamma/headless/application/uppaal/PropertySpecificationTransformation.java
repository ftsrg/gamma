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

import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;

import hu.bme.mit.gamma.headless.application.util.gamma.VariableRenamingSerializationHelper;
import hu.bme.mit.gamma.querygenerator.AbstractQueryGenerator;
import hu.bme.mit.gamma.querygenerator.UppaalQueryGenerator;
import hu.bme.mit.gamma.querygenerator.operators.TemporalOperator;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.statechart.Region;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace;

public class PropertySpecificationTransformation {

	private static final Logger LOGGER = LogManager.getLogger(PropertySpecificationTransformation.class);

	private PropertySpecification specification;
	private SynchronousComponentInstance sci;

	public PropertySpecificationTransformation(PropertySpecification specification, SynchronousComponentInstance sci) {
		this.specification = specification;
		this.sci = sci;
	}

	public String getCtlExpression(G2UTrace trace) {
		AbstractQueryGenerator generator = new UppaalQueryGenerator(trace);
		VariableRenamingSerializationHelper serializationHelper = new VariableRenamingSerializationHelper(generator,
				sci);

		Stream<String> stateNames = specification.getStates().stream().map(state -> getStateName(generator, state));
		Stream<String> expressions = specification.getExpressions().stream()
				.map(expression -> serializationHelper.serialize(expression));

		String rawCtlExpression = Stream.concat(stateNames, expressions).collect(Collectors.joining(" && "));
		if (specification.isNegated()) {
			rawCtlExpression = String.format("!(%s)", rawCtlExpression);
		}

		String ctlExpression = generator.parseRegularQuery(rawCtlExpression, getTemporalOperator());
		LOGGER.info(ctlExpression);

		return ctlExpression;
	}

	private TemporalOperator getTemporalOperator() {
		switch (specification.getOperator()) {
		case LEADS_TO:
			return TemporalOperator.LEADS_TO;
		case MIGHT_ALWAYS:
			return TemporalOperator.MIGHT_ALWAYS;
		case MIGHT_EVENTUALLY:
			return TemporalOperator.MIGHT_EVENTUALLY;
		case MUST_ALWAYS:
			return TemporalOperator.MUST_ALWAYS;
		case MUST_EVENTUALLY:
			return TemporalOperator.MUST_EVENTUALLY;
		}
		return null;
	}

	private String getStateName(AbstractQueryGenerator generator, State state) {
		Region parentRegion = StatechartModelDerivedFeatures.getParentRegion(state);
		String stateName = generator.getStateName(sci, parentRegion, state);
		return stateName;
	}

}
