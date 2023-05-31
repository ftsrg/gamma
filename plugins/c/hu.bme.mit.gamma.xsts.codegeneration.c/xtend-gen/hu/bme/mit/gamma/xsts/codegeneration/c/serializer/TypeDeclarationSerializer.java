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

import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import java.util.Arrays;
import java.util.List;
import org.eclipse.emf.common.util.EList;
import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.Conversions;
import org.eclipse.xtext.xbase.lib.Functions.Function1;
import org.eclipse.xtext.xbase.lib.IterableExtensions;
import org.eclipse.xtext.xbase.lib.ListExtensions;
import org.eclipse.xtext.xbase.lib.StringExtensions;

/**
 * A serializer for type declarations.
 */
@SuppressWarnings("all")
public class TypeDeclarationSerializer {
  /**
   * Transforms a string with underscores to camel case by converting each word's first letter
   * after an underscore to uppercase.
   * 
   * @param input the string to transform
   * @return the transformed string in camel case
   */
  public String transformString(final String input) {
    final String[] parts = input.split("_");
    final Function1<String, String> _function = (String it) -> {
      return StringExtensions.toFirstUpper(it);
    };
    final List<String> transformedParts = ListExtensions.<String, String>map(((List<String>)Conversions.doWrapArray(parts)), _function);
    return IterableExtensions.join(transformedParts, "_");
  }

  /**
   * Serializes an enumeration type definition.
   * 
   * @param type The enumeration type definition.
   * @param name The name of the enumeration type.
   * @return The serialized string representation.
   */
  protected String _serialize(final EnumerationTypeDefinition type, final String name) {
    StringConcatenation _builder = new StringConcatenation();
    _builder.append("/* Enum representing region ");
    _builder.append(name);
    _builder.append(" */");
    _builder.newLineIfNotEmpty();
    _builder.append("enum ");
    String _transformString = this.transformString(name);
    _builder.append(_transformString);
    _builder.append(" {");
    _builder.newLineIfNotEmpty();
    _builder.append("\t");
    {
      EList<EnumerationLiteralDefinition> _literals = type.getLiterals();
      boolean _hasElements = false;
      for(final EnumerationLiteralDefinition literal : _literals) {
        if (!_hasElements) {
          _hasElements = true;
        } else {
          _builder.appendImmediate(",\n", "\t");
        }
        String _name = literal.getName();
        _builder.append(_name, "\t");
        _builder.append("_");
        String _lowerCase = name.toLowerCase();
        _builder.append(_lowerCase, "\t");
      }
    }
    _builder.newLineIfNotEmpty();
    _builder.append("} ");
    String _lowerCase_1 = name.toLowerCase();
    _builder.append(_lowerCase_1);
    _builder.append(";");
    _builder.newLineIfNotEmpty();
    return _builder.toString();
  }

  /**
   * Serializes a type declaration of an unsupported type.
   * 
   * @param type The unsupported type.
   * @param name The name of the type declaration.
   * @throws IllegalArgumentException Always thrown.
   */
  protected String _serialize(final Type type, final String name) {
    throw new IllegalArgumentException(("Not supported type: " + type));
  }

  /**
   * Serializes a type declaration.
   * 
   * @param type The type declaration.
   * @return The serialized string representation.
   */
  public String serialize(final TypeDeclaration type) {
    return this.serialize(type.getType(), type.getName());
  }

  public String serialize(final Type type, final String name) {
    if (type instanceof EnumerationTypeDefinition) {
      return _serialize((EnumerationTypeDefinition)type, name);
    } else if (type != null) {
      return _serialize(type, name);
    } else {
      throw new IllegalArgumentException("Unhandled parameter types: " +
        Arrays.<Object>asList(type, name).toString());
    }
  }
}
