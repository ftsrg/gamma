/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
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
import java.lang.reflect.Method;
import java.net.URL;
import java.net.URLClassLoader;
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

public class PropertyConcretizer {
	// Singleton
	public static final PropertyConcretizer INSTANCE = new PropertyConcretizer();
	protected PropertyConcretizer() {}
	//
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	//
	
	@SuppressWarnings("unchecked")
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
				Class<?> patternClass = getPatternClass(comments);
				
				Collection<IPatternMatch> matches = null;
				try {
					Method onMethod = patternClass.getMethod("on",
							new Class[] { ViatraQueryEngine.class });
					Object matcher = onMethod.invoke(null, engine);
					Class<? extends Object> matcherClass = matcher.getClass();
					Method getAllMatchesMethod = matcherClass.getMethod("getAllMatches", new Class[0]);
					Object collection = getAllMatchesMethod.invoke(matcher, new Object[0]);
	
					matches = (Collection<IPatternMatch>) collection; 
				} catch (Exception e) {
					e.printStackTrace();
				}
				
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

	protected Class<?> getPatternClass(Collection<? extends Comment> comments) {
		for (Comment comment : comments) {
			Class<?> patternClass = getPatternClass(comment);
			if (patternClass != null) {
				return patternClass;
			}
		}
		throw new IllegalArgumentException("The pattern class cannot be found");
	}

	@SuppressWarnings("deprecation")
	protected Class<?> getPatternClass(Comment comment) {
		File projectFile = ecoreUtil.getProjectFile(comment.eResource());
		String binUri = projectFile.getAbsolutePath() + File.separator + "bin";
		File bin = new File(binUri);
		URLClassLoader loader;
		try {
			loader = URLClassLoader.newInstance(new URL[] { bin.toURL() },
					PropertyConcretizer.class.getClassLoader());
			
			String fqnOfPattern = comment.getComment();
			String fqnClassName = fqnOfPattern + "$Matcher"; // $ is for subclasses
			Class<?> clazz = loader.loadClass(fqnClassName);
			return clazz;
		} catch (Exception e) {
			e.printStackTrace();
		}
		return null;
	}

}