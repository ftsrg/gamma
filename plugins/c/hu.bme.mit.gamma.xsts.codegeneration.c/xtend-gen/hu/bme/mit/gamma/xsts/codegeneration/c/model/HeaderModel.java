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
package hu.bme.mit.gamma.xsts.codegeneration.c.model;

import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.Functions.Function0;

/**
 * Represents a C header file model.
 */
@SuppressWarnings("all")
public class HeaderModel extends FileModel {
  /**
   * Creates a new HeaderModel instance with the given name.
   * 
   * @param name the name of the header file
   */
  public HeaderModel(final String name) {
    super(new Function0<String>() {
      @Override
      public String apply() {
        StringConcatenation _builder = new StringConcatenation();
        String _lowerCase = name.toLowerCase();
        _builder.append(_lowerCase);
        _builder.append(".h");
        return _builder.toString();
      }
    }.apply());
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("#include <stdbool.h>");
    _builder.newLine();
    _builder.newLine();
    _builder.append("/* header guard */");
    _builder.newLine();
    _builder.append("#ifndef ");
    String _upperCase = name.toUpperCase();
    _builder.append(_upperCase);
    _builder.append("_HEADER");
    _builder.newLineIfNotEmpty();
    _builder.append("#define ");
    String _upperCase_1 = name.toUpperCase();
    _builder.append(_upperCase_1);
    _builder.append("_HEADER");
    _builder.newLineIfNotEmpty();
    this.content = _builder.toString();
  }
}
