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

public class ActionSerializer {
	// Singleton
	public static final ActionSerializer INSTANCE = new ActionSerializer();

	protected ActionSerializer() {
	}
	//

	protected final ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE;

	protected String _serialize(final Block block) {
		StringBuilder builder = new StringBuilder("{ ");
		for (Action action : block.getActions()) {
			builder.append(serialize(action) + " ");
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
			builder.append("branch [" + expressionSerializer.serialize(branch.getGuard()) + "] "
					+ serialize(branch.getAction()) + System.lineSeparator());
		}
		builder.append("}");
		return builder.toString();
	}

	protected String _serialize(final ConstantDeclarationStatement statement) {
		ConstantDeclaration constant = statement.getConstantDeclaration(); // TODO type
		return "const " + constant.getName() + " := " + expressionSerializer.serialize(constant.getExpression());
	}

	protected String _serialize(final VariableDeclarationStatement statement) {
		VariableDeclaration variable = statement.getVariableDeclaration();
		StringBuilder builder = new StringBuilder("var " + variable.getName()); // TODO type
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
				+ expressionSerializer.serialize(statement.getRange()) + ")" + System.lineSeparator());
		builder.append(serialize(statement.getBody()) + System.lineSeparator());
		builder.append("then " + serialize(statement.getThen()));
		return builder.toString();
	}

	protected String _serialize(final SwitchStatement statement) {
		StringBuilder builder = new StringBuilder("switch ("
				+ expressionSerializer.serialize(statement.getControlExpression()) + ") {" + System.lineSeparator());
		for (Branch branch : statement.getCases()) {
			builder.append(
					"case " + expressionSerializer.serialize(branch.getGuard()) + ":" + serialize(branch.getAction()));
		}
		builder.append("}");
		return builder.toString();
	}

	protected String _serialize(final IfStatement statement) {
		StringBuilder builder = new StringBuilder();
		for (Branch branch : statement.getConditionals()) {
			builder.append(
					"[" + expressionSerializer.serialize(branch.getGuard()) + "]" + serialize(branch.getAction()));
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
