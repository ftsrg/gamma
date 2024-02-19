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

import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.xsts.codegeneration.c.IStatechartCode;
import hu.bme.mit.gamma.xsts.codegeneration.c.platforms.SupportedPlatforms;
import hu.bme.mit.gamma.xsts.model.XSTS;

public class CommandHandler extends AbstractHandler {
	
	private static final Logger LOGGER = Logger.getLogger("hu.bme.mit.gamma.xsts.codegeneration.c.commandhandler");
	private static final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;

	
	public Resource loadResource(URI uri) {
		return new ResourceSetImpl().getResource(uri, true);
	}
	
	public URI getPackageRoot(URI uri) {
		File projectFile = ecoreUtil.getProjectFile(uri);
		
		/* now uri should point to the root of the package */
		URI fileUri = URI.createFileURI(projectFile.toString());
		return fileUri;
	}

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		
		/* read parameter from UI event */
		IStructuredSelection selection = (IStructuredSelection) HandlerUtil.getCurrentSelection(event);
		Object element = selection.getFirstElement();
		
		/* in case of type mismatch throw exception */
		if (!(element instanceof IFile)) {
			LOGGER.severe("Invalid parameter: " + element);
			throw new IllegalArgumentException("Parameter type must be *.gsts");
		}
		
		/* retrieve xsts model */
		IFile file = (IFile) element;
		String locationUriString = file.getLocationURI().toString();
		URI locationUri = URI.createURI(locationUriString);
		
		Resource res = loadResource(locationUri);
		XSTS xSts = (XSTS) res.getContents().get(0);
		
		/* determine the path of the project's root */
		URI root = getPackageRoot(locationUri);
		
		LOGGER.info("XSTS model " + xSts.getName() + " successfully read");
		
		/* define the platform and function pointers*/
		final boolean pointers = true;
		final SupportedPlatforms platform = SupportedPlatforms.UNIX;
		
		// Load component too, if you want to use this
		List<IStatechartCode> generate = List.of(
//			new CodeBuilder(xSts),
//			new WrapperBuilder(xSts, pointers),
//			new HavocBuilder(xSts)
		);
		
		/* build c code */
		for (IStatechartCode builder : generate) {
			builder.setPlatform(platform);
			builder.constructHeader();
			builder.constructCode();
			builder.save(root);
		}
		
		LOGGER.info("C code from model " + xSts.getName() + " successfully generated");
		
		return null;
	}

}
