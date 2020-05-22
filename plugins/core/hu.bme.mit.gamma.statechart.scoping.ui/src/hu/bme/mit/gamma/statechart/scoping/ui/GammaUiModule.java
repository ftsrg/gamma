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

import org.eclipse.ui.plugin.AbstractUIPlugin;
import org.eclipse.xtext.ui.LanguageSpecific;
import org.eclipse.xtext.ui.editor.IURIEditorOpener;
import org.eclipse.xtext.ui.resource.generic.EmfUiModule;

import com.google.inject.Binder;

public class GammaUiModule extends EmfUiModule {
 
    public GammaUiModule(AbstractUIPlugin plugin) {
        super(plugin);
    }
 
    @Override
    public void configureLanguageSpecificURIEditorOpener(Binder binder) {
        binder.bind(IURIEditorOpener.class).annotatedWith(LanguageSpecific.class).to(GammaEditorOpener.class);
    }
 
}
