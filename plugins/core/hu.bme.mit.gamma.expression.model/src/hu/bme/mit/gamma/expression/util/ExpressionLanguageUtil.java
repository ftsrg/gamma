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
package hu.bme.mit.gamma.expression.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.AccessExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.NamedElement;
import hu.bme.mit.gamma.expression.model.TypeDefinition;

public class ExpressionLanguageUtil {
	
	protected final static ExpressionUtil util = ExpressionUtil.INSTANCE;
	
	public static TypeDefinition findAccessExpressionTypeDefinition1(AccessExpression accessExpression) {
		Declaration instanceDeclaration = util.getDeclaration(accessExpression);
		return ExpressionModelDerivedFeatures.getTypeDefinition(instanceDeclaration);
	}
	
	public static Collection<? extends NamedElement> getRecursiveContainerContentsOfType(EObject ele, Class<? extends NamedElement> type){
		List<NamedElement> ret = new ArrayList<NamedElement>();
		ret.addAll(getContentsOfType(ele, type));
		if (ele.eContainer() != null) {
			ret.addAll(getRecursiveContainerContentsOfType(ele.eContainer(), type));
		}
		return ret;
	}
	
	public static Collection<? extends NamedElement> getContentsOfType(EObject ele, Class<? extends NamedElement> type){
		List<NamedElement> ret = new ArrayList<NamedElement>();
		for (EObject obj : ele.eContents()) {
			if (obj instanceof NamedElement) {
				NamedElement ne = (NamedElement) obj;
				if (type.isAssignableFrom(ne.getClass())) {
					ret.add(ne);
				}
			}
		}
		return ret;
	}
}
