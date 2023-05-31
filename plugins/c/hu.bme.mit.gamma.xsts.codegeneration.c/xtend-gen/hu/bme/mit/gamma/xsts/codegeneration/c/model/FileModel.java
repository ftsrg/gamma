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

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Paths;
import org.eclipse.emf.common.util.URI;
import org.eclipse.xtend2.lib.StringConcatenation;
import org.eclipse.xtext.xbase.lib.Exceptions;
import org.eclipse.xtext.xbase.lib.Functions.Function0;

/**
 * Represents a file in the generated C code.
 */
@SuppressWarnings("all")
public abstract class FileModel {
  /**
   * The name of the file.
   */
  protected String name;

  /**
   * The content of the file.
   */
  protected String content;

  /**
   * New line
   */
  public static final String NEW_LINE = new Function0<String>() {
    @Override
    public String apply() {
      StringConcatenation _builder = new StringConcatenation();
      _builder.newLine();
      return _builder.toString();
    }
  }.apply();

  /**
   * Constructs a new {@code FileModel} instance with the given name.
   * 
   * @param name the name of the file
   */
  public FileModel(final String name) {
    this.name = name;
  }

  /**
   * Saves the file to the given URI.
   * 
   * @param uri the URI where the file should be saved
   */
  public void save(final URI uri) {
    try {
      final URI local = uri.appendSegment(this.name);
      String _fileString = local.toFileString();
      boolean _exists = new File(_fileString).exists();
      if (_exists) {
        Files.delete(Paths.get(local.toFileString()));
      }
      Files.createFile(Paths.get(local.toFileString()));
      Files.write(Paths.get(local.toFileString()), this.content.getBytes());
    } catch (Throwable _e) {
      throw Exceptions.sneakyThrow(_e);
    }
  }

  /**
   * Adds content to the file.
   * 
   * @param content the content to be added to the file
   */
  public void addContent(final String content) {
    String _content = this.content;
    this.content = (_content + (FileModel.NEW_LINE + content));
  }

  /**
   * Returns the content of the file.
   * 
   * @return the content of the file
   */
  @Override
  public String toString() {
    return this.content;
  }
}
