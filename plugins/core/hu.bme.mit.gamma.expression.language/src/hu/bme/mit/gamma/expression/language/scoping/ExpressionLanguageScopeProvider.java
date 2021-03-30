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
package hu.bme.mit.gamma.expression.language.scoping;

import java.util.Collection;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.xtext.scoping.IScope;
import org.eclipse.xtext.scoping.Scopes;

import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
public class ExpressionLanguageScopeProvider extends AbstractExpressionLanguageScopeProvider {

	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected ExpressionUtil util = ExpressionUtil.INSTANCE; // Redefinable
	
	@Override
	public IScope getScope(final EObject context, final EReference reference) {
		if (reference == ExpressionModelPackage.Literals.RECORD_LITERAL_EXPRESSION__TYPE_DECLARATION) {
			Collection<TypeDeclaration> typeDeclarations = util.getTypeDeclarations(context);
			return Scopes.scopeFor(typeDeclarations);
		}
		if (reference == ExpressionModelPackage.Literals.FIELD_REFERENCE_EXPRESSION__FIELD_DECLARATION) {
			RecordLiteralExpression literal = ecoreUtil.getSelfOrContainerOfType(context, RecordLiteralExpression.class);
			TypeDeclaration typeDeclaration = literal.getTypeDeclaration();
			RecordTypeDefinition recordType = (RecordTypeDefinition) typeDeclaration.getType();
			return Scopes.scopeFor(recordType.getFieldDeclarations());
		}
		return super.getScope(context, reference);
	}
	
}