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
package hu.bme.mit.gamma.headless.application.util;

import java.io.File;
import java.io.IOException;

public abstract class FileUtil {

	public static File createThetaTempFile(String extension) throws IOException {
		return createTempFile("thetaverif", extension, true);
	}

	public static File createTempFile(String prefix, String extension, boolean isPersistent) throws IOException {
		File tempFile = File.createTempFile(prefix, String.format(".%s", extension));
		if (!isPersistent) {
			tempFile.deleteOnExit();
		}
		return tempFile;
	}

}
