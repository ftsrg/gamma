/********************************************************************************
 * Copyright (c) 2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.util

import java.io.File
import java.net.URLClassLoader
import java.util.Collection
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.viatra.query.runtime.api.IPatternMatch
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

class ReflectiveViatraMatcher {
	// Singleton
	public static final ReflectiveViatraMatcher INSTANCE = new ReflectiveViatraMatcher
	protected new() {}
	//
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	//
	
	def queryAndMapMatches(EObject object,
			ClassLoader classLoader, String fqnOfPattern, String binUri) {
		val elements = newLinkedHashSet
		
		val matches = object.queryMatches(classLoader, fqnOfPattern, binUri)
		for (match : matches) {
			val parameters = match.parameterNames
			for (parameter : parameters) {
				val element = match.get(parameter)
				elements += element
			}
		}
		
		return elements
	}
	
	def queryMatches(EObject object,
			ClassLoader classLoader, String fqnOfPattern, String binUri) {
		val root = object.root
		val resource = root.eResource
		return resource.queryMatches(classLoader, fqnOfPattern, binUri)
	}
	
	def queryMatches(Resource resource,
			ClassLoader classLoader, String fqnOfPattern, String binUri) {
		val engine = ViatraQueryEngine.on(
			new EMFScope(resource))
		return engine.queryMatches(classLoader, fqnOfPattern, binUri)
	}
	
	def queryMatches(ViatraQueryEngine engine,
			ClassLoader classLoader, String fqnOfPattern, String binUri) {
		val loadPatternMatcherClass = classLoader.loadPatternMatcherClass(fqnOfPattern, binUri)
		val queryMatches = engine.queryMatches(loadPatternMatcherClass)
		
		return queryMatches
	}
	
	//

	def Class<?> loadPatternMatcherClass(ClassLoader classLoader,
			String fqnOfPattern, String binUri) {
		val bin = new File(binUri)
		var URLClassLoader loader = null
		
		try {
			loader = URLClassLoader.newInstance(#[ bin.toURL() ], classLoader)
			
			val fqnClassName = fqnOfPattern + "$Matcher" // $ is for subclasses
			val clazz = loader.loadClass(fqnClassName)
			return clazz
		} catch (Exception e) {
			e.printStackTrace
		}
		
		return null
	}

	@SuppressWarnings("unchecked")
	def queryMatches(ViatraQueryEngine engine, Class<?> patternMatcherClass) {
		var Collection<IPatternMatch> matches = null
		
		try {
			val onMethod = patternMatcherClass.getMethod("on", #[ ViatraQueryEngine ])
			val matcher = onMethod.invoke(null, engine)
			val matcherClass = matcher.class
			val getAllMatchesMethod = matcherClass.getMethod("getAllMatches", #[])
			val collection = getAllMatchesMethod.invoke(matcher, #[])

			matches = collection as Collection<IPatternMatch>
		} catch (Exception e) {
			e.printStackTrace
		}
		
		return matches
	}
}