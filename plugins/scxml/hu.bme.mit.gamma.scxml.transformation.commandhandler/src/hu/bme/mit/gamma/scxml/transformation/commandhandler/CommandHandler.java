/********************************************************************************
 * Copyright (c) 2023-2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scxml.transformation.commandhandler;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IContainer;
import org.eclipse.core.resources.IFile;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import ac.soton.scxml.ScxmlScxmlType;
import hu.bme.mit.gamma.expression.model.ConstantDeclaration;
import hu.bme.mit.gamma.scxml.transformation.CompositeTraceability;
import hu.bme.mit.gamma.scxml.transformation.Namings;
import hu.bme.mit.gamma.scxml.transformation.ScxmlToGammaCompositeTransformer;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.language.ui.serializer.StatechartLanguageSerializer;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;
import hu.bme.mit.gamma.util.FileUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class CommandHandler extends AbstractHandler {

	protected final FileUtil fileUtil = FileUtil.INSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
	protected final Logger logger = Logger.getLogger("GammaLogger");

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		try {
			ISelection sel = HandlerUtil.getActiveMenuSelection(event);
			if (sel instanceof IStructuredSelection) {
				IStructuredSelection selection = (IStructuredSelection) sel;
				Object firstElement = selection.getFirstElement();
				if (selection.size() == 1) {
					if (firstElement != null && firstElement instanceof IFile) {
						IFile file = (IFile) firstElement;
						IContainer parentFolder = file.getParent();
						String fileName = file.getName();
						String extensionlessFileName = fileUtil.getExtensionlessName(fileName);
						String parentPath = parentFolder.getFullPath().toString();
						String path = file.getFullPath().toString();

						// Model processing
						ScxmlToGammaCompositeTransformer compositeTransformer = new ScxmlToGammaCompositeTransformer(path);
						CompositeTraceability compositeTraceability = compositeTransformer.execute();

						// Interfaces and type declarations have to be explicitly serialized in another package
						List<Interface> gammaInterfaces = new ArrayList<Interface>(
								compositeTraceability.getInterfaces());
						gammaInterfaces.removeIf(i -> i == null);
						ScxmlScxmlType scxmlRoot = compositeTraceability.getScxmlRoot();
						Package gammaInterfacePackage = statechartUtil.createPackage(
								Namings.getInterfacePackageName(scxmlRoot));
						gammaInterfacePackage.getInterfaces().addAll(gammaInterfaces);

						List<ConstantDeclaration> gammaConstants = new ArrayList<ConstantDeclaration>(
								compositeTraceability.getConstantDeclarations());
						gammaInterfacePackage.getConstantDeclarations().addAll(gammaConstants);

						// Pack and serialize asynchronous component
						Component rootComponent = compositeTraceability.getRootComponent();
						Package gammaCompositePackage = statechartUtil.wrapIntoPackage(rootComponent);
						Collection<Component> components = compositeTraceability.getComponents();
						gammaCompositePackage.getComponents().addAll(components);
						gammaCompositePackage.getImports()
								.addAll(StatechartModelDerivedFeatures.getImportablePackages(gammaCompositePackage));
						gammaCompositePackage.getImports().remove(gammaCompositePackage);

						StatechartLanguageSerializer packageSerializer = new StatechartLanguageSerializer();
						logger.log(Level.INFO, "Start serializing Gamma packages...");

						// String declarationsPackageFileName = extensionlessFileName + "Declarations.gsm";
						// ecoreUtil.normalSave(gammaInterfacePackage, parentPath,
						// declarationsPackageFileName);
						String declarationsPackageFileName = extensionlessFileName + "Declarations.gcd";
						packageSerializer.serialize(gammaInterfacePackage, parentPath, declarationsPackageFileName);

						// String compositePackageFileName = extensionlessFileName + ".gsm";
						// ecoreUtil.normalSave(gammaCompositePackage, parentPath,
						// compositePackageFileName);
						String compositePackageFileName = extensionlessFileName + ".gcd";
						packageSerializer.serialize(gammaCompositePackage, parentPath, compositePackageFileName);

						logger.log(Level.INFO, "The SCXML - Gamma statechart transformation has finished.");
					}
				}
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
		return null;
	}

}
