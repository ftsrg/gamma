/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.plantuml.serialization

import java.io.ByteArrayOutputStream
import java.nio.charset.Charset
import net.sourceforge.plantuml.FileFormat
import net.sourceforge.plantuml.FileFormatOption
import net.sourceforge.plantuml.SourceStringReader

class SvgSerializer {
	// Singleton
	public static final SvgSerializer INSTANCE = new SvgSerializer
	//
	
	def serialize(String plantUmlString) {
		  try (val os = new ByteArrayOutputStream) {
			val reader = new SourceStringReader(plantUmlString)
			reader.outputImage(os, new FileFormatOption(FileFormat.SVG)).description
			val svg = new String(os.toByteArray, Charset.forName("UTF-8"))
			return svg
		  }
	 }

}