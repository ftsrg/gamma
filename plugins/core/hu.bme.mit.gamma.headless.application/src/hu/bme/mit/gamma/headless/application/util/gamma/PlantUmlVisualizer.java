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
package hu.bme.mit.gamma.headless.application.util.gamma;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.Charset;

import hu.bme.mit.gamma.plantuml.transformation.TraceToPlantUMLTransformer;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import net.sourceforge.plantuml.FileFormat;
import net.sourceforge.plantuml.FileFormatOption;
import net.sourceforge.plantuml.SourceStringReader;

public class PlantUmlVisualizer {

	public static String toSvg(ExecutionTrace trace) throws IOException {
		try (ByteArrayOutputStream os = new ByteArrayOutputStream()) {
			TraceToPlantUMLTransformer transformer = new TraceToPlantUMLTransformer(trace);
			String plantuml = transformer.execute();

			SourceStringReader reader = new SourceStringReader(plantuml);
			reader.outputImage(os, new FileFormatOption(FileFormat.SVG)).getDescription();
			return new String(os.toByteArray(), Charset.forName("UTF-8"));
		}
	}

}
