/**
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 */
package hu.bme.mit.gamma.xsts.codegeneration.c.serializer;

import hu.bme.mit.gamma.expression.model.AddExpression;
import hu.bme.mit.gamma.expression.model.AndExpression;
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.DivideExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.FalseExpression;
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression;
import hu.bme.mit.gamma.expression.model.GreaterExpression;
import hu.bme.mit.gamma.expression.model.IfThenElseExpression;
import hu.bme.mit.gamma.expression.model.ImplyExpression;
import hu.bme.mit.gamma.expression.model.InequalityExpression;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.LessEqualExpression;
import hu.bme.mit.gamma.expression.model.LessExpression;
import hu.bme.mit.gamma.expression.model.ModExpression;
import hu.bme.mit.gamma.expression.model.MultiplyExpression;
import hu.bme.mit.gamma.expression.model.NotExpression;
import hu.bme.mit.gamma.expression.model.OrExpression;
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression;
import hu.bme.mit.gamma.expression.model.SubtractExpression;
import hu.bme.mit.gamma.expression.model.TrueExpression;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.UnaryMinusExpression;
import hu.bme.mit.gamma.expression.model.UnaryPlusExpression;
import hu.bme.mit.gamma.expression.model.XorExpression;
import hu.bme.mit.gamma.xsts.codegeneration.c.CodeBuilder;
import java.util.Arrays;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtend2.lib.StringConcatenation;

/**
 * Serializer for expressions in the C code generation.
 */
@SuppressWarnings("all")
public class ExpressionSerializer {
  /**
   * Serializes the given expression.
   * 
   * @param expression the expression to serialize
   * @return the serialized expression as a string
   * @throws IllegalArgumentException if the expression is not supported
   */
  protected String _serialize(final Expression expression) {
    throw new IllegalArgumentException(("Not supported expression: " + expression));
  }

  /**
   * Serializes the given ElseExpression.
   * 
   * @param expression the ElseExpression to serialize
   * @return the serialized ElseExpression as a string
   * @throws IllegalArgumentException if the expression cannot be transformed
   */
  protected String _serialize(final ElseExpression expression) {
    throw new IllegalArgumentException("Cannot be transformed");
  }

  /**
   * Serializes the given DirectReferenceExpression.
   * 
   * @param expression the DirectReferenceExpression to serialize
   * @return the serialized DirectReferenceExpression as a string
   */
  protected String _serialize(final DirectReferenceExpression expression) {
    final Declaration declaration = expression.getDeclaration();
    boolean _contains = CodeBuilder.componentVariables.contains(declaration.getName());
    if (_contains) {
      StringConcatenation _builder = new StringConcatenation();
      _builder.append("statechart->");
      String _name = declaration.getName();
      _builder.append(_name);
      return _builder.toString();
    }
    return declaration.getName();
  }

  /**
   * Serializes the given EnumerationLiteralExpression.
   * 
   * @param expression the EnumerationLiteralExpression to serialize
   * @return the serialized EnumerationLiteralExpression as a string
   */
  protected String _serialize(final EnumerationLiteralExpression expression) {
    final EnumerationLiteralDefinition definition = expression.getReference();
    EObject _eContainer = definition.eContainer();
    final EnumerationTypeDefinition enumerationType = ((EnumerationTypeDefinition) _eContainer);
    EObject _eContainer_1 = enumerationType.eContainer();
    final TypeDeclaration typeDeclaration = ((TypeDeclaration) _eContainer_1);
    String _name = definition.getName();
    String _plus = (_name + "_");
    String _lowerCase = typeDeclaration.getName().toLowerCase();
    return (_plus + _lowerCase);
  }

  /**
   * Serializes the given IntegerLiteralExpression.
   * 
   * @param expression the IntegerLiteralExpression to serialize
   * @return the serialized IntegerLiteralExpression as a string
   */
  protected String _serialize(final IntegerLiteralExpression expression) {
    return expression.getValue().toString();
  }

  /**
   * Serializes the given DecimalLiteralExpression.
   * 
   * @param expression the DecimalLiteralExpression to serialize
   * @return the serialized DecimalLiteralExpression as a string
   */
  protected String _serialize(final DecimalLiteralExpression expression) {
    return expression.getValue().toString();
  }

