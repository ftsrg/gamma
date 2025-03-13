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
package hu.bme.mit.gamma.querygenerator

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.composite.MessageQueue
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.xsts.transformation.util.Namings

import static extension hu.bme.mit.gamma.xsts.iml.transformation.util.Namings.*

class ImlQueryGenerator extends ThetaQueryGenerator {
	//
	protected final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
	//
	new(Component component) {
		super(component)
	}
	
	// In the XSTS->IML mapping, ID of variable (field) declarations, type declarations and  enum literals are wrapped
	
	override protected getSingleTargetStateName(State state, Region parentRegion, SynchronousComponentInstance instance) {
		val superName = super.getSingleTargetStateName(state, parentRegion, instance)
		val split = superName.split(" == ")
		val variable = split.head
		
		return '''«variable.customizeDeclarationName» == «Namings.customizeRegionTypeName(parentRegion).customizeTypeDeclarationName».«Namings.customizeName(state).customizeEnumLiteralName»'''
	} 
	
	override protected getTargetVariableNames(VariableDeclaration variable, SynchronousComponentInstance instance) {
		return super.getTargetVariableNames(variable, instance).map[it.customizeDeclarationName]
	}
	
	override protected getTargetOutEventName(Event event, Port port, SynchronousComponentInstance instance) {
		return super.getTargetOutEventName(event, port, instance).customizeDeclarationName
	}
	
	override protected getTargetOutEventParameterNames(Event event, Port port, ParameterDeclaration parameter, SynchronousComponentInstance instance) {
		return super.getTargetOutEventParameterNames(event, port, parameter, instance).map[it.customizeDeclarationName]
	}
	
	override protected getTargetInEventName(Event event, Port port, SynchronousComponentInstance instance) {
		return super.getTargetInEventName(event, port, instance).customizeDeclarationName
	}
	
	override protected getTargetInEventParameterName(Event event, Port port, ParameterDeclaration parameter, SynchronousComponentInstance instance) {
		return super.getTargetInEventParameterName(event, port, parameter, instance).map[it.customizeDeclarationName]
	}
	
	override protected getTargetMasterQueueName(MessageQueue queue, AsynchronousComponentInstance instance) {
		return super.getTargetMasterQueueName(queue, instance).customizeDeclarationName
	}
	
	override protected getTargetSlaveQueueName(Event event, Port port, ParameterDeclaration parameter, AsynchronousComponentInstance instance) {
		return super.getTargetSlaveQueueName(event, port, parameter, instance).map[it.customizeDeclarationName]
	}
	
//	override getSourceVariable(String id) {
//		val backAnnotatedId = id.substring(DECLARATION_NAME_PREFIX.length)
//		return super.getSourceVariable(backAnnotatedId)
//	}
//	
//	override getSourceVariableFieldHierarchy(String id) {
//		val backAnnotatedId = id.substring(DECLARATION_NAME_PREFIX.length)
//		return super.getSourceVariableFieldHierarchy(backAnnotatedId)
//	}
//	
//	override getSynchronousSourceInEventParameterFieldHierarchy(String id) {
//		val backAnnotatedId = id.substring(DECLARATION_NAME_PREFIX.length)
//		return super.getSynchronousSourceInEventParameterFieldHierarchy(backAnnotatedId)
//	}
//	
//	override getSynchronousSourceOutEvent(String id) {
//		val backAnnotatedId = id.substring(DECLARATION_NAME_PREFIX.length)
//		return super.getSynchronousSourceOutEvent(backAnnotatedId)
//	}
//	
//	override getSourceOutEventParameterFieldHierarchy(String id) {
//		val backAnnotatedId = id.substring(DECLARATION_NAME_PREFIX.length)
//		return super.getSourceOutEventParameterFieldHierarchy(backAnnotatedId)
//	}
//	
//	override getAsynchronousSourceMessageQueue(String id) {
//		val backAnnotatedId = id.substring(DECLARATION_NAME_PREFIX.length)
//		return super.getAsynchronousSourceMessageQueue(backAnnotatedId)
//	}
//	
//	override getAsynchronousSourceInEventParameter(String id) {
//		val backAnnotatedId = id.substring(DECLARATION_NAME_PREFIX.length)
//		return super.getAsynchronousSourceInEventParameter(backAnnotatedId)
//	}
//	
//	override getAsynchronousSourceInEventParameterFieldHierarchy(String id) {
//		val backAnnotatedId = id.substring(DECLARATION_NAME_PREFIX.length)
//		return super.getAsynchronousSourceInEventParameterFieldHierarchy(backAnnotatedId)
//	}
//	
//	override getAsynchronousSourceOutEvent(String id) {
//		val backAnnotatedId = id.substring(DECLARATION_NAME_PREFIX.length)
//		return super.getAsynchronousSourceOutEvent(backAnnotatedId)
//	}
	
}