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

import hu.bme.mit.gamma.expression.model.AccessExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.NamedElement;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;

public class ExpressionLanguageUtil {
	
	public static TypeDefinition findAccessExpressionTypeDefinition(AccessExpression accessExpression) {
		Declaration instanceDeclaration = findAccessExpressionInstanceDeclaration(accessExpression);
		Type instanceDeclarationType = instanceDeclaration.getType();
		return findTypeDefinitionOfType(instanceDeclarationType);
	}
	
	public static TypeDefinition findTypeDefinitionOfType(Type t) {
		if (t instanceof TypeDefinition) {
			return (TypeDefinition) t;
		} else {	// t instanceof TypeReference
			TypeReference tr = (TypeReference) t;
			TypeDeclaration td = tr.getReference();
			return findTypeDefinitionOfType(td.getType());
		}
	}
	
	public static Declaration findAccessExpressionInstanceDeclaration(AccessExpression accessExpression)/* throws Exception*/ {
		if (accessExpression.getOperand() instanceof DirectReferenceExpression) {
			DirectReferenceExpression ref = (DirectReferenceExpression)accessExpression.getOperand();
			return ref.getDeclaration();
		} else if (accessExpression.getOperand() instanceof AccessExpression) {
			return findAccessExpressionInstanceDeclaration((AccessExpression)accessExpression.getOperand());
		} else {
			return null;
		}
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
