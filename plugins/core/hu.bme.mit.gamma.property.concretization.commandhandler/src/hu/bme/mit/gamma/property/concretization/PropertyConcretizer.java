/********************************************************************************
 * Copyright (c) 2023-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.property.concretization;

import java.io.File;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.viatra.query.runtime.api.IPatternMatch;
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine;
import org.eclipse.viatra.query.runtime.emf.EMFScope;

import hu.bme.mit.gamma.expression.model.Comment;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReflectiveElementReferenceExpression;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.ReflectiveViatraMatcher;

public class PropertyConcretizer {
	// Singleton
	public static final PropertyConcretizer INSTANCE = new PropertyConcretizer();
	protected PropertyConcretizer() {}
	//
	protected final ReflectiveViatraMatcher matcher = ReflectiveViatraMatcher.INSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	//
	
	public PropertyPackage execute(PropertyPackage propertyPackage) {
		ResourceSet resourceSet = propertyPackage.eResource().getResourceSet();
		ViatraQueryEngine engine = ViatraQueryEngine.on(
				new EMFScope(resourceSet));
		
		List<CommentableStateFormula> formulas = propertyPackage.getFormulas();
		List<CommentableStateFormula> concretizedFormulas = new ArrayList<CommentableStateFormula>();
		
		for (int i = 0; i < formulas.size(); i++) {
			CommentableStateFormula commentableStateFormula = formulas.get(i);
			
			if (ecoreUtil.containsTypeTransitively(commentableStateFormula,
					ComponentInstanceReflectiveElementReferenceExpression.class)) {
				List<Comment> comments = commentableStateFormula.getComments();
				
				Class<?> patternMatcherClass = getPatternMatcherClass(comments);
				Collection<IPatternMatch> matches = matcher.queryMatches(engine, patternMatcherClass);
				
				FormulaConcretizer formulaConcretizer = FormulaConcretizer.INSTANCE;
				List<CommentableStateFormula> concretizedFormulaSet =
						formulaConcretizer.concretize(commentableStateFormula, matches);
				concretizedFormulas.addAll(concretizedFormulaSet);
			}
			else {
				concretizedFormulas.add(
						ecoreUtil.clone(commentableStateFormula));
			}
		}
		
		PropertyPackage concretizedPropertyPackage = ecoreUtil.clone(propertyPackage);
		List<CommentableStateFormula> concretizableFormulas = concretizedPropertyPackage.getFormulas();
		concretizableFormulas.clear();
		concretizableFormulas.addAll(concretizedFormulas);
		
		return concretizedPropertyPackage;
	}

	protected Class<?> getPatternMatcherClass(Collection<? extends Comment> comments) {
		for (Comment comment : comments) {
			Class<?> patternClass = getPatternMatcherClass(comment);
			if (patternClass != null) {
				return patternClass;
			}
		}
		throw new IllegalArgumentException("The pattern class cannot be found");
	}


	protected Class<?> getPatternMatcherClass(Comment comment) {
		final String CLASS_REFERENCE_PREFIX = "$";
		String stringComment = comment.getComment();
		
		if (stringComment.startsWith(CLASS_REFERENCE_PREFIX)) {
			String fqnOfPattern = stringComment.substring(1);
			File projectFile = ecoreUtil.getProjectFile(comment.eResource());
			String binUri = projectFile.getAbsolutePath() + File.separator + "bin";
			return matcher.loadPatternMatcherClass(this.getClass().getClassLoader(),
					fqnOfPattern, binUri);
		}
		
		return null;
	}
	
}