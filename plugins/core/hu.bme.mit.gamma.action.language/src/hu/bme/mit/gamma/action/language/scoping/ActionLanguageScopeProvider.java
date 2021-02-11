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

import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.xtext.scoping.IScope;
import org.eclipse.xtext.scoping.Scopes;

import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.Block;
import hu.bme.mit.gamma.action.util.ActionUtil;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
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
		
		if (context instanceof Action &&
				reference == ExpressionModelPackage.Literals.DIRECT_REFERENCE_EXPRESSION__DECLARATION) {
			EObject container = context.eContainer();
			IScope parentScope = getScope(container, reference);
			if (container instanceof Block) {
				Block block = (Block) container;
				Action action = (Action) context;
				List<VariableDeclaration> precedingLocalDeclaratations =
						actionUtil.getPrecedingVariableDeclarations(block, action);
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
	
}
