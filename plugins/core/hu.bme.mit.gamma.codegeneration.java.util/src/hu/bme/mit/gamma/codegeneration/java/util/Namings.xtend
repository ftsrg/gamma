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
package hu.bme.mit.gamma.codegeneration.java.util

import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Interface
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import java.io.File
import org.eclipse.emf.ecore.EObject

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class Namings {
	
	public static final String GAMMA_EVENT_CLASS = "Event"
	
	public static final String YAKINDU_TIMER_INTERFACE = "ITimer"
	public static final String GAMMA_TIMER_INTERFACE = "TimerInterface"
	public static final String UNIFIED_TIMER_INTERFACE = "UnifiedTimerInterface"
	
	public static final String TIMER_CALLBACK_INTERFACE = "ITimerCallback"
	
	public static final String YAKINDU_TIMER_CLASS = "TimerService"
	public static final String GAMMA_TIMER_CLASS = "OneThreadedTimer"
	public static final String UNIFIED_TIMER_CLASS = "UnifiedTimer"
	
	public static final String REFLECTIVE_WRAPPED_COMPONENT = "wrappedComponent"
	public static final String REFLECTIVE_INTERFACE = "ReflectiveComponentInterface"
	
	public static final String CHANNEL_PACKAGE_POSTFIX = "channels"
	
	static def String getPackageString(Package _package, String base) '''«base».«_package.name.toLowerCase»'''
	
	static def String getPackageString(Component component, String base) '''«component.containingPackage.getPackageString(base)»'''
	static def String getPackageString(EObject object, String base) '''«object.containingPackage.getPackageString(base)»'''
	
	static def String generateUri(String targetFolderUri, String packageName) '''«targetFolderUri + File.separator + packageName.replaceAll("\\.", "/")»'''
	
	/**
	 * Returns the name of the Java interface generated from the given Gamma interface, e.g., PortInterface. 
	 */
 	static def String getImplementationName(Interface _interface) '''«_interface.name.toFirstUpper»Interface'''
	
	/**
	 * Returns the name of the Java interface the given port realizes, e.g., Controller.Required.
	 */
	static def String getImplementedInterfaceName(Port port) '''«port.interfaceRealization.interface.implementationName».«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»'''
	
	/**
	 * Returns the name of the Java class of the component.
	 */
	static def String getComponentClassName(Component component) '''«component.name.toFirstUpper»'''
	
	/**
	 * Returns the name of the Java class of the reflective component.
	 */
	static def String getReflectiveClassName(Component component) '''Reflective«component.componentClassName»'''
	
	/**
	 * Returns the name of the Java class of the wrapped statemachine component.
	 */
	static def String getWrappedStatemachineClassName(Component component) '''«component.componentClassName»Statemachine'''
	
	/**
	 * Returns the name of the Java object of the wrapped synchronous component.
	 */
	static def String getWrappedComponentName(AsynchronousAdapter component) '''«component.wrappedComponent.name»'''

}
