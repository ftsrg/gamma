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

import hu.bme.mit.gamma.expression.model.ClockVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.VariableDeclarationAnnotation;
import hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures;
import hu.bme.mit.gamma.xsts.model.Action;
import hu.bme.mit.gamma.xsts.model.AssignmentAction;
import hu.bme.mit.gamma.xsts.model.EmptyAction;
import hu.bme.mit.gamma.xsts.model.HavocAction;
import hu.bme.mit.gamma.xsts.model.IfAction;
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction;
import hu.bme.mit.gamma.xsts.model.ParallelAction;
import hu.bme.mit.gamma.xsts.model.SequentialAction;
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction;
import hu.bme.mit.gamma.xsts.model.XSTS;
import java.util.Arrays;
import org.eclipse.emf.common.util.EList;
import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.IterableExtensions;

/**
 * This class provides a serializer for actions in XSTS models.
 */
@SuppressWarnings("all")
public class ActionSerializer {
  private final HavocSerializer havocSerializer = new HavocSerializer();

  private final ExpressionSerializer expressionSerializer = new ExpressionSerializer();

  private final VariableDeclarationSerializer variableDeclarationSerializer = new VariableDeclarationSerializer();

  /**
   * Serializes an initializing action.
   * 
   * @param xSts an XSTS model
   * @return a CharSequence that represents the serialized initializing action
   */
  public CharSequence serializeInitializingAction(final XSTS xSts) {
    StringConcatenation _builder = new StringConcatenation();
    CharSequence _serialize = this.serialize(XstsDerivedFeatures.getInitializingAction(xSts));
    _builder.append(_serialize);
    return _builder;
  }

  /**
   * Throws an IllegalArgumentException if the action is not supported.
   * 
   * @param action an action
   * @return a CharSequence that represents the serialized action
   */
  protected CharSequence _serialize(final Action action) {
    throw new IllegalArgumentException(("Not supported action: " + action));
  }

  /**
   * Serializes an IfAction.
   * 
   * @param action an IfAction
   * @return a CharSequence that represents the serialized IfAction
   */
  protected CharSequence _serialize(final IfAction action) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("if (");
    String _serialize = this.expressionSerializer.serialize(action.getCondition());
    _builder.append(_serialize);
    _builder.append(") {");
    _builder.newLineIfNotEmpty();
    _builder.append("\t");
    CharSequence _serialize_1 = this.serialize(action.getThen());
    _builder.append(_serialize_1, "\t");
    _builder.newLineIfNotEmpty();
    _builder.append("}else {");
    _builder.newLine();
    _builder.append("\t");
    CharSequence _serialize_2 = this.serialize(action.getElse());
    _builder.append(_serialize_2, "\t");
    _builder.newLineIfNotEmpty();
    _builder.append("}");
    _builder.newLine();
    return _builder;
  }

  /**
   * Serializes a SequentialAction.
   * 
   * @param action a SequentialAction
   * @return a CharSequence that represents the serialized SequentialAction
   */
  protected CharSequence _serialize(final SequentialAction action) {
    StringConcatenation _builder = new StringConcatenation();
    {
      EList<Action> _actions = action.getActions();
      boolean _hasElements = false;
      for(final Action xstsSubaction : _actions) {
        if (!_hasElements) {
          _hasElements = true;
        } else {
          String _lineSeparator = System.lineSeparator();
          _builder.appendImmediate(_lineSeparator, "");
        }
        CharSequence _serialize = this.serialize(xstsSubaction);
        _builder.append(_serialize);
      }
    }
    return _builder;
  }

  /**
   * Serializes a ParallelAction.
   * 
   * @param action a ParallelAction
   * @return a CharSequence that represents the serialized ParallelAction
   */
  protected CharSequence _serialize(final ParallelAction action) {
    StringConcatenation _builder = new StringConcatenation();
    {
      EList<Action> _actions = action.getActions();
      boolean _hasElements = false;
      for(final Action xstsSubaction : _actions) {
        if (!_hasElements) {
          _hasElements = true;
        } else {
          String _lineSeparator = System.lineSeparator();
          _builder.appendImmediate(_lineSeparator, "");
        }
        CharSequence _serialize = this.serialize(xstsSubaction);
        _builder.append(_serialize);
      }
    }
    return _builder;
  }

  /**
   * Serializes a NonDeterministicAction.
   * 
   * @param action a NonDeterministicAction
   * @return a CharSequence that represents the serialized NonDeterministicAction
   */
  protected CharSequence _serialize(final NonDeterministicAction action) {
    StringConcatenation _builder = new StringConcatenation();
    {
      EList<Action> _actions = action.getActions();
      boolean _hasElements = false;
      for(final Action xstsSubaction : _actions) {
        if (!_hasElements) {
          _hasElements = true;
        } else {
          String _lineSeparator = System.lineSeparator();
          _builder.appendImmediate(_lineSeparator, "");
        }
        CharSequence _serialize = this.serialize(xstsSubaction);
        _builder.append(_serialize);
      }
    }
    return _builder;
  }

  /**
   * Serializes a HavocAction.
   * 
   * @param action a HavocAction
   * @return a CharSequence that represents the serialized HavocAction
   */
  protected CharSequence _serialize(final HavocAction action) {
    StringConcatenation _builder = new StringConcatenation();
    String _serialize = this.expressionSerializer.serialize(action.getLhs());
    _builder.append(_serialize);
    _builder.append(" = ");
    String _serialize_1 = this.havocSerializer.serialize(action.getLhs());
    _builder.append(_serialize_1);
    _builder.append(";");
    return _builder;
  }

  /**
   * Serializes an AssignmentAction.
   * 
   * @param action an AssignmentAction
   * @return a CharSequence that represents the serialized AssignmentAction
   */
  protected CharSequence _serialize(final AssignmentAction action) {
    StringConcatenation _builder = new StringConcatenation();
    String _serialize = this.expressionSerializer.serialize(action.getLhs());
    _builder.append(_serialize);
    _builder.append(" = ");
    String _serialize_1 = this.expressionSerializer.serialize(action.getRhs());
    _builder.append(_serialize_1);
    _builder.append(";");
    return _builder;
  }

  /**
   * Serializes a VariableDeclarationAction.
   * 
   * @param action a VariableDeclarationAction
   * @return a CharSequence that represents the serialized VariableDeclarationAction
   */
  protected CharSequence _serialize(final VariableDeclarationAction action) {
    StringConcatenation _builder = new StringConcatenation();
    final Function1<VariableDeclarationAnnotation, Boolean> _function = (VariableDeclarationAnnotation type) -> {
      return Boolean.valueOf((type instanceof ClockVariableDeclarationAnnotation));
    };
    String _serialize = this.variableDeclarationSerializer.serialize(
      action.getVariableDeclaration().getType(), 
      IterableExtensions.<VariableDeclarationAnnotation>exists(action.getVariableDeclaration().getAnnotations(), _function), 
      action.getVariableDeclaration().getName());
    _builder.append(_serialize);
    _builder.append(" ");
    String _name = action.getVariableDeclaration().getName();
    _builder.append(_name);
    _builder.append(";");
    return _builder;
  }

  /**
   * Serializes an EmptyAction.
   * 
   * @param action an EmptyAction
   * @return a CharSequence that represents the serialized EmptyAction
   */
  protected CharSequence _serialize(final EmptyAction action) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("/* Empty Action */");
    return _builder;
  }

  public CharSequence serialize(final Action action) {
    if (action instanceof AssignmentAction) {
      return _serialize((AssignmentAction)action);
    } else if (action instanceof HavocAction) {
      return _serialize((HavocAction)action);
    } else if (action instanceof NonDeterministicAction) {
      return _serialize((NonDeterministicAction)action);
    } else if (action instanceof ParallelAction) {
      return _serialize((ParallelAction)action);
    } else if (action instanceof SequentialAction) {
      return _serialize((SequentialAction)action);
    } else if (action instanceof EmptyAction) {
      return _serialize((EmptyAction)action);
    } else if (action instanceof IfAction) {
      return _serialize((IfAction)action);
    } else if (action instanceof VariableDeclarationAction) {
      return _serialize((VariableDeclarationAction)action);
    } else if (action != null) {
      return _serialize(action);
    } else {
      throw new IllegalArgumentException("Unhandled parameter types: " +
        Arrays.<Object>asList(action).toString());
    }
  }
}
