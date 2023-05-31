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
package hu.bme.mit.gamma.xsts.codegeneration.c;

import com.google.common.collect.Iterables;
import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.ClockVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclarationAnnotation;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.VariableGroupRetriever;
import hu.bme.mit.gamma.xsts.codegeneration.c.model.CodeModel;
import hu.bme.mit.gamma.xsts.codegeneration.c.model.HeaderModel;
import hu.bme.mit.gamma.xsts.codegeneration.c.platforms.SupportedPlatforms;
import hu.bme.mit.gamma.xsts.codegeneration.c.serializer.ActionSerializer;
import hu.bme.mit.gamma.xsts.codegeneration.c.serializer.ExpressionSerializer;
import hu.bme.mit.gamma.xsts.codegeneration.c.serializer.TypeDeclarationSerializer;
import hu.bme.mit.gamma.xsts.codegeneration.c.serializer.VariableDeclarationSerializer;
import hu.bme.mit.gamma.xsts.model.XSTS;
import hu.bme.mit.gamma.xsts.model.XTransition;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.function.Consumer;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.common.util.URI;
import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.Exceptions;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.eclipse.xtext.xbase.lib.StringExtensions;

/**
 * The {@code CodeBuilder} class implements the {@code IStatechartCode} interface and is responsible for generating C code from an XSTS model.
 */
@SuppressWarnings("all")
public class CodeBuilder implements IStatechartCode {
  /**
   * The XSTS (Extended Symbolic Transition Systems) used for code generation.
   */
  private XSTS xsts;

  /**
   * The name of the component.
   */
  private String name;

  /**
   * The name of the statechart.
   */
  private String stName;

  /**
   * The code model for generating code.
   */
  private CodeModel code;

  /**
   * The header model for generating code.
   */
  private HeaderModel header;

  /**
   * The supported platform for code generation.
   */
  private SupportedPlatforms platform = SupportedPlatforms.UNIX;

  /**
   * Serializers used for code generation
   */
  private final ActionSerializer actionSerializer = new ActionSerializer();

  private final ExpressionSerializer expressionSerializer = new ExpressionSerializer();

  private final VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE;

  private final TypeDeclarationSerializer typeDeclarationSerializer = new TypeDeclarationSerializer();

  private final VariableDeclarationSerializer variableDeclarationSerializer = new VariableDeclarationSerializer();

  /**
   * The set of input variable declarations.
   */
  private Set<VariableDeclaration> inputs = new HashSet<VariableDeclaration>();

  /**
   * The set of output variable declarations.
   */
  private Set<VariableDeclaration> outputs = new HashSet<VariableDeclaration>();

  /**
   * The list of components within the system. It is used to determine wether 'statechart->' is neccesarry.
   */
  public static List<String> componentVariables = new ArrayList<String>();

  /**
   * Constructs a {@code CodeBuilder} object with the given {@code XSTS}.
   * 
   * @param xsts the XSTS (Extended Symbolic Transition Systems) used for code generation
   */
  public CodeBuilder(final XSTS xsts) {
    this.xsts = xsts;
    this.name = StringExtensions.toFirstUpper(xsts.getName());
    this.stName = (this.name + "Statechart");
    CodeModel _codeModel = new CodeModel(this.name);
    this.code = _codeModel;
    HeaderModel _headerModel = new HeaderModel(this.name);
    this.header = _headerModel;
    final Consumer<VariableDeclaration> _function = (VariableDeclaration variableDeclaration) -> {
      CodeBuilder.componentVariables.add(variableDeclaration.getName());
    };
    xsts.getVariableDeclarations().forEach(_function);
    this.inputs.addAll(this.variableGroupRetriever.getSystemInEventVariableGroup(xsts).getVariables());
    final Function1<VariableDeclaration, Boolean> _function_1 = (VariableDeclaration it) -> {
      return Boolean.valueOf(ExpressionModelDerivedFeatures.isEnvironmentResettable(it));
    };
    Iterables.<VariableDeclaration>addAll(this.inputs, IterableExtensions.<VariableDeclaration>filter(this.variableGroupRetriever.getSystemInEventParameterVariableGroup(xsts).getVariables(), _function_1));
    this.outputs.addAll(this.variableGroupRetriever.getSystemOutEventVariableGroup(xsts).getVariables());
    final Function1<VariableDeclaration, Boolean> _function_2 = (VariableDeclaration it) -> {
      return Boolean.valueOf(ExpressionModelDerivedFeatures.isEnvironmentResettable(it));
    };
    Iterables.<VariableDeclaration>addAll(this.outputs, IterableExtensions.<VariableDeclaration>filter(this.variableGroupRetriever.getSystemOutEventParameterVariableGroup(xsts).getVariables(), _function_2));
  }

