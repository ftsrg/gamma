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
package hu.bme.mit.gamma.action.language.scoping;

import java.util.Collection;
import java.util.Collections;
import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.xtext.scoping.IScope;
import org.eclipse.xtext.scoping.Scopes;

import hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures;
import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.Block;
import hu.bme.mit.gamma.action.model.ForStatement;
import hu.bme.mit.gamma.action.util.ActionUtil;
import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.FieldReferenceExpression;
import hu.bme.mit.gamma.expression.model.RecordAccessExpression;
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;

public class ActionLanguageScopeProvider extends AbstractActionLanguageScopeProvider {

	public ActionLanguageScopeProvider() {
		super.util = ActionUtil.INSTANCE;
	}
	
	@Override
	public IScope getScope(final EObject context, final EReference reference) {
		// Records
		if (reference == ExpressionModelPackage.Literals.FIELD_REFERENCE_EXPRESSION__FIELD_DECLARATION) {
			RecordAccessExpression recordAccess = ecoreUtil.getSelfOrContainerOfType(context, RecordAccessExpression.class);
			if (recordAccess != null) {
				Expression operand = recordAccess.getOperand();
				Collection<FieldDeclaration> fieldDeclarations = getFieldDeclarations(operand);
				return Scopes.scopeFor(fieldDeclarations);
			}
		}
		// Local declarations
		if (context instanceof Action &&
				reference == ExpressionModelPackage.Literals.DIRECT_REFERENCE_EXPRESSION__DECLARATION) {
			IScope parentScope = getParentScope(context, reference);
			EObject container = context.eContainer();
			if (container instanceof Block) {
				Block block = (Block) container;
				Action action = (Action) context;
				List<VariableDeclaration> precedingLocalDeclaratations =
						ActionModelDerivedFeatures.getPrecedingVariableDeclarations(block, action);
				return Scopes.scopeFor(precedingLocalDeclaratations, parentScope);
			}
			// For statement
			if (container instanceof ForStatement) {
				ForStatement forStatement = (ForStatement) container;
				return Scopes.scopeFor(List.of(forStatement.getParameter()), parentScope);
			}
			return parentScope;
		}
		return super.getScope(context, reference);
	}
	
	protected List<FieldDeclaration> getFieldDeclarations(Expression operand) {
		if (operand instanceof DirectReferenceExpression) {
			DirectReferenceExpression reference = (DirectReferenceExpression) operand;
			Declaration declaration = reference.getDeclaration();
			return getFieldDeclarations(declaration);
		}
		if (operand instanceof FieldReferenceExpression) {
			FieldReferenceExpression reference = (FieldReferenceExpression) operand;
			FieldDeclaration declaration = reference.getFieldDeclaration();
			return Collections.singletonList(declaration);
		}
		if (operand instanceof RecordAccessExpression) {
			RecordAccessExpression reference = (RecordAccessExpression) operand;
			FieldReferenceExpression fieldReference = reference.getFieldReference();
			if (fieldReference != null) {
				Declaration declaration = fieldReference.getFieldDeclaration();
				return getFieldDeclarations(declaration);
			}
		}
		if (operand instanceof RecordLiteralExpression) {
			RecordLiteralExpression recordLiteralExpression = (RecordLiteralExpression) operand;
			return getFieldDeclarations(recordLiteralExpression.getTypeDeclaration());
		}
		if (operand instanceof ArrayAccessExpression) {
			ArrayAccessExpression reference = (ArrayAccessExpression) operand;
			Expression accessedExpression = reference.getOperand();
			return getFieldDeclarations(accessedExpression);
		}
		return Collections.emptyList();
	}
	
	protected List<FieldDeclaration> getFieldDeclarations(Declaration declaration) {
		Type type = declaration.getType();
		return getFieldDeclarations(type);
	}
	
	protected List<FieldDeclaration> getFieldDeclarations(Type type) {
		if (type != null) {
			TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(type);
			if (typeDefinition instanceof RecordTypeDefinition) {
				RecordTypeDefinition record = (RecordTypeDefinition) typeDefinition;
				return record.getFieldDeclarations();
			}
			if (typeDefinition instanceof ArrayTypeDefinition) {
				ArrayTypeDefinition array = (ArrayTypeDefinition) typeDefinition;
				return getFieldDeclarations(array.getElementType());
			}
		}
		return Collections.emptyList();
	}
	
}