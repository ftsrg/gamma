/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.scoping.ui;

import java.util.Collections;

import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.ui.IEditorPart;
import org.eclipse.xtext.ui.editor.LanguageSpecificURIEditorOpener;


import hu.bme.mit.gamma.statechart.model.presentation.StatechartModelEditor;

public class GammaEditorOpener extends LanguageSpecificURIEditorOpener {
 
    @Override
    protected void selectAndReveal(IEditorPart openEditor, URI uri,
    		EReference crossReference, int indexInList, boolean select) {
        StatechartModelEditor statechartModelEditor = (StatechartModelEditor) openEditor.getAdapter(StatechartModelEditor.class);
        if (statechartModelEditor != null) {
            EObject eObject = statechartModelEditor.getEditingDomain().getResourceSet().getEObject(uri, true);
            statechartModelEditor.setSelectionToViewer(Collections.singletonList(eObject));
        }
    }
}
 
