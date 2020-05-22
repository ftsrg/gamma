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
package hu.bme.mit.gamma.action.language.validation;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.action.model.ConstantDeclarationStatement;
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement;
import hu.bme.mit.gamma.expression.model.ConstantDeclaration;
import hu.bme.mit.gamma.expression.model.NamedElement;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;

public class ActionLanguageValidatorUtil {
	
		public static Collection<? extends NamedElement> getRecursiveContainerNamedElements(EObject ele){
			List<NamedElement> ret = new ArrayList<NamedElement>();
			ret.addAll(getNamedElements(ele));
			if(ele.eContainer() != null) {
				ret.addAll(getRecursiveContainerNamedElements(ele.eContainer()));
			}
			return ret;
		}
		
		public static Collection<? extends NamedElement> getNamedElements(EObject ele){
			List<NamedElement> ret = new ArrayList<NamedElement>();
			for(EObject obj : ele.eContents()) {
				if(obj instanceof NamedElement) {
					NamedElement ne = (NamedElement)obj;
					ret.add(ne);
				}else if(obj instanceof VariableDeclarationStatement) {
					VariableDeclaration vd = ((VariableDeclarationStatement)obj).getVariableDeclaration();
					ret.add(vd);
				}else if(obj instanceof ConstantDeclarationStatement) {
					ConstantDeclaration cd = ((ConstantDeclarationStatement)obj).getConstantDeclaration();
					ret.add(cd);
				}
			}
			return ret;
		}
}
