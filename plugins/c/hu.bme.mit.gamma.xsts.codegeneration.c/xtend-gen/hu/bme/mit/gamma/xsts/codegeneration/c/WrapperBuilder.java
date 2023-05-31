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

import hu.bme.mit.gamma.expression.model.ClockVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclarationAnnotation;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.VariableGroupRetriever;
import hu.bme.mit.gamma.xsts.codegeneration.c.model.CodeModel;
import hu.bme.mit.gamma.xsts.codegeneration.c.model.HeaderModel;
import hu.bme.mit.gamma.xsts.codegeneration.c.platforms.IPlatform;
import hu.bme.mit.gamma.xsts.codegeneration.c.platforms.Platforms;
import hu.bme.mit.gamma.xsts.codegeneration.c.platforms.SupportedPlatforms;
import hu.bme.mit.gamma.xsts.codegeneration.c.serializer.VariableDeclarationSerializer;
import hu.bme.mit.gamma.xsts.model.XSTS;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashSet;
import java.util.Set;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.common.util.URI;
import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.Exceptions;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.eclipse.xtext.xbase.lib.StringExtensions;

/**
 * The WrapperBuilder class implements the IStatechartCode interface and is responsible for generating the wrapper code.
 */
@SuppressWarnings("all")
public class WrapperBuilder implements IStatechartCode {
  /**
   * The XSTS (Extended Symbolic Transition Systems) used for code generation.
   */
  private XSTS xsts;

  /**
   * The name of the wrapper component.
   */
  private String name;

  /**
   * The name of the original statechart.
   */
  private String stName;

  /**
   * The code model for generating wrapper code.
   */
  private CodeModel code;

  /**
   * The header model for generating wrapper code.
   */
  private HeaderModel header;

  /**
   * The supported platform for code generation.
   */
  private SupportedPlatforms platform = SupportedPlatforms.UNIX;

  /**
   * Serializers used for code generation
   */
  private final VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE;

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
   * Constructs a WrapperBuilder object.
   * 
   * @param xsts The XSTS (Extended Symbolic Transition Systems) used for wrapper code generation.
   */
  public WrapperBuilder(final XSTS xsts) {
    this.xsts = xsts;
    String _firstUpper = StringExtensions.toFirstUpper(xsts.getName());
    String _plus = (_firstUpper + "Wrapper");
    this.name = _plus;
    String _name = xsts.getName();
    String _plus_1 = (_name + "Statechart");
    this.stName = _plus_1;
    CodeModel _codeModel = new CodeModel(this.name);
    this.code = _codeModel;
    HeaderModel _headerModel = new HeaderModel(this.name);
    this.header = _headerModel;
    this.inputs.addAll(this.variableGroupRetriever.getSystemInEventVariableGroup(xsts).getVariables());
    this.inputs.addAll(this.variableGroupRetriever.getSystemInEventParameterVariableGroup(xsts).getVariables());
    this.outputs.addAll(this.variableGroupRetriever.getSystemOutEventVariableGroup(xsts).getVariables());
    this.outputs.addAll(this.variableGroupRetriever.getSystemOutEventParameterVariableGroup(xsts).getVariables());
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
   * Constructs the statechart wrapper's header code.
   */
  @Override
  public void constructHeader() {
    StringConcatenation _builder = new StringConcatenation();
    String _headers = Platforms.get(this.platform).getHeaders();
    _builder.append(_headers);
    _builder.newLineIfNotEmpty();
    this.header.addContent(_builder.toString());
    StringConcatenation _builder_1 = new StringConcatenation();
    _builder_1.append("#include \"");
    String _lowerCase = this.xsts.getName().toLowerCase();
    _builder_1.append(_lowerCase);
    _builder_1.append(".h\"");
    _builder_1.newLineIfNotEmpty();
    this.header.addContent(_builder_1.toString());
    StringConcatenation _builder_2 = new StringConcatenation();
    _builder_2.append("/* Wrapper for statechart ");
    _builder_2.append(this.stName);
    _builder_2.append(" */");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("typedef struct {");
    _builder_2.newLine();
    _builder_2.append("\t");
    _builder_2.append(this.stName, "\t");
    _builder_2.append(" ");
    String _lowerCase_1 = this.stName.toLowerCase();
    _builder_2.append(_lowerCase_1, "\t");
    _builder_2.append(";");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("\t");
    String _struct = Platforms.get(this.platform).getStruct();
    _builder_2.append(_struct, "\t");
    _builder_2.newLineIfNotEmpty();
    _builder_2.append("} ");
    _builder_2.append(this.name);
    _builder_2.append(";");
    _builder_2.newLineIfNotEmpty();
    this.header.addContent(_builder_2.toString());
    StringConcatenation _builder_3 = new StringConcatenation();
    _builder_3.append("/* Initialize component ");
    _builder_3.append(this.name);
    _builder_3.append(" */");
    _builder_3.newLineIfNotEmpty();
    _builder_3.append("void initialize");
    _builder_3.append(this.name);
    _builder_3.append("(");
    _builder_3.append(this.name);
    _builder_3.append(" *statechart);");
    _builder_3.newLineIfNotEmpty();
    _builder_3.append("/* Calculate Timeout events */");
    _builder_3.newLine();
    _builder_3.append("void time");
    _builder_3.append(this.name);
    _builder_3.append("(");
    _builder_3.append(this.name);
    _builder_3.append("* statechart);");
    _builder_3.newLineIfNotEmpty();
    _builder_3.append("/* Run cycle of component ");
    _builder_3.append(this.name);
    _builder_3.append(" */");
    _builder_3.newLineIfNotEmpty();
    _builder_3.append("void runCycle");
    _builder_3.append(this.name);
    _builder_3.append("(");
    _builder_3.append(this.name);
    _builder_3.append("* statechart);");
    _builder_3.newLineIfNotEmpty();
    this.header.addContent(_builder_3.toString());
    StringConcatenation _builder_4 = new StringConcatenation();
    {
      for(final VariableDeclaration variable : this.inputs) {
        _builder_4.append("/* Setter for ");
        String _firstUpper = StringExtensions.toFirstUpper(variable.getName());
        _builder_4.append(_firstUpper);
        _builder_4.append(" */");
        _builder_4.newLineIfNotEmpty();
        _builder_4.append("void set");
        String _firstUpper_1 = StringExtensions.toFirstUpper(variable.getName());
        _builder_4.append(_firstUpper_1);
        _builder_4.append("(");
        _builder_4.append(this.name);
        _builder_4.append("* statechart, ");
        final Function1<VariableDeclarationAnnotation, Boolean> _function = (VariableDeclarationAnnotation type) -> {
          return Boolean.valueOf((type instanceof ClockVariableDeclarationAnnotation));
        };
        String _serialize = this.variableDeclarationSerializer.serialize(
          variable.getType(), 
          IterableExtensions.<VariableDeclarationAnnotation>exists(variable.getAnnotations(), _function), 
          variable.getName());
        _builder_4.append(_serialize);
        _builder_4.append(" value);");
        _builder_4.newLineIfNotEmpty();
      }
    }
    this.header.addContent(_builder_4.toString());
    StringConcatenation _builder_5 = new StringConcatenation();
    {
      for(final VariableDeclaration variable_1 : this.outputs) {
        _builder_5.append("/* Getter for ");
        String _firstUpper_2 = StringExtensions.toFirstUpper(variable_1.getName());
        _builder_5.append(_firstUpper_2);
        _builder_5.append(" */");
        _builder_5.newLineIfNotEmpty();
        final Function1<VariableDeclarationAnnotation, Boolean> _function_1 = (VariableDeclarationAnnotation type) -> {
          return Boolean.valueOf((type instanceof ClockVariableDeclarationAnnotation));
        };
        String _serialize_1 = this.variableDeclarationSerializer.serialize(
          variable_1.getType(), 
          IterableExtensions.<VariableDeclarationAnnotation>exists(variable_1.getAnnotations(), _function_1), 
          variable_1.getName());
        _builder_5.append(_serialize_1);
        _builder_5.append(" get");
        String _firstUpper_3 = StringExtensions.toFirstUpper(variable_1.getName());
        _builder_5.append(_firstUpper_3);
        _builder_5.append("(");
        _builder_5.append(this.name);
        _builder_5.append("* statechart);");
        _builder_5.newLineIfNotEmpty();
      }
    }
    this.header.addContent(_builder_5.toString());
    StringConcatenation _builder_6 = new StringConcatenation();
    _builder_6.append("#endif /* ");
    String _upperCase = this.name.toUpperCase();
    _builder_6.append(_upperCase);
    _builder_6.append("_HEADER */");
    _builder_6.newLineIfNotEmpty();
    this.header.addContent(_builder_6.toString());
  }

  /**
   * Constructs the statechart wrapper's C code.
   */
  @Override
  public void constructCode() {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("/* Initialize component ");
    _builder.append(this.name);
    _builder.append(" */");
    _builder.newLineIfNotEmpty();
    _builder.append("void initialize");
    _builder.append(this.name);
    _builder.append("(");
    _builder.append(this.name);
    _builder.append("* statechart) {");
    _builder.newLineIfNotEmpty();
    _builder.append("\t");
    String _initialization = Platforms.get(this.platform).getInitialization();
    _builder.append(_initialization, "\t");
    _builder.newLineIfNotEmpty();
    _builder.append("\t");
    _builder.append("reset");
    _builder.append(this.stName, "\t");
    _builder.append("(&statechart->");
    String _lowerCase = this.stName.toLowerCase();
    _builder.append(_lowerCase, "\t");
    _builder.append(");");
    _builder.newLineIfNotEmpty();
    _builder.append("\t");
    _builder.append("initialize");
    _builder.append(this.stName, "\t");
    _builder.append("(&statechart->");
    String _lowerCase_1 = this.stName.toLowerCase();
    _builder.append(_lowerCase_1, "\t");
    _builder.append(");");
    _builder.newLineIfNotEmpty();
    _builder.append("\t");
    _builder.append("entryEvents");
    _builder.append(this.stName, "\t");
    _builder.append("(&statechart->");
    String _lowerCase_2 = this.stName.toLowerCase();
    _builder.append(_lowerCase_2, "\t");
    _builder.append(");");
    _builder.newLineIfNotEmpty();
    _builder.append("}");
    _builder.newLine();
    _builder.newLine();
    _builder.append("/* Calculate Timeout events */");
    _builder.newLine();
    _builder.append("void time");
    _builder.append(this.name);
    _builder.append("(");
    _builder.append(this.name);
    _builder.append("* statechart) {");
    _builder.newLineIfNotEmpty();
    _builder.append("\t");
    String _timer = Platforms.get(this.platform).getTimer();
    _builder.append(_timer, "\t");
    _builder.newLineIfNotEmpty();
    {
      EList<VariableDeclaration> _variables = this.variableGroupRetriever.getTimeoutGroup(this.xsts).getVariables();
      for(final VariableDeclaration variable : _variables) {
        _builder.append("\t");
        _builder.append("/* Add elapsed time to timeout variable ");
        String _name = variable.getName();
        _builder.append(_name, "\t");
        _builder.append(" */");
        _builder.newLineIfNotEmpty();
        _builder.append("\t");
        _builder.append("statechart->");
        String _lowerCase_3 = this.stName.toLowerCase();
        _builder.append(_lowerCase_3, "\t");
        _builder.append(".");
        String _name_1 = variable.getName();
        _builder.append(_name_1, "\t");
        _builder.append(" += ");
        _builder.append(IPlatform.CLOCK_VARIABLE_NAME, "\t");
        _builder.append(";");
        _builder.newLineIfNotEmpty();
      }
    }
    _builder.append("}");
    _builder.newLine();
    _builder.newLine();
    _builder.append("/* Run cycle of component ");
    _builder.append(this.name);
    _builder.append(" */");
    _builder.newLineIfNotEmpty();
    _builder.append("void runCycle");
    _builder.append(this.name);
    _builder.append("(");
    _builder.append(this.name);
    _builder.append("* statechart) {");
    _builder.newLineIfNotEmpty();
    _builder.append("\t");
    _builder.append("time");
    _builder.append(this.name, "\t");
    _builder.append("(statechart);");
    _builder.newLineIfNotEmpty();
    _builder.append("\t");
    _builder.append("runCycle");
    _builder.append(this.stName, "\t");
    _builder.append("(&statechart->");
    String _lowerCase_4 = this.stName.toLowerCase();
    _builder.append(_lowerCase_4, "\t");
    _builder.append(");");
    _builder.newLineIfNotEmpty();
    _builder.append("}");
    _builder.newLine();
    this.code.addContent(_builder.toString());
    StringConcatenation _builder_1 = new StringConcatenation();
    {
      boolean _hasElements = false;
      for(final VariableDeclaration variable_1 : this.inputs) {
        if (!_hasElements) {
          _hasElements = true;
        } else {
          String _lineSeparator = System.lineSeparator();
          _builder_1.appendImmediate(_lineSeparator, "");
        }
        _builder_1.append("/* Setter for ");
        String _firstUpper = StringExtensions.toFirstUpper(variable_1.getName());
        _builder_1.append(_firstUpper);
        _builder_1.append(" */");
        _builder_1.newLineIfNotEmpty();
        _builder_1.append("void set");
        String _firstUpper_1 = StringExtensions.toFirstUpper(variable_1.getName());
        _builder_1.append(_firstUpper_1);
        _builder_1.append("(");
        _builder_1.append(this.name);
        _builder_1.append("* statechart, ");
        final Function1<VariableDeclarationAnnotation, Boolean> _function = (VariableDeclarationAnnotation type) -> {
          return Boolean.valueOf((type instanceof ClockVariableDeclarationAnnotation));
        };
        String _serialize = this.variableDeclarationSerializer.serialize(
          variable_1.getType(), 
          IterableExtensions.<VariableDeclarationAnnotation>exists(variable_1.getAnnotations(), _function), 
          variable_1.getName());
        _builder_1.append(_serialize);
        _builder_1.append(" value) {");
        _builder_1.newLineIfNotEmpty();
        _builder_1.append("\t");
        _builder_1.append("statechart->");
        String _lowerCase_5 = this.stName.toLowerCase();
        _builder_1.append(_lowerCase_5, "\t");
        _builder_1.append(".");
        String _name_2 = variable_1.getName();
        _builder_1.append(_name_2, "\t");
        _builder_1.append(" = value;");
        _builder_1.newLineIfNotEmpty();
        _builder_1.append("}");
        _builder_1.newLine();
      }
    }
    this.code.addContent(_builder_1.toString());
    StringConcatenation _builder_2 = new StringConcatenation();
    {
      boolean _hasElements_1 = false;
      for(final VariableDeclaration variable_2 : this.outputs) {
        if (!_hasElements_1) {
          _hasElements_1 = true;
        } else {
          String _lineSeparator_1 = System.lineSeparator();
          _builder_2.appendImmediate(_lineSeparator_1, "");
        }
        _builder_2.append("/* Getter for ");
        String _firstUpper_2 = StringExtensions.toFirstUpper(variable_2.getName());
        _builder_2.append(_firstUpper_2);
        _builder_2.append(" */");
        _builder_2.newLineIfNotEmpty();
        final Function1<VariableDeclarationAnnotation, Boolean> _function_1 = (VariableDeclarationAnnotation type) -> {
          return Boolean.valueOf((type instanceof ClockVariableDeclarationAnnotation));
        };
        String _serialize_1 = this.variableDeclarationSerializer.serialize(
          variable_2.getType(), 
          IterableExtensions.<VariableDeclarationAnnotation>exists(variable_2.getAnnotations(), _function_1), 
          variable_2.getName());
        _builder_2.append(_serialize_1);
        _builder_2.append(" get");
        String _firstUpper_3 = StringExtensions.toFirstUpper(variable_2.getName());
        _builder_2.append(_firstUpper_3);
        _builder_2.append("(");
        _builder_2.append(this.name);
        _builder_2.append("* statechart) {");
        _builder_2.newLineIfNotEmpty();
        _builder_2.append("\t");
        _builder_2.append("return statechart->");
        String _lowerCase_6 = this.stName.toLowerCase();
        _builder_2.append(_lowerCase_6, "\t");
        _builder_2.append(".");
        String _name_3 = variable_2.getName();
        _builder_2.append(_name_3, "\t");
        _builder_2.append(";");
        _builder_2.newLineIfNotEmpty();
        _builder_2.append("}");
        _builder_2.newLine();
      }
    }
    this.code.addContent(_builder_2.toString());
  }

  /**
   * Saves the generated wrapper code and header models to the specified URI.
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
      local = local.appendSegment(this.xsts.getName().toLowerCase());
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
