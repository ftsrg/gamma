/********************************************************************************
 * Copyright (c) 2023-2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlFinalType
import ac.soton.scxml.ScxmlHistoryType
import ac.soton.scxml.ScxmlParallelType
import ac.soton.scxml.ScxmlScxmlType
import ac.soton.scxml.ScxmlStateType

class Namings {

	// TODO check default names differ from user defined interface and port names at the end of the transformation
	def static String getDefaultPortName(String instanceName) '''«instanceName»_DefaultPort'''
	def static String getDefaultInterfaceName(String instanceName) '''«instanceName»_DefaultInterface'''
	def static String getDefaultInterfacePortName(String scxmlInterfaceName) '''«scxmlInterfaceName»_DefaultPort'''
	def static String getInterfaceName(String scxmlInterfaceName) '''«scxmlInterfaceName»'''
	def static String getPortName(String scxmlPortName) '''«scxmlPortName»'''

	def static String getInternalEventName(String scxmlEventName) '''«scxmlEventName»'''
	def static String getInEventName(String scxmlEventName) '''«scxmlEventName»'''
	def static String getOutEventName(String scxmlEventName) '''«scxmlEventName»'''

	def static String getAdapterName(ScxmlScxmlType scxmlRoot) '''«scxmlRoot.name»Adapter'''
	def static String getInternalEventQueueName(ScxmlScxmlType scxmlRoot) '''«scxmlRoot.name»InternalEventQueue'''
	def static String getExternalEventQueueName(ScxmlScxmlType scxmlRoot) '''«scxmlRoot.name»ExternalEventQueue'''

	def static String getInterfacePackageName(ScxmlScxmlType scxmlRoot) '''«scxmlRoot.name.toLowerCase»_interfaces'''
	def static String getCompositeStatechartName(ScxmlScxmlType scxmlRoot) '''«scxmlRoot.name»'''
	def static String getStatechartName(ScxmlScxmlType scxmlRoot) '''«scxmlRoot.name»'''
	def static String getRegionName(String scxmlElementName) '''«scxmlElementName»Region'''

	def static String getParallelName(ScxmlParallelType scxmlParallel) '''«scxmlParallel.id»'''
	def static String getStateName(ScxmlStateType scxmlState) '''«scxmlState.id»'''
	def static String getFinalName(ScxmlFinalType scxmlFinal) '''«scxmlFinal.id»'''

	def static String getInitialName(ScxmlStateType scxmlParentState) '''«scxmlParentState.id»Initial'''
	def static String getInitialName(ScxmlScxmlType scxmlRoot) '''«scxmlRoot.name»Initial'''
	def static String getShallowHistoryName(ScxmlHistoryType scxmlHistoryState) '''«scxmlHistoryState.id»ShallowHistory'''
	def static String getDeepHistoryName(ScxmlHistoryType scxmlHistoryState) '''«scxmlHistoryState.id»DeepHistory'''

}
