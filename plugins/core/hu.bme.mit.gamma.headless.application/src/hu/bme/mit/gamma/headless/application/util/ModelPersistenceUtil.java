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

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;

public class ModelPersistenceUtil {

	private static final Logger LOGGER = LogManager.getLogger(ModelPersistenceUtil.class);

	public static URI saveInOneResource(String resourceFilePrefix, String resourceFileExtension, List<EObject> objects) {
		URI uri = null;
		if (objects.isEmpty()) {
			return uri;
		}

		try {
			uri = createTempFileUri(resourceFilePrefix, resourceFileExtension);
			ResourceSet resourceSet = new ResourceSetImpl();
			Resource resource = resourceSet.createResource(uri);
			objects.forEach(resource.getContents()::add);
			resource.save(Collections.EMPTY_MAP);
		} catch (IOException ex) {
			LOGGER.error(ex.getMessage(), ex);
		}
		return uri;
	}
	
	public static URI saveInOneResource(String resourceFilePrefix, List<EObject> objects) {
		return saveInOneResource(resourceFilePrefix, "xml", objects);
	}

	public static String serializeIntoOneResource(List<EObject> objects) {
		try {
			if (!objects.isEmpty()) {
				ResourceSet resourceSet = new ResourceSetImpl();
				Resource resource = resourceSet.createResource(URI.createURI("gamma"));
				objects.forEach(resource.getContents()::add);
				try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
					resource.save(outputStream, Collections.EMPTY_MAP);
					return outputStream.toString();
				}
			}
		} catch (IOException ex) {
			LOGGER.error(ex.getMessage(), ex);
		}
		return null;
	}

	public static Resource loadResourceWithSerializedUri(String from, ResourceSet resourceSet) throws IOException {
		String[] parts = from.split("\n");
		String uriName = parts[0];

		String[] rest = new String[parts.length - 1];
		System.arraycopy(parts, 1, rest, 0, parts.length - 1);
		from = Arrays.asList(rest).stream().collect(Collectors.joining("\n"));

		URI uri = URI.createURI(uriName);
		Resource resource = resourceSet.createResource(uri);

		try (ByteArrayInputStream bis = new ByteArrayInputStream(from.getBytes())) {
			resource.load(bis, Collections.EMPTY_MAP);
		}

		return resource;
	}
	
	private static URI createTempFileUri(String prefix, String extension) throws IOException {
		String absolutePath = FileUtil.createTempFile(prefix, extension, true).getAbsolutePath();
		return URI.createFileURI(absolutePath);
	}

}