  /**
   * Sets the platform for code generation.
   * 
   * @param platform the platform
   */
  @Override
  public void setPlatform(final SupportedPlatforms platform) {
    this.platform = platform;
  }

  /**
   * Constructs the statechart's header code.
   */
  @Override
  public void constructHeader() {
    StringConcatenation _builder = new StringConcatenation();
    {
      EList<TypeDeclaration> _typeDeclarations = this.xsts.getTypeDeclarations();
      boolean _hasElements = false;
      for(final TypeDeclaration typeDeclaration : _typeDeclarations) {
        if (!_hasElements) {
          _hasElements = true;
        } else {
          String _lineSeparator = System.lineSeparator();
          _builder.appendImmediate(_lineSeparator, "");
        }
        String _serialize = this.typeDeclarationSerializer.serialize(typeDeclaration);
        _builder.append(_serialize);
        _builder.newLineIfNotEmpty();
      }
    }
    this.header.addContent(_builder.toString());
    StringConcatenation _builder_1 = new StringConcatenation();
    _builder_1.append("/* Structure representing ");
    _builder_1.append(this.name);
    _builder_1.append(" component */");
    _builder_1.newLineIfNotEmpty();
    _builder_1.append("typedef struct {");
    _builder_1.newLine();
    {
      EList<VariableDeclaration> _variableDeclarations = this.xsts.getVariableDeclarations();
      for(final VariableDeclaration variableDeclaration : _variableDeclarations) {
        _builder_1.append("\t");
        final Function1<VariableDeclarationAnnotation, Boolean> _function = (VariableDeclarationAnnotation type) -> {
          return Boolean.valueOf((type instanceof ClockVariableDeclarationAnnotation));
        };
        String _serialize_1 = this.variableDeclarationSerializer.serialize(
          variableDeclaration.getType(), 
          IterableExtensions.<VariableDeclarationAnnotation>exists(variableDeclaration.getAnnotations(), _function), 
          variableDeclaration.getName());
        _builder_1.append(_serialize_1, "\t");
        _builder_1.append(" ");
        String _name = variableDeclaration.getName();
        _builder_1.append(_name, "\t");
        _builder_1.append(";");
        _builder_1.newLineIfNotEmpty();
      }
    }
    _builder_1.append("} ");
    _builder_1.append(this.stName);
    _builder_1.append(";");
    _builder_1.newLineIfNotEmpty();
    this.header.addContent(_builder_1.toString());
    StringConcatenation _builder_2 = new StringConcatenation();
    _builder_2.append("/* Reset component ");
    _builder_2.append(this.name);
    _builder_2.append(" */");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("void reset");
    _builder_2.append(this.stName);
    _builder_2.append("(");
    _builder_2.append(this.stName);
    _builder_2.append("* statechart);");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("/* Initialize component ");
    _builder_2.append(this.name);
    _builder_2.append(" */");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("void initialize");
    _builder_2.append(this.stName);
    _builder_2.append("(");
    _builder_2.append(this.stName);
    _builder_2.append("* statechart);");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("/* Entry event of component ");
    _builder_2.append(this.name);
    _builder_2.append(" */");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("void entryEvents");
    _builder_2.append(this.stName);
    _builder_2.append("(");
    _builder_2.append(this.stName);
    _builder_2.append("* statechart);");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("/* Clear input events of component ");
    _builder_2.append(this.name);
    _builder_2.append(" */");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("void clearInEvents");
    _builder_2.append(this.stName);
    _builder_2.append("(");
    _builder_2.append(this.stName);
    _builder_2.append("* statechart);");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("/* Clear output events of component ");
    _builder_2.append(this.name);
    _builder_2.append(" */");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("void clearOutEvents");
    _builder_2.append(this.stName);
    _builder_2.append("(");
    _builder_2.append(this.stName);
    _builder_2.append("* statechart);");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("/* Transitions of component ");
    _builder_2.append(this.name);
    _builder_2.append(" */");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("void changeState");
    _builder_2.append(this.stName);
    _builder_2.append("(");
    _builder_2.append(this.stName);
    _builder_2.append("* statechart);");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("/* Run cycle in component ");
    _builder_2.append(this.name);
    _builder_2.append(" */");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("void runCycle");
    _builder_2.append(this.stName);
    _builder_2.append("(");
    _builder_2.append(this.stName);
    _builder_2.append("* statechart);");
    _builder_2.newLineIfNotEmpty();
    this.header.addContent(_builder_2.toString());
    StringConcatenation _builder_3 = new StringConcatenation();
    _builder_3.append("#endif /* ");
    String _upperCase = this.name.toUpperCase();
    _builder_3.append(_upperCase);
    _builder_3.append("_HEADER */");
    _builder_3.newLineIfNotEmpty();
    this.header.addContent(_builder_3.toString());
  }

  /**
   * Constructs the statechart's C code.
   */
  @Override
  public void constructCode() {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("/* Reset component ");
    _builder.append(this.name);
    _builder.append(" */");
    _builder.newLineIfNotEmpty();
    _builder.append("void reset");
    _builder.append(this.stName);
    _builder.append("(");
    _builder.append(this.stName);
    _builder.append("* statechart) {");
    _builder.newLineIfNotEmpty();
    _builder.append("\t");
    CharSequence _serialize = this.actionSerializer.serialize(this.xsts.getVariableInitializingTransition().getAction());
    _builder.append(_serialize, "\t");
    _builder.newLineIfNotEmpty();
    _builder.append("}");
    _builder.newLine();
    this.code.addContent(_builder.toString());
    StringConcatenation _builder_1 = new StringConcatenation();
    _builder_1.append("/* Initialize component ");
    _builder_1.append(this.name);
    _builder_1.append(" */");
    _builder_1.newLineIfNotEmpty();
    _builder_1.append("void initialize");
    _builder_1.append(this.stName);
    _builder_1.append("(");
    _builder_1.append(this.stName);
    _builder_1.append("* statechart) {");
    _builder_1.newLineIfNotEmpty();
    _builder_1.append("\t");
    CharSequence _serialize_1 = this.actionSerializer.serialize(this.xsts.getConfigurationInitializingTransition().getAction());
    _builder_1.append(_serialize_1, "\t");
    _builder_1.newLineIfNotEmpty();
    _builder_1.append("}");
    _builder_1.newLine();
    this.code.addContent(_builder_1.toString());
    StringConcatenation _builder_2 = new StringConcatenation();
    _builder_2.append("/* Entry event of component ");
    _builder_2.append(this.name);
    _builder_2.append(" */");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("void entryEvents");
    _builder_2.append(this.stName);
    _builder_2.append("(");
    _builder_2.append(this.stName);
    _builder_2.append("* statechart) {");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("\t");
    CharSequence _serialize_2 = this.actionSerializer.serialize(this.xsts.getEntryEventTransition().getAction());
    _builder_2.append(_serialize_2, "\t");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("}");
    _builder_2.newLine();
    this.code.addContent(_builder_2.toString());
    StringConcatenation _builder_3 = new StringConcatenation();
    _builder_3.append("/* Clear input events of component ");
    _builder_3.append(this.name);
    _builder_3.append(" */");
    _builder_3.newLineIfNotEmpty();
    _builder_3.append("void clearInEvents");
    _builder_3.append(this.stName);
    _builder_3.append("(");
    _builder_3.append(this.stName);
    _builder_3.append("* statechart) {");
    _builder_3.newLineIfNotEmpty();
    _builder_3.append("\t");
    {
      boolean _hasElements = false;
      for(final VariableDeclaration input : this.inputs) {
        if (!_hasElements) {
          _hasElements = true;
        } else {
          String _lineSeparator = System.lineSeparator();
          _builder_3.appendImmediate(_lineSeparator, "\t");
        }
        _builder_3.append("statechart->");
        String _name = input.getName();
        _builder_3.append(_name, "\t");
        _builder_3.append(" = ");
        String _serialize_3 = this.expressionSerializer.serialize(input.getExpression());
        _builder_3.append(_serialize_3, "\t");
        _builder_3.append(";");
      }
    }
    _builder_3.newLineIfNotEmpty();
    _builder_3.append("}");
    _builder_3.newLine();
    this.code.addContent(_builder_3.toString());
    StringConcatenation _builder_4 = new StringConcatenation();
    _builder_4.append("/* Clear output events of component ");
    _builder_4.append(this.name);
    _builder_4.append(" */");
    _builder_4.newLineIfNotEmpty();
    _builder_4.append("void clearOutEvents");
    _builder_4.append(this.stName);
    _builder_4.append("(");
    _builder_4.append(this.stName);
    _builder_4.append("* statechart) {");
    _builder_4.newLineIfNotEmpty();
    _builder_4.append("\t");
    {
      boolean _hasElements_1 = false;
      for(final VariableDeclaration output : this.outputs) {
        if (!_hasElements_1) {
          _hasElements_1 = true;
        } else {
          String _lineSeparator_1 = System.lineSeparator();
          _builder_4.appendImmediate(_lineSeparator_1, "\t");
        }
        _builder_4.append("statechart->");
        String _name_1 = output.getName();
        _builder_4.append(_name_1, "\t");
        _builder_4.append(" = ");
        String _serialize_4 = this.expressionSerializer.serialize(output.getExpression());
        _builder_4.append(_serialize_4, "\t");
        _builder_4.append(";");
      }
    }
    _builder_4.newLineIfNotEmpty();
    _builder_4.append("}");
    _builder_4.newLine();
    this.code.addContent(_builder_4.toString());
    StringConcatenation _builder_5 = new StringConcatenation();
    _builder_5.append("/* Transitions of component ");
    _builder_5.append(this.name);
    _builder_5.append(" */");
    _builder_5.newLineIfNotEmpty();
    _builder_5.append("void changeState");
    _builder_5.append(this.stName);
    _builder_5.append("(");
    _builder_5.append(this.stName);
    _builder_5.append("* statechart) {");
    _builder_5.newLineIfNotEmpty();
    _builder_5.append("\t");
    {
      EList<XTransition> _transitions = this.xsts.getTransitions();
      boolean _hasElements_2 = false;
      for(final XTransition transition : _transitions) {
        if (!_hasElements_2) {
          _hasElements_2 = true;
        } else {
          String _lineSeparator_2 = System.lineSeparator();
          _builder_5.appendImmediate(_lineSeparator_2, "\t");
        }
        CharSequence _serialize_5 = this.actionSerializer.serialize(transition.getAction());
        _builder_5.append(_serialize_5, "\t");
      }
    }
    _builder_5.newLineIfNotEmpty();
    _builder_5.append("}");
    _builder_5.newLine();
    this.code.addContent(_builder_5.toString());
    StringConcatenation _builder_6 = new StringConcatenation();
    _builder_6.append("/* Run cycle of component ");
    _builder_6.append(this.name);
    _builder_6.append(" */");
    _builder_6.newLineIfNotEmpty();
    _builder_6.append("void runCycle");
    _builder_6.append(this.stName);
    _builder_6.append("(");
    _builder_6.append(this.stName);
    _builder_6.append("* statechart) {");
    _builder_6.newLineIfNotEmpty();
    _builder_6.append("\t");
    _builder_6.append("clearOutEvents");
    _builder_6.append(this.stName, "\t");
    _builder_6.append("(statechart);");
    _builder_6.newLineIfNotEmpty();
    _builder_6.append("\t");
    _builder_6.append("changeState");
    _builder_6.append(this.stName, "\t");
    _builder_6.append("(statechart);");
    _builder_6.newLineIfNotEmpty();
    _builder_6.append("\t");
    _builder_6.append("clearInEvents");
    _builder_6.append(this.stName, "\t");
    _builder_6.append("(statechart);");
    _builder_6.newLineIfNotEmpty();
    _builder_6.append("}");
    _builder_6.newLine();
    this.code.addContent(_builder_6.toString());
  }

  /**
   * Saves the generated code and header models to the specified URI.
   * 
   * @param uri the URI to save the models to
   */
  @Override
  public void save(final URI uri) {
    try {
      URI local = uri.appendSegment("src-gen");
      String _fileString = local.toFileString();
      boolean _exists = new File(_fileString).exists();
      boolean _not = (!_exists);
      if (_not) {
        Files.createDirectories(Paths.get(local.toFileString()));
      }
      local = local.appendSegment(this.name.toLowerCase());
      String _fileString_1 = local.toFileString();
      boolean _exists_1 = new File(_fileString_1).exists();
      boolean _not_1 = (!_exists_1);
      if (_not_1) {
        Files.createDirectories(Paths.get(local.toFileString()));
      }
      this.code.save(local);
      this.header.save(local);
    } catch (Throwable _e) {
      throw Exceptions.sneakyThrow(_e);
    }
  }
}
