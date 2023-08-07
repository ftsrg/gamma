/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.gui.perspectives;

import org.eclipse.ui.IFolderLayout;
import org.eclipse.ui.IPageLayout;
import org.eclipse.ui.IPerspectiveFactory;
import org.eclipse.ui.console.IConsoleConstants;

public class GammaPerspectiveFactory implements IPerspectiveFactory {
	
	private static final String PLANTUML_ID = "net.sourceforge.plantuml.eclipse.views.PlantUmlView";
	private static final String PLANTUML_SVG_ID = "net.sourceforge.plantuml.eclipse.views.PlantUmlSvgView";

	@Override
	public void createInitialLayout(IPageLayout layout) {
		String editorArea = layout.getEditorArea();
		IFolderLayout left = layout.createFolder("left", IPageLayout.LEFT, 0.16f, editorArea);
		left.addView(IPageLayout.ID_PROJECT_EXPLORER);
		// Included to get rid of a warning issued by the workbench
		left.addPlaceholder("org.eclipse.jdt.ui.PackageExplorer");

		IFolderLayout right = layout.createFolder("right", IPageLayout.RIGHT, 0.84f, editorArea);
		right.addView(IPageLayout.ID_OUTLINE);
		right.addView(PLANTUML_ID);
		right.addView(PLANTUML_SVG_ID);

		IFolderLayout bottom = layout.createFolder("bottom", IPageLayout.BOTTOM, 0.65f, editorArea);
		bottom.addView(IConsoleConstants.ID_CONSOLE_VIEW);
		bottom.addView(IPageLayout.ID_PROP_SHEET);
		bottom.addView(IPageLayout.ID_PROBLEM_VIEW);
		bottom.addView(IPageLayout.ID_TASK_LIST);
		bottom.addView(IPageLayout.ID_PROGRESS_VIEW);
	}

}
