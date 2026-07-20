/********************************************************************************
 * Copyright (c) 2018-2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.expression.language.scoping;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.xtext.scoping.IScope;
import org.eclipse.xtext.scoping.Scopes;
import org.eclipse.xtext.scoping.impl.SimpleScope;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.ExpressionPackage;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.NamedElement;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.ParametricElement;
import hu.bme.mit.gamma.expression.model.RecordAccessExpression;
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.util.ExpressionTypeDeterminator2;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ExpressionLanguageScopeProvider extends AbstractExpressionLanguageScopeProvider {

	protected final ExpressionTypeDeterminator2 typeDeterminator = ExpressionTypeDeterminator2.INSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected ExpressionUtil util = ExpressionUtil.INSTANCE; // Redefinable
	
	@Override
	public IScope getScope(final EObject context, final EReference reference) {
		if (reference == ExpressionModelPackage.Literals.RECORD_LITERAL_EXPRESSION__TYPE_DECLARATION) {
			Collection<TypeDeclaration> typeDeclarations = util.getTypeDeclarations(context);
			return Scopes.scopeFor(typeDeclarations);
		}
		if (reference == ExpressionModelPackage.Literals.FIELD_REFERENCE_EXPRESSION__FIELD_DECLARATION) {
			TypeDeclaration typeDeclaration = null; 
			RecordLiteralExpression literal = ecoreUtil.getSelfOrContainerOfType(context, RecordLiteralExpression.class);
			if (literal == null) {
				RecordAccessExpression access = ecoreUtil.getSelfOrContainerOfType(context, RecordAccessExpression.class);
				Expression recordTypeExpression = access.getOperand();
				try {
					TypeDefinition typeDefinition = typeDeterminator.getTypeDefinition(recordTypeExpression);
					if (typeDefinition instanceof RecordTypeDefinition recordType) {
						return Scopes.scopeFor(recordType.getFieldDeclarations());
					}
				} catch (RuntimeException e) {} // Not fully constructed element
				
				return super.getScope(context, reference);
			}
			else {
				typeDeclaration = literal.getTypeDeclaration(); 
			}
			RecordTypeDefinition recordType = (RecordTypeDefinition)
					ExpressionModelDerivedFeatures.getTypeDefinition(typeDeclaration);
			List<FieldDeclaration> fieldDeclarations = recordType.getFieldDeclarations();
			return Scopes.scopeFor(fieldDeclarations);
		}
		if (context instanceof ExpressionPackage expressionPackage &&
				reference == ExpressionModelPackage.Literals.ABSTRACT_DIRECT_REFERENCE_EXPRESSION__DECLARATION) {
			Collection<Declaration> declarations = new ArrayList<Declaration>();
			declarations.addAll(
					expressionPackage.getConstantDeclarations());
			declarations.addAll(
					expressionPackage.getFunctionDeclarations());
			// Parameter declarations could be added too, but what for?
			return Scopes.scopeFor(declarations);
		} // Order is important, as ExpressionPackage is a ParametricElement
		if (context instanceof ParametricElement parametricElement &&
				reference == ExpressionModelPackage.Literals.ABSTRACT_DIRECT_REFERENCE_EXPRESSION__DECLARATION) {
			IScope parentScope = getParentScope(context, reference);
			List<ParameterDeclaration> parameterDeclarations = parametricElement.getParameterDeclarations();
			return Scopes.scopeFor(parameterDeclarations, parentScope);
		}
		if (reference == ExpressionModelPackage.Literals.ABSTRACT_DIRECT_REFERENCE_EXPRESSION__DECLARATION) {
			// Right now, this might not be necessary as parametric elements are contained directly by packages
			IScope parentScope_ = getParentScope(context, reference);
			return parentScope_;
		}
		if (reference == ExpressionModelPackage.Literals.TYPE_REFERENCE__REFERENCE) {
			// Util override is crucial because of this
			Collection<TypeDeclaration> typeDeclarations = util.getTypeDeclarations(context);
			return Scopes.scopeFor(typeDeclarations);
		}
		if (reference == ExpressionModelPackage.Literals.ENUMERATION_LITERAL_EXPRESSION__REFERENCE) {
			// The above branch must work well for this
			EnumerationLiteralExpression literal = ecoreUtil.getSelfOrContainerOfType(context, EnumerationLiteralExpression.class);
			if (literal != null) {
				TypeReference typeReference = literal.getTypeReference();
				try {
					EnumerationTypeDefinition enumeration = (EnumerationTypeDefinition)
							ExpressionModelDerivedFeatures.getTypeDefinition(typeReference);
					List<EnumerationLiteralDefinition> literals = enumeration.getLiterals();
					return Scopes.scopeFor(literals);
				} catch (IllegalArgumentException e) {
					// LazyLinkingResource bug: 'type == null'
				}
			}
		}
		
		return super.getScope(context, reference);
	}
	
	protected IScope getParentScope(EObject context, EReference reference) {
		if (context == null) {
			return IScope.NULLSCOPE;
		}
		EObject container = context.eContainer();
		if (container == null) {
			return IScope.NULLSCOPE;
		}
		return getScope(container, reference);
	}
	
	protected IScope embedScopes(Collection<IScope> scopes) {
		if (scopes.isEmpty()) {
			return IScope.NULLSCOPE; 
		}
		IScope parentScope = IScope.NULLSCOPE;
		for (IScope scope : scopes) {
			parentScope = new SimpleScope(parentScope, scope.getAllElements());
		}
		return parentScope;
	}
	
	//
	
	protected EObject checkParent(NamedElement parent) {
		EObject setParent = getSelfOrFirstSubelementWithNamedElements(parent);
		if (setParent == null) {
			return parent;
		}
		return setParent;
	}
	
	protected EObject getSelfOrFirstSubelementWithNamedElements(EObject context) {
		List<EObject> contents = context.eContents();
		if (contents.stream().anyMatch(it ->  it instanceof NamedElement)) {
			return context;
		}
		
		List<EObject> subelements = new ArrayList<EObject>(contents);
		subelements.addAll(
				context.eCrossReferences());
		for (EObject object : subelements) {
			EObject content = getSelfOrFirstSubelementWithNamedElements(object);
			if (content != null) {
				return content;
			}
		}
		
		return null;
	}
	
}