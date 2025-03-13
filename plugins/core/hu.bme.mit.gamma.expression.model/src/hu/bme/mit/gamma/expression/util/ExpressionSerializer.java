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
package hu.bme.mit.gamma.expression.util;

import java.util.List;
import java.util.Objects;

import hu.bme.mit.gamma.expression.model.AddExpression;
import hu.bme.mit.gamma.expression.model.AndExpression;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression;
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DefaultExpression;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.DivExpression;
import hu.bme.mit.gamma.expression.model.DivideExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.ExistsExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.FalseExpression;
import hu.bme.mit.gamma.expression.model.FieldAssignment;
import hu.bme.mit.gamma.expression.model.ForallExpression;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression;
import hu.bme.mit.gamma.expression.model.GreaterExpression;
import hu.bme.mit.gamma.expression.model.IfThenElseExpression;
import hu.bme.mit.gamma.expression.model.ImplyExpression;
import hu.bme.mit.gamma.expression.model.InequalityExpression;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression;
import hu.bme.mit.gamma.expression.model.LessEqualExpression;
import hu.bme.mit.gamma.expression.model.LessExpression;
import hu.bme.mit.gamma.expression.model.ModExpression;
import hu.bme.mit.gamma.expression.model.MultiplyExpression;
import hu.bme.mit.gamma.expression.model.NotExpression;
import hu.bme.mit.gamma.expression.model.OpaqueExpression;
import hu.bme.mit.gamma.expression.model.OrExpression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression;
import hu.bme.mit.gamma.expression.model.RecordAccessExpression;
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression;
import hu.bme.mit.gamma.expression.model.SelectExpression;
import hu.bme.mit.gamma.expression.model.SubtractExpression;
import hu.bme.mit.gamma.expression.model.TrueExpression;
import hu.bme.mit.gamma.expression.model.UnaryMinusExpression;
import hu.bme.mit.gamma.expression.model.UnaryPlusExpression;
import hu.bme.mit.gamma.expression.model.XorExpression;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ExpressionSerializer {
	// Singleton
	public static final ExpressionSerializer INSTANCE = new ExpressionSerializer();
	protected ExpressionSerializer() {}
	//
	
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;

	protected String _serialize(final ElseExpression expression) {
		return "else";
	}
	
	protected String _serialize(final DefaultExpression expression) {
		return "default";
	}

	protected String _serialize(final TrueExpression expression) {
		return "true";
	}

	protected String _serialize(final FalseExpression expression) {
		return "false";
	}

	protected String _serialize(final IntegerLiteralExpression integerLiteralExpression) {
		return integerLiteralExpression.getValue().toString();
	}

	protected String _serialize(final DecimalLiteralExpression decimalLiteralExpression) {
		return decimalLiteralExpression.getValue().toString();
	}

	protected String _serialize(final RationalLiteralExpression rationalLiteralExpression) {
		return rationalLiteralExpression.getNumerator() + " % " + rationalLiteralExpression.getDenominator();
	}

	protected String _serialize(final OpaqueExpression opaqueExpression) {
		return opaqueExpression.getExpression();
	}

	protected String _serialize(final DirectReferenceExpression expression) {
		final Declaration declaration = expression.getDeclaration();
		return declaration.getName();
	}
	
	protected String _serialize(final NotExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("!(");
		String serialize = this.serialize(expression.getOperand());
		builder.append(serialize);
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final OrExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("(");
		List<Expression> operands = expression.getOperands();
		boolean hasElements = false;
		for (final Expression operand : operands) {
			if (!hasElements) {
				hasElements = true;
			} else {
				builder.append(" || ");
			}
			String serialize = this.serialize(operand);
			builder.append(serialize);
		}
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final XorExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("(");
		List<Expression> operands = expression.getOperands();
		boolean hasElements = false;
		for (final Expression operand : operands) {
			if (!hasElements) {
				hasElements = true;
			} else {
				builder.append(" ^^ ");
			}
			String serialize = this.serialize(operand);
			builder.append(serialize);
		}
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final AndExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("(");
		List<Expression> operands = expression.getOperands();
		boolean hasElements = false;
		for (final Expression operand : operands) {
			if (!hasElements) {
				hasElements = true;
			} else {
				builder.append(" && ");
			}
			String serialize = this.serialize(operand);
			builder.append(serialize);
		}
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final EqualityExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("(");
		String serialize = this.serialize(expression.getLeftOperand());
		builder.append(serialize);
		builder.append(" == ");
		String serialize1 = this.serialize(expression.getRightOperand());
		builder.append(serialize1);
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final InequalityExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("(");
		String serialize = this.serialize(expression.getLeftOperand());
		builder.append(serialize);
		builder.append(" != ");
		String serialize1 = this.serialize(expression.getRightOperand());
		builder.append(serialize1);
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final GreaterExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("(");
		String serialize = this.serialize(expression.getLeftOperand());
		builder.append(serialize);
		builder.append(" > ");
		String serialize1 = this.serialize(expression.getRightOperand());
		builder.append(serialize1);
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final GreaterEqualExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("(");
		String serialize = this.serialize(expression.getLeftOperand());
		builder.append(serialize);
		builder.append(" >= ");
		String serialize1 = this.serialize(expression.getRightOperand());
		builder.append(serialize1);
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final LessExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("(");
		String serialize = this.serialize(expression.getLeftOperand());
		builder.append(serialize);
		builder.append(" < ");
		String serialize1 = this.serialize(expression.getRightOperand());
		builder.append(serialize1);
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final LessEqualExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("(");
		String serialize = this.serialize(expression.getLeftOperand());
		builder.append(serialize);
		builder.append(" <= ");
		String serialize1 = this.serialize(expression.getRightOperand());
		builder.append(serialize1);
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final AddExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("(");
		List<Expression> operands = expression.getOperands();
		boolean hasElements = false;
		for (final Expression operand : operands) {
			if (!hasElements) {
				hasElements = true;
			} else {
				builder.append(" + ");
			}
			String serialize = this.serialize(operand);
			builder.append(serialize);
		}
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final SubtractExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("(");
		String serialize = this.serialize(expression.getLeftOperand());
		builder.append(serialize);
		builder.append(" - ");
		String serialize1 = this.serialize(expression.getRightOperand());
		builder.append(serialize1);
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final MultiplyExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("(");
		List<Expression> operands = expression.getOperands();
		boolean hasElements = false;
		for (final Expression operand : operands) {
			if (!hasElements) {
				hasElements = true;
			} else {
				builder.append(" * ");
			}
			String serialize = this.serialize(operand);
			builder.append(serialize);
		}
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final DivideExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("(");
		String serialize = this.serialize(expression.getLeftOperand());
		builder.append(serialize);
		builder.append(" / ");
		String serialize1 = this.serialize(expression.getRightOperand());
		builder.append(serialize1);
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final ModExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("(");
		String serialize = this.serialize(expression.getLeftOperand());
		builder.append(serialize);
		builder.append(" mod ");
		String serialize1 = this.serialize(expression.getRightOperand());
		builder.append(serialize1);
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final DivExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("(");
		String serialize = this.serialize(expression.getLeftOperand());
		builder.append(serialize);
		builder.append(" div ");
		String serialize1 = this.serialize(expression.getRightOperand());
		builder.append(serialize1);
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final UnaryPlusExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("+(");
		String serialize = this.serialize(expression.getOperand());
		builder.append(serialize);
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final UnaryMinusExpression expression) {
		StringBuilder builder = new StringBuilder();
		builder.append("-(");
		String serialize = this.serialize(expression.getOperand());
		builder.append(serialize);
		builder.append(")");
		return builder.toString();
	}

	protected String _serialize(final ArrayAccessExpression arrayAccessExpression) {
		return serialize(arrayAccessExpression.getOperand()) + "[" + serialize(arrayAccessExpression.getIndex()) + "]";
	}

	protected String _serialize(final FunctionAccessExpression functionAccessExpression) {
		String string = "";
		List<Expression> _arguments = functionAccessExpression.getArguments();
		for (final Expression expression : _arguments) {
			string = string.concat(this.serialize(expression).toString());
			List<Expression> arguments = functionAccessExpression.getArguments();
			Expression _last = arguments.get(arguments.size() - 1);
			boolean _notEquals = (!Objects.equals(expression, _last));
			if (_notEquals) {
				string = string.concat(", ");
			}
		}
		String serialize = this.serialize(functionAccessExpression.getOperand());
		String _plus = (serialize + "(");
		String _plus_1 = (_plus + string);
		return _plus_1 + ")";
	}

	protected String _serialize(final RecordAccessExpression recordAccessExpression) {
		String _serialize = this.serialize(recordAccessExpression.getOperand());
		String _plus = (_serialize + ".");
		String _field = recordAccessExpression.getFieldReference().getFieldDeclaration().getName();
		return _plus + _field;
	}

	protected String _serialize(final SelectExpression selectExpression) {
		String _serialize = this.serialize(selectExpression.getOperand());
		return _serialize + "->select";
	}

	protected String _serialize(final ForallExpression forallExpression) {
		String string = "";
		List<ParameterDeclaration> _parameterDeclarations = forallExpression.getParameterDeclarations();
		for (final ParameterDeclaration expression : _parameterDeclarations) {
			string = string.concat(expression.getType().toString());
			ParameterDeclaration _last = _parameterDeclarations.get(_parameterDeclarations.size() - 1);
			boolean _notEquals = (!Objects.equals(expression, _last));
			if (_notEquals) {
				string = string.concat(", ");
			}
		}
		String _serialize = this.serialize(forallExpression.getOperand());
		return "forall" + "(" + string + "): " + _serialize;
	}

	protected String _serialize(final ExistsExpression existsExpression) {
		String string = "";
		List<ParameterDeclaration> _parameterDeclarations = existsExpression.getParameterDeclarations();
		for (final ParameterDeclaration expression : _parameterDeclarations) {
			string = string.concat(expression.getType().toString());
			ParameterDeclaration _last = _parameterDeclarations.get(_parameterDeclarations.size() - 1);
			boolean _notEquals = (!Objects.equals(expression, _last));
			if (_notEquals) {
				string = string.concat(", ");
			}
		}
		String _serialize = this.serialize(existsExpression.getOperand());
		return "exists" + "(" + string + "): " + _serialize;
	}

	protected String _serialize(final ImplyExpression implyExpression) {
		String _serialize = this.serialize(implyExpression.getLeftOperand());
		String _plus = (_serialize + " imply ");
		String _serialize_1 = this.serialize(implyExpression.getRightOperand());
		return _plus + _serialize_1;
	}

	protected String _serialize(final IfThenElseExpression ifThenElseExpresison) {
		String _serialize = this.serialize(ifThenElseExpresison.getCondition());
		String _plus = (_serialize + " ? ");
		String _serialize_1 = this.serialize(ifThenElseExpresison.getThen());
		String _plus_1 = (_plus + _serialize_1);
		String _plus_2 = (_plus_1 + " : ");
		String _serialize_2 = this.serialize(ifThenElseExpresison.getElse());
		return _plus_2 + _serialize_2;
	}

	protected String _serialize(final ArrayLiteralExpression arrayLiteralExpression) {
		String string = "";
		List<Expression> _operands = arrayLiteralExpression.getOperands();
		for (final Expression expression : _operands) {
			string = string.concat(this.serialize(expression).toString());
			Expression _last = _operands.get(_operands.size() - 1);
			boolean _notEquals = (!Objects.equals(expression, _last));
			if (_notEquals) {
				string = string.concat(", ");
			}
		}
		return "{ " + string + " }";
	}

	protected String _serialize(final EnumerationLiteralExpression enumerationLiteralExpression) {
		String _typeName = enumerationLiteralExpression.getTypeReference().getReference().getName();
		String _name = enumerationLiteralExpression.getReference().getName();
		return _typeName + "::" + _name;
	}

	protected String _serialize(final RecordLiteralExpression recordLiteralExpression) {
		String string = "";
		List<FieldAssignment> _fieldAssignments = recordLiteralExpression.getFieldAssignments();
		for (final FieldAssignment expression : _fieldAssignments) {
			String _reference = expression.getReference().getFieldDeclaration().getName();
			String _plus = (_reference + ":=");
			String _serialize = this.serialize(expression.getValue());
			String _plus_1 = (_plus + _serialize);
			string = string.concat(_plus_1);
			FieldAssignment _last = _fieldAssignments.get(_fieldAssignments.size() - 1);
			boolean _notEquals = (!Objects.equals(expression, _last));
			if (_notEquals) {
				string = string.concat(", ");
			}
		}
		return "# { " + string + " }";
	}

	protected String _serialize(final IntegerRangeLiteralExpression integerRangeLiteralExpression) {
		String leftinc = "";
		String rightinc = "";
		boolean _isLeftInclusive = integerRangeLiteralExpression.isLeftInclusive();
		if (_isLeftInclusive) {
			leftinc = "[";
		} else {
			leftinc = "(";
		}
		boolean _isRightInclusive = integerRangeLiteralExpression.isRightInclusive();
		if (_isRightInclusive) {
			rightinc = "]";
		} else {
			rightinc = ")";
		}
		String _serialize = this.serialize(integerRangeLiteralExpression.getLeftOperand());
		String _plus = (leftinc + _serialize);
		String _plus_1 = (_plus + "..");
		String _serialize_1 = this.serialize(integerRangeLiteralExpression.getRightOperand());
		String _plus_2 = (_plus_1 + _serialize_1);
		return _plus_2 + rightinc;
	}

	public String serialize(final Expression expression) {
		if (expression instanceof EqualityExpression) {
			return _serialize((EqualityExpression) expression);
		} else if (expression instanceof FalseExpression) {
			return _serialize((FalseExpression) expression);
		} else if (expression instanceof GreaterEqualExpression) {
			return _serialize((GreaterEqualExpression) expression);
		} else if (expression instanceof GreaterExpression) {
			return _serialize((GreaterExpression) expression);
		} else if (expression instanceof InequalityExpression) {
			return _serialize((InequalityExpression) expression);
		} else if (expression instanceof LessEqualExpression) {
			return _serialize((LessEqualExpression) expression);
		} else if (expression instanceof LessExpression) {
			return _serialize((LessExpression) expression);
		} else if (expression instanceof TrueExpression) {
			return _serialize((TrueExpression) expression);
		} else if (expression instanceof AndExpression) {
			return _serialize((AndExpression) expression);
		} else if (expression instanceof IntegerLiteralExpression) {
			return _serialize((IntegerLiteralExpression) expression);
		} else if (expression instanceof DecimalLiteralExpression) {
			return _serialize((DecimalLiteralExpression) expression);
		} else if (expression instanceof RationalLiteralExpression) {
			return _serialize((RationalLiteralExpression) expression);
		} else if (expression instanceof NotExpression) {
			return _serialize((NotExpression) expression);
		} else if (expression instanceof OrExpression) {
			return _serialize((OrExpression) expression);
		} else if (expression instanceof XorExpression) {
			return _serialize((XorExpression) expression);
		} else if (expression instanceof AddExpression) {
			return _serialize((AddExpression) expression);
		} else if (expression instanceof DivideExpression) {
			return _serialize((DivideExpression) expression);
		} else if (expression instanceof ModExpression) {
			return _serialize((ModExpression) expression);
		} else if (expression instanceof ElseExpression) {
			return _serialize((ElseExpression) expression);
		} else if (expression instanceof EnumerationLiteralExpression) {
			return _serialize((EnumerationLiteralExpression) expression);
		} else if (expression instanceof MultiplyExpression) {
			return _serialize((MultiplyExpression) expression);
		} else if (expression instanceof DirectReferenceExpression) {
			return _serialize((DirectReferenceExpression) expression);
		} else if (expression instanceof SubtractExpression) {
			return _serialize((SubtractExpression) expression);
		} else if (expression instanceof UnaryMinusExpression) {
			return _serialize((UnaryMinusExpression) expression);
		} else if (expression instanceof UnaryPlusExpression) {
			return _serialize((UnaryPlusExpression) expression);
		} else if (expression instanceof ForallExpression) {
			return _serialize((ForallExpression) expression);
		} else if (expression instanceof ImplyExpression) {
			return _serialize((ImplyExpression) expression);
		} else if (expression instanceof ArrayAccessExpression) {
			return _serialize((ArrayAccessExpression) expression);
		} else if (expression instanceof DivExpression) {
			return _serialize((DivExpression) expression);
		} else if (expression instanceof FunctionAccessExpression) {
			return _serialize((FunctionAccessExpression) expression);
		} else if (expression instanceof RecordAccessExpression) {
			return _serialize((RecordAccessExpression) expression);
		} else if (expression instanceof SelectExpression) {
			return _serialize((SelectExpression) expression);
		} else if (expression instanceof IfThenElseExpression) {
			return _serialize((IfThenElseExpression) expression);
		} else if (expression instanceof OpaqueExpression) {
			return _serialize((OpaqueExpression) expression);
		} else if (expression instanceof ExistsExpression) {
			return _serialize((ExistsExpression) expression);
		} else if (expression instanceof ArrayLiteralExpression) {
			return _serialize((ArrayLiteralExpression) expression);
		} else if (expression instanceof RecordLiteralExpression) {
			return _serialize((RecordLiteralExpression) expression);
		} else if (expression instanceof IntegerRangeLiteralExpression) {
			return _serialize((IntegerRangeLiteralExpression) expression);
		} else {
			throw new IllegalArgumentException("Unhandled parameter types: " + expression);
		}
	}

}