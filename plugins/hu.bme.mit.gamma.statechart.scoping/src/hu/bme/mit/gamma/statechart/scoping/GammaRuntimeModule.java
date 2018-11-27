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
package hu.bme.mit.gamma.statechart.scoping; 

import org.eclipse.xtext.naming.IQualifiedNameProvider;
import org.eclipse.xtext.resource.IDefaultResourceDescriptionStrategy;
import org.eclipse.xtext.resource.generic.AbstractGenericResourceRuntimeModule;

public class GammaRuntimeModule extends AbstractGenericResourceRuntimeModule {
 
    @Override
    protected String getLanguageName() {
    	// Needed for opening EMF Editor from an Xtext file (Ctrl + Click)
    	return "hu.bme.mit.gamma.statechart.model.presentation.StatechartModelEditorID";
    }
 
    @Override
    protected String getFileExtensions() {
    	return "gsm";
    }
    
    public Class<? extends IDefaultResourceDescriptionStrategy> bindIDefaultResourceDescriptionStrategy() {
        return GammaResourceDescriptionStrategy.class;
    }
 
    @Override
    public Class<? extends IQualifiedNameProvider> bindIQualifiedNameProvider() {
        return GammaQualifiedNameProvider.class;
    }
 
}
