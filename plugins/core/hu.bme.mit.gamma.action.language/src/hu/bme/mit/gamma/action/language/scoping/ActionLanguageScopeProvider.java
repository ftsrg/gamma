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
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
public class ActionLanguageScopeProvider extends AbstractActionLanguageScopeProvider {

	protected final ActionUtil actionUtil = ActionUtil.INSTANCE;
	
	@Override
	public IScope getScope(final EObject context, final EReference reference) {
		// Records
//		RecordAccessExpression recordAccess = ecoreUtil.getSelfOrContainerOfType(context, RecordAccessExpression.class);
//		if (recordAccess != null) {
//			Expression operand = recordAccess.getOperand();
//			if (operand == null) {
//				EObject container = context.eContainer();
//				// NOT '.super'
//				return getScope(container, reference); // Still looking for a record variable
//			}
//			// Looking for the fields in the operand
//			Collection<FieldDeclaration> fieldDeclarations = getFieldDeclarations(operand);
//			return Scopes.scopeFor(fieldDeclarations);
//		}
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
			EObject container = context.eContainer();
			IScope parentScope = getScope(container, reference);
			if (container instanceof Block) {
				Block block = (Block) container;
				Action action = (Action) context;
				List<VariableDeclaration> precedingLocalDeclaratations =
						ActionModelDerivedFeatures.getPrecedingVariableDeclarations(block, action);
				return Scopes.scopeFor(precedingLocalDeclaratations, parentScope);
			}
//			else if (context instanceof Block) {
//				// In Xtext, when editing, the assignment statement is NOT the context, but the block
//				Block block = (Block) context;
//				List<VariableDeclaration> localDeclaratations =
//						actionUtil.getVariableDeclarations(block);
//				return Scopes.scopeFor(localDeclaratations, parentScope);
//			}
			return parentScope;
		}
//		else if (reference == 
//				ExpressionModelPackage.Literals.DIRECT_REFERENCE_EXPRESSION__DECLARATION) {
//			// The context is NOT an Action
//			Action actionContainer = ecoreUtil.getSelfOrContainerOfType(context, Action.class);
//			if (actionContainer instanceof Block) {
//				// First action container is a block, not an assignment
//				// This means that the Xtext code is being edited
//				// Let us return every local variable in the block and the parent scopes too
//				Block block = (Block) actionContainer;
//				IScope parentScope = getScope(block, reference);
//				List<VariableDeclaration> localDeclaratations =
//						actionUtil.getVariableDeclarations(block);
//				return Scopes.scopeFor(localDeclaratations, parentScope);
//			}
//		}
		return super.getScope(context, reference);
	}
	
	protected List<FieldDeclaration> getFieldDeclarations(Expression operand) {
		// TODO extend with recordLiterals too, e.g., ExpressionTypeDeterminator.getType(operand) method is needed
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