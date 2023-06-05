/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.codegeneration.c.commandhandler;

import java.io.File;
import java.util.List;
import java.util.logging.Logger;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import hu.bme.mit.gamma.xsts.codegeneration.c.CodeBuilder;
import hu.bme.mit.gamma.xsts.codegeneration.c.IStatechartCode;
import hu.bme.mit.gamma.xsts.codegeneration.c.WrapperBuilder;
import hu.bme.mit.gamma.xsts.codegeneration.c.platforms.SupportedPlatforms;
import hu.bme.mit.gamma.xsts.model.XSTS;

public class CommandHandler extends AbstractHandler {
	
	private static final Logger LOGGER = Logger.getLogger("hu.bme.mit.gamma.xsts.codegeneration.c.commandhandler");
	
	public Resource loadResource(URI uri) {
	    return new ResourceSetImpl().getResource(uri, true);
	}
	
	public URI getPackageRoot(URI uri) {
	    /* keep stepping back until the until the folder "src" exists */
		while (!new File(uri.toFileString() + "/src").exists()) {
	        uri = uri.trimSegments(1);
	    }
	    /* now uri should point to the root of the package */
	    return uri;
	}

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		
		/* read parameter from ui event */
		IStructuredSelection selection = (IStructuredSelection) HandlerUtil.getCurrentSelection(event);
		Object element = selection.getFirstElement();
		
		/* in case of type mismatch throw exception */
		if (!(element instanceof IFile)) {
			LOGGER.severe("Invalid parameter: " + element);
			throw new IllegalArgumentException("Parameter type must be *.gsts");
		}
		
		/* retrieve xsts model */
		IFile file = (IFile) element;
		Resource res = loadResource(URI.createURI(file.getLocationURI().toString()));
		XSTS xsts = (XSTS) res.getContents().get(0);
		
		/* determine the path of the project's root */
		URI root = getPackageRoot(URI.createURI(file.getLocationURI().toString()));
		
		LOGGER.info("XSTS model " + xsts.getName() + " successfully read.");
		
		/* define the platform */
		final SupportedPlatforms platform = SupportedPlatforms.UNIX;
		
		/* define what to generate */
		List<IStatechartCode> generate = List.of(
			new CodeBuilder(xsts),
			new WrapperBuilder(xsts)
		);
		
		/* build c code */
		for (IStatechartCode builder : generate) {
			builder.setPlatform(platform);
			builder.constructHeader();
			builder.constructCode();
			builder.save(root);
		}
		
		LOGGER.info("C code from model " + xsts.getName() + " successfully created.");
		
		return null;
	}

}
