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
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class PropertyConcretizer {

	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;

	public PropertyPackage execute(PropertyPackage propertyPackage) {
		ResourceSet resourceSet = propertyPackage.eResource().getResourceSet();
		ViatraQueryEngine engine = ViatraQueryEngine.on(
				new EMFScope(resourceSet));
		
		List<CommentableStateFormula> formulas = propertyPackage.getFormulas();
		List<CommentableStateFormula> concretizedFormulas = new ArrayList<CommentableStateFormula>();
		
		for (int i = 0; i < formulas.size(); i++) {
			CommentableStateFormula commentableStateFormula = formulas.get(i);
			List<Comment> comments = commentableStateFormula.getComments();
			Class<?> patternClass = getPatternClass(comments);
			System.out.println(patternClass.getName());
			Collection<IPatternMatch> matches = null;
			
			try {
				Method onMethod = patternClass.getMethod("on",
						new Class[] { ViatraQueryEngine.class });
				Object matcher = onMethod.invoke(null, engine);
				Class<? extends Object> matcherClass = matcher.getClass();
				Method getAllMatchesMethod = matcherClass.getMethod("getAllMatches", new Class[0]);
				Object collection = getAllMatchesMethod.invoke(matcher, new Object[0]);
				System.out.println(collection.toString());
				matches = (Collection<IPatternMatch>) collection; 
			} catch (Exception e) {
				e.printStackTrace();
			}
			
			for (IPatternMatch match : matches) {
				CommentableStateFormula concretizableFormula = ecoreUtil.clone(commentableStateFormula);
				
				Object object = match.get("state"); // TODO
				System.out.println(object);
			}
		}
		// TODO make concretizedFormulas unique
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

	protected Class<?> getPatternClass(Comment comment) {
		File projectFile = ecoreUtil.getProjectFile(comment.eResource());
		String binUri = projectFile.getAbsolutePath() + File.separator + "bin";
		File bin = new File(binUri);
		// MyClassLoader classLoader = new MyClassLoader(
		// BaseGeneratedEMFQuerySpecification.class.getClassLoader(),
		// StatechartModelPackage.class.getClassLoader());
		URLClassLoader loader;
		try {
			loader = URLClassLoader.newInstance(new URL[] { bin.toURL() },
					PropertyConcretizer.class.getClassLoader());
			// Class<State> class2 = State.class;
			// class2.getClassLoader().loadClass("hu.bme.mit.gamma.statechart.statechart.State");
			String fqnOfPattern = comment.getComment();
			String fqnClassName = fqnOfPattern + "$Matcher";
			Class<?> clazz = loader.loadClass(fqnClassName);
			return clazz;
			// hu/bme/mit/gamma/statechart/statechart/State
//			for (Class<?> class1 : clazz.getNestMembers()) {
//				String name = class1.getName();
//				System.out.println(name);
//			}
//			Method[] methods = clazz.getMethods();
//			for (Method method : methods) {
//				String name = method.getName();
//				System.out.println(name);
//			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return null;
	}

}
