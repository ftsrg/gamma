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
package hu.bme.mit.gamma.action.util;

import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.action.model.Block;
import hu.bme.mit.gamma.action.model.Branch;
import hu.bme.mit.gamma.action.model.BreakStatement;
import hu.bme.mit.gamma.action.model.ChoiceStatement;
import hu.bme.mit.gamma.action.model.ConstantDeclarationStatement;
import hu.bme.mit.gamma.action.model.EmptyStatement;
import hu.bme.mit.gamma.action.model.ExpressionStatement;
import hu.bme.mit.gamma.action.model.ForStatement;
import hu.bme.mit.gamma.action.model.IfStatement;
import hu.bme.mit.gamma.action.model.ReturnStatement;
import hu.bme.mit.gamma.action.model.SwitchStatement;
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement;
import hu.bme.mit.gamma.expression.model.ConstantDeclaration;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionSerializer;
import hu.bme.mit.gamma.expression.util.TypeSerializer;

public class ActionSerializer {
	// Singleton
	public static final ActionSerializer INSTANCE = new ActionSerializer();
	protected ActionSerializer() {}
	//

	protected ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE; // Redefinable
	protected final TypeSerializer typeSerializer = TypeSerializer.INSTANCE;

	//

	protected String _serialize(final Block block) {
		StringBuilder builder = new StringBuilder("{" + System.lineSeparator());
		for (Action action : block.getActions()) {
			builder.append("\t" + serialize(action) + System.lineSeparator());
		}
		builder.append("}");
		return builder.toString();
	}

	protected String _serialize(final BreakStatement statement) {
		return "break";
	}

	protected String _serialize(final ReturnStatement statement) {
		return "return " + expressionSerializer.serialize(statement.getExpression());
	}

	protected String _serialize(final AssignmentStatement statement) {
		return expressionSerializer.serialize(statement.getLhs()) + " := "
				+ expressionSerializer.serialize(statement.getRhs());
	}

	protected String _serialize(final ChoiceStatement statement) {
		StringBuilder builder = new StringBuilder("choice {" + System.lineSeparator());
		for (Branch branch : statement.getBranches()) {
			builder.append("\tbranch [" + expressionSerializer.serialize(branch.getGuard()) + "] "
					+ serialize(branch.getAction()) + System.lineSeparator());
		}
		builder.append("}");
		return builder.toString();
	}

	protected String _serialize(final ConstantDeclarationStatement statement) {
		ConstantDeclaration constant = statement.getConstantDeclaration();
		String typeName = typeSerializer.serialize(constant.getType());
		String expression = expressionSerializer.serialize(constant.getExpression());
		return "const " + constant.getName() + " : " + typeName + " := " + expression;
	}

	protected String _serialize(final VariableDeclarationStatement statement) {
		VariableDeclaration variable = statement.getVariableDeclaration();
		String typeName = typeSerializer.serialize(variable.getType());
		StringBuilder builder = new StringBuilder("var " + variable.getName() + " : " + typeName);
		final Expression expression = variable.getExpression();
		if (expression != null) {
			builder.append(" := " + expressionSerializer.serialize(expression));
		}
		return builder.toString();
	}

	protected String _serialize(final EmptyStatement statement) {
		return "";
	}

	protected String _serialize(final ExpressionStatement statement) {
		return expressionSerializer.serialize(statement.getExpression());
	}

	protected String _serialize(final ForStatement statement) {
		StringBuilder builder = new StringBuilder("for (" + statement.getParameter().getName() + " : "
				+ expressionSerializer.serialize(statement.getRange()) + ") ");
		builder.append(serialize(statement.getBody()));
		return builder.toString();
	}

	protected String _serialize(final SwitchStatement statement) {
		StringBuilder builder = new StringBuilder("switch ("
				+ expressionSerializer.serialize(statement.getControlExpression()) + ") {"  + System.lineSeparator());
		for (Branch branch : statement.getCases()) {
			builder.append(
					"\tcase " + expressionSerializer.serialize(branch.getGuard()) + ":"
			+ serialize(branch.getAction()) + System.lineSeparator());
		}
		builder.append("}");
		return builder.toString();
	}

	protected String _serialize(final IfStatement statement) {
		StringBuilder builder = new StringBuilder();
		for (Branch branch : statement.getConditionals()) {
			builder.append(
					"if (" + expressionSerializer.serialize(branch.getGuard()) + ") "
			+ serialize(branch.getAction()) + " ");
		}
		return builder.toString();
	}

	public String serialize(final Action action) {
		if (action instanceof Block) {
			return _serialize((Block) action);
		} else if (action instanceof BreakStatement) {
			return _serialize((BreakStatement) action);
		} else if (action instanceof ReturnStatement) {
			return _serialize((ReturnStatement) action);
		} else if (action instanceof AssignmentStatement) {
			return _serialize((AssignmentStatement) action);
		} else if (action instanceof ChoiceStatement) {
			return _serialize((ChoiceStatement) action);
		} else if (action instanceof ConstantDeclarationStatement) {
			return _serialize((ConstantDeclarationStatement) action);
		} else if (action instanceof VariableDeclarationStatement) {
			return _serialize((VariableDeclarationStatement) action);
		} else if (action instanceof EmptyStatement) {
			return _serialize((EmptyStatement) action);
		} else if (action instanceof ExpressionStatement) {
			return _serialize((ExpressionStatement) action);
		} else if (action instanceof ForStatement) {
			return _serialize((ForStatement) action);
		} else if (action instanceof SwitchStatement) {
			return _serialize((SwitchStatement) action);
		} else if (action instanceof IfStatement) {
			return _serialize((IfStatement) action);
		} else {
			throw new IllegalArgumentException("Unhandled parameter types: " + action);
		}
	}

}
