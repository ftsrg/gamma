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
package hu.bme.mit.gamma.headless.application.util.gamma;

import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionSerializer;
import hu.bme.mit.gamma.querygenerator.AbstractQueryGenerator;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;

public class VariableRenamingSerializationHelper extends ExpressionSerializer {

	private AbstractQueryGenerator queryGenerator;
	private SynchronousComponentInstance sci;

	public VariableRenamingSerializationHelper(AbstractQueryGenerator queryGenerator, SynchronousComponentInstance sci) {
		this.queryGenerator = queryGenerator;
		this.sci = sci;
	}

	@Override
	protected String _serialize(ReferenceExpression expression) {
		final Declaration declaration = expression.getDeclaration();
		if(declaration instanceof VariableDeclaration) {
			return queryGenerator.getVariableName(sci, (VariableDeclaration)declaration);
		} else {
			return super._serialize(expression);
		}
	}

}