  /**
   * Serializes the given RationalLiteralExpression.
   * 
   * @param expression the RationalLiteralExpression to serialize
   * @return the serialized RationalLiteralExpression as a string
   */
  protected String _serialize(final RationalLiteralExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(((float) ");
    String _string = expression.getNumerator().toString();
    _builder.append(_string);
    _builder.append(") / ");
    String _string_1 = expression.getDenominator().toString();
    _builder.append(_string_1);
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes the given TrueExpression.
   * 
   * @param expression the TrueExpression to serialize
   * @return the serialized TrueExpression as a string
   */
  protected String _serialize(final TrueExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("true");
    return _builder.toString();
  }

  /**
   * Serializes the given FalseExpression.
   * 
   * @param expression the FalseExpression to serialize
   * @return the serialized FalseExpression as a string
   */
  protected String _serialize(final FalseExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("false");
    return _builder.toString();
  }

  /**
   * Serializes the given NotExpression.
   * 
   * @param expression the NotExpression to serialize
   * @return the serialized NotExpression as a string
   */
  protected String _serialize(final NotExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("!(");
    String _serialize = this.serialize(expression.getOperand());
    _builder.append(_serialize);
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes the given OrExpression object.
   * 
   * @param expression The OrExpression object to serialize.
   * @return The serialized OrExpression object as a string.
   */
  protected String _serialize(final OrExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(");
    {
      EList<Expression> _operands = expression.getOperands();
      boolean _hasElements = false;
      for(final Expression operand : _operands) {
        if (!_hasElements) {
          _hasElements = true;
        } else {
          _builder.appendImmediate(" || ", "");
        }
        String _serialize = this.serialize(operand);
        _builder.append(_serialize);
      }
    }
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes the given XorExpression object.
   * 
   * @param expression The XorExpression object to serialize.
   * @return The serialized XorExpression object as a string.
   */
  protected String _serialize(final XorExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(");
    {
      EList<Expression> _operands = expression.getOperands();
      boolean _hasElements = false;
      for(final Expression operand : _operands) {
        if (!_hasElements) {
          _hasElements = true;
        } else {
          _builder.appendImmediate(" ^ ", "");
        }
        String _serialize = this.serialize(operand);
        _builder.append(_serialize);
      }
    }
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes the given AndExpression object.
   * 
   * @param expression The AndExpression object to serialize.
   * @return The serialized AndExpression object as a string.
   */
  protected String _serialize(final AndExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(");
    {
      EList<Expression> _operands = expression.getOperands();
      boolean _hasElements = false;
      for(final Expression operand : _operands) {
        if (!_hasElements) {
          _hasElements = true;
        } else {
          _builder.appendImmediate(" && ", "");
        }
        _builder.append("(");
        String _serialize = this.serialize(operand);
        _builder.append(_serialize);
        _builder.append(")");
      }
    }
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes the given ImplyExpression object.
   * 
   * @param expression The ImplyExpression object to serialize.
   * @return The serialized ImplyExpression object as a string.
   */
  protected String _serialize(final ImplyExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(!(");
    String _serialize = this.serialize(expression.getLeftOperand());
    _builder.append(_serialize);
    _builder.append(") || ");
    String _serialize_1 = this.serialize(expression.getRightOperand());
    _builder.append(_serialize_1);
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes the given IfThenElseExpression object.
   * 
   * @param expression The IfThenElseExpression object to serialize.
   * @return The serialized IfThenElseExpression object as a string.
   */
  protected String _serialize(final IfThenElseExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(");
    String _serialize = this.serialize(expression.getCondition());
    _builder.append(_serialize);
    _builder.append(" ? ");
    String _serialize_1 = this.serialize(expression.getThen());
    _builder.append(_serialize_1);
    _builder.append(" : ");
    String _serialize_2 = this.serialize(expression.getElse());
    _builder.append(_serialize_2);
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes the given EqualityExpression object.
   * 
   * @param expression The EqualityExpression object to serialize.
   * @return The serialized EqualityExpression object as a string.
   */
  protected String _serialize(final EqualityExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(");
    String _serialize = this.serialize(expression.getLeftOperand());
    _builder.append(_serialize);
    _builder.append(" == ");
    String _serialize_1 = this.serialize(expression.getRightOperand());
    _builder.append(_serialize_1);
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes the given InequalityExpression object.
   * 
   * @param expression The InequalityExpression object to serialize.
   * @return The serialized InequalityExpression object as a string.
   */
  protected String _serialize(final InequalityExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(");
    String _serialize = this.serialize(expression.getLeftOperand());
    _builder.append(_serialize);
    _builder.append(" != ");
    String _serialize_1 = this.serialize(expression.getRightOperand());
    _builder.append(_serialize_1);
    _builder.append(" )");
    return _builder.toString();
  }

  /**
   * Serializes the given GreaterExpression object.
   * 
   * @param expression The GreaterExpression object to serialize.
   * @return The serialized GreaterExpression object as a string.
   */
  protected String _serialize(final GreaterExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(");
    String _serialize = this.serialize(expression.getLeftOperand());
    _builder.append(_serialize);
    _builder.append(" > ");
    String _serialize_1 = this.serialize(expression.getRightOperand());
    _builder.append(_serialize_1);
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes the given GreaterEqualExpression object.
   * 
   * @param expression The GreaterEqualExpression object to serialize.
   * @return The serialized GreaterEqualExpression object as a string.
   */
  protected String _serialize(final GreaterEqualExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(");
    String _serialize = this.serialize(expression.getLeftOperand());
    _builder.append(_serialize);
    _builder.append(" >= ");
    String _serialize_1 = this.serialize(expression.getRightOperand());
    _builder.append(_serialize_1);
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes the given LessExpression object.
   * 
   * @param expression The LessExpression object to serialize.
   * @return The serialized LessExpression object as a string.
   */
  protected String _serialize(final LessExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(");
    String _serialize = this.serialize(expression.getLeftOperand());
    _builder.append(_serialize);
    _builder.append(" < ");
    String _serialize_1 = this.serialize(expression.getRightOperand());
    _builder.append(_serialize_1);
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes the given LessEqualExpression object.
   * 
   * @param expression The LessEqualExpression object to serialize.
   * @return The serialized LessEqualExpression object as a string.
   */
  protected String _serialize(final LessEqualExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(");
    String _serialize = this.serialize(expression.getLeftOperand());
    _builder.append(_serialize);
    _builder.append(" <= ");
    String _serialize_1 = this.serialize(expression.getRightOperand());
    _builder.append(_serialize_1);
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes an AddExpression into a string representation.
   * 
   * @param expression the AddExpression to serialize
   * @return the string representation of the AddExpression
   */
  protected String _serialize(final AddExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(");
    {
      EList<Expression> _operands = expression.getOperands();
      boolean _hasElements = false;
      for(final Expression operand : _operands) {
        if (!_hasElements) {
          _hasElements = true;
        } else {
          _builder.appendImmediate(" + ", "");
        }
        String _serialize = this.serialize(operand);
        _builder.append(_serialize);
      }
    }
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes a SubtractExpression into a string representation.
   * 
   * @param expression the SubtractExpression to serialize
   * @return the string representation of the SubtractExpression
   */
  protected String _serialize(final SubtractExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(");
    String _serialize = this.serialize(expression.getLeftOperand());
    _builder.append(_serialize);
    _builder.append(" - ");
    String _serialize_1 = this.serialize(expression.getRightOperand());
    _builder.append(_serialize_1);
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes a MultiplyExpression into a string representation.
   * 
   * @param expression the MultiplyExpression to serialize
   * @return the string representation of the MultiplyExpression
   */
  protected String _serialize(final MultiplyExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(");
    {
      EList<Expression> _operands = expression.getOperands();
      boolean _hasElements = false;
      for(final Expression operand : _operands) {
        if (!_hasElements) {
          _hasElements = true;
        } else {
          _builder.appendImmediate(" * ", "");
        }
        String _serialize = this.serialize(operand);
        _builder.append(_serialize);
      }
    }
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes a DivideExpression into a string representation.
   * 
   * @param expression the DivideExpression to serialize
   * @return the string representation of the DivideExpression
   */
  protected String _serialize(final DivideExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(");
    String _serialize = this.serialize(expression.getLeftOperand());
    _builder.append(_serialize);
    _builder.append(" / ");
    String _serialize_1 = this.serialize(expression.getRightOperand());
    _builder.append(_serialize_1);
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes a ModExpression into a string representation.
   * 
   * @param expression the ModExpression to serialize
   * @return the string representation of the ModExpression
   */
  protected String _serialize(final ModExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("(");
    String _serialize = this.serialize(expression.getLeftOperand());
    _builder.append(_serialize);
    _builder.append(" % ");
    String _serialize_1 = this.serialize(expression.getRightOperand());
    _builder.append(_serialize_1);
    _builder.append(")");
    return _builder.toString();
  }

  /**
   * Serializes an UnaryPlusExpression into a string representation.
   * 
   * @param expression the UnaryPlusExpression to serialize
   * @return the string representation of the UnaryPlusExpression
   */
  protected String _serialize(final UnaryPlusExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("+");
    String _serialize = this.serialize(expression.getOperand());
    _builder.append(_serialize);
    return _builder.toString();
  }

  /**
   * Serializes an UnaryMinusExpression into a string representation.
   * 
   * @param expression the UnaryMinusExpression to serialize
   * @return the string representation of the UnaryMinusExpression
   */
  protected String _serialize(final UnaryMinusExpression expression) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("-");
    String _serialize = this.serialize(expression.getOperand());
    _builder.append(_serialize);
    return _builder.toString();
  }

  public String serialize(final Expression expression) {
    if (expression instanceof EqualityExpression) {
      return _serialize((EqualityExpression)expression);
    } else if (expression instanceof FalseExpression) {
      return _serialize((FalseExpression)expression);
    } else if (expression instanceof GreaterEqualExpression) {
      return _serialize((GreaterEqualExpression)expression);
    } else if (expression instanceof GreaterExpression) {
      return _serialize((GreaterExpression)expression);
    } else if (expression instanceof InequalityExpression) {
      return _serialize((InequalityExpression)expression);
    } else if (expression instanceof LessEqualExpression) {
      return _serialize((LessEqualExpression)expression);
    } else if (expression instanceof LessExpression) {
      return _serialize((LessExpression)expression);
    } else if (expression instanceof TrueExpression) {
      return _serialize((TrueExpression)expression);
    } else if (expression instanceof AndExpression) {
      return _serialize((AndExpression)expression);
    } else if (expression instanceof DecimalLiteralExpression) {
      return _serialize((DecimalLiteralExpression)expression);
    } else if (expression instanceof DirectReferenceExpression) {
      return _serialize((DirectReferenceExpression)expression);
    } else if (expression instanceof ImplyExpression) {
      return _serialize((ImplyExpression)expression);
    } else if (expression instanceof IntegerLiteralExpression) {
      return _serialize((IntegerLiteralExpression)expression);
    } else if (expression instanceof NotExpression) {
      return _serialize((NotExpression)expression);
    } else if (expression instanceof OrExpression) {
      return _serialize((OrExpression)expression);
    } else if (expression instanceof RationalLiteralExpression) {
      return _serialize((RationalLiteralExpression)expression);
    } else if (expression instanceof XorExpression) {
      return _serialize((XorExpression)expression);
    } else if (expression instanceof AddExpression) {
      return _serialize((AddExpression)expression);
    } else if (expression instanceof DivideExpression) {
      return _serialize((DivideExpression)expression);
    } else if (expression instanceof ElseExpression) {
      return _serialize((ElseExpression)expression);
    } else if (expression instanceof EnumerationLiteralExpression) {
      return _serialize((EnumerationLiteralExpression)expression);
    } else if (expression instanceof ModExpression) {
      return _serialize((ModExpression)expression);
    } else if (expression instanceof MultiplyExpression) {
      return _serialize((MultiplyExpression)expression);
    } else if (expression instanceof SubtractExpression) {
      return _serialize((SubtractExpression)expression);
    } else if (expression instanceof UnaryMinusExpression) {
      return _serialize((UnaryMinusExpression)expression);
    } else if (expression instanceof UnaryPlusExpression) {
      return _serialize((UnaryPlusExpression)expression);
    } else if (expression instanceof IfThenElseExpression) {
      return _serialize((IfThenElseExpression)expression);
    } else if (expression != null) {
      return _serialize(expression);
    } else {
      throw new IllegalArgumentException("Unhandled parameter types: " +
        Arrays.<Object>asList(expression).toString());
    }
  }
}
