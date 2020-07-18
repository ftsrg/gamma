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
package hu.bme.mit.gamma.genmodel.language.validation

import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.genmodel.model.AdaptiveContractTestGeneration
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation
import hu.bme.mit.gamma.genmodel.model.AsynchronousInstanceConstraint
import hu.bme.mit.gamma.genmodel.model.CodeGeneration
import hu.bme.mit.gamma.genmodel.model.EventMapping
import hu.bme.mit.gamma.genmodel.model.EventPriorityTransformation
import hu.bme.mit.gamma.genmodel.model.GenModel
import hu.bme.mit.gamma.genmodel.model.GenmodelModelPackage
import hu.bme.mit.gamma.genmodel.model.InterfaceCompilation
import hu.bme.mit.gamma.genmodel.model.InterfaceMapping
import hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint
import hu.bme.mit.gamma.genmodel.model.PhaseStatechartGeneration
import hu.bme.mit.gamma.genmodel.model.SchedulingConstraint
import hu.bme.mit.gamma.genmodel.model.StateCoverage
import hu.bme.mit.gamma.genmodel.model.StatechartCompilation
import hu.bme.mit.gamma.genmodel.model.Task
import hu.bme.mit.gamma.genmodel.model.TestGeneration
import hu.bme.mit.gamma.genmodel.model.TestReplayModelGeneration
import hu.bme.mit.gamma.genmodel.model.TransitionCoverage
import hu.bme.mit.gamma.genmodel.model.Verification
import hu.bme.mit.gamma.genmodel.model.YakinduCompilation
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration
import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelPackage
import hu.bme.mit.gamma.statechart.interface_.RealizationMode
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.FileUtil
import java.util.HashMap
import java.util.HashSet
import java.util.Set
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.validation.Check
import org.yakindu.base.types.Direction
import org.yakindu.base.types.Event
import org.yakindu.sct.model.stext.stext.InterfaceScope

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class GenModelValidator extends AbstractGenModelValidator {
	
	protected extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected extension FileUtil fileUtil = FileUtil.INSTANCE
	
	// Checking tasks, only one parameter is acceptable
	
	@Check
	def checkTasks(Task task) {
		if (task.fileName.size > 1) {
			error("At most one file name can be specified.", GenmodelModelPackage.Literals.TASK__FILE_NAME)
		}
		if (task.targetFolder.size > 1) {
			error("At most one target folder can be specified.", GenmodelModelPackage.Literals.TASK__TARGET_FOLDER)
		}
	}
	
	@Check
	def checkTasks(YakinduCompilation yakinduCompilation) {
		if (yakinduCompilation.packageName.size > 1) {
			error("At most one package name can be specified.", GenmodelModelPackage.Literals.YAKINDU_COMPILATION__PACKAGE_NAME)
		}
	}
	
	@Check
	def checkTasks(StatechartCompilation statechartCompilation) {
		if (statechartCompilation.statechartName.size > 1) {
			error("At most one statechart name can be specified.", GenmodelModelPackage.Literals.STATECHART_COMPILATION__STATECHART_NAME)
		}
	}
	
	@Check
	def checkTasks(AnalysisModelTransformation analysisModelTransformation) {
		if (analysisModelTransformation.scheduler.size > 1) {
			error("At most one scheduler type can be specified.", GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__SCHEDULER)
		}
		val languages = analysisModelTransformation.languages
		if (languages.size != languages.toSet.size) {
			error("A single formal language can be specified only once.", GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__LANGUAGES)
		}
		if (analysisModelTransformation.coverages.filter(TransitionCoverage).size > 1) {
			error("A single transition coverage task can be defined.", GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__COVERAGES)
		}
		if (analysisModelTransformation.coverages.filter(StateCoverage).size > 1) {
			error("A single state coverage task can be defined.", GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__COVERAGES)
		}
		val constraint = analysisModelTransformation.constraint
		if (constraint !== null) {
			val component = analysisModelTransformation.component
			if (component instanceof AsynchronousComponent && constraint instanceof OrchestratingConstraint) {
				error("Asynchronous component constraints must contain either a 'top' keyword or references to the contained instances.", GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__CONSTRAINT)
			}
		}
	}
	
	@Check
	def checkTasks(Verification verification) {
		val languages = verification.languages
		if (languages.size != 1) {
			error("A single formal language must be specified.", GenmodelModelPackage.Literals.VERIFICATION__LANGUAGES)
		}
		val resourceFile = ecoreUtil.getFile(verification.eResource)
		val modelFiles = verification.fileName
		if (modelFiles.size != 1) {
			error("A single model file must be specified.", GenmodelModelPackage.Literals.TASK__FILE_NAME)
		}
		for (modelFile : modelFiles) {
			if (!resourceFile.isValidRelativeFile(modelFile)) {
				val index = modelFiles.indexOf(modelFile)
				error("This is not a valid relative path to a model file: " + modelFile,
					GenmodelModelPackage.Literals.TASK__FILE_NAME, index)
			}
		}
		val queryFiles = verification.queryFiles
		val propertyPackages = verification.propertyPackages
		if (queryFiles.size + propertyPackages.size < 1) {
			error("At least one query file must be specified.", GenmodelModelPackage.Literals.VERIFICATION__QUERY_FILES)
		}
		for (queryFile : queryFiles) {
			if (!resourceFile.isValidRelativeFile(queryFile)) {
				val index = queryFiles.indexOf(queryFile)
				error("This is not a valid relative path to a query file: " + queryFile,
					GenmodelModelPackage.Literals.VERIFICATION__QUERY_FILES, index)
			}
		}
		val testFolders = verification.testFolder
		if (testFolders.size > 1) {
			error("At most one test folder can be specified.", GenmodelModelPackage.Literals.VERIFICATION__TEST_FOLDER)
		}
	}
	
	@Check
	def checkTasks(TestReplayModelGeneration modelGeneration) {
		val systemFileNames = modelGeneration.fileName
		if (systemFileNames.size != 1) {
			error("A single system file name must be specified.", GenmodelModelPackage.Literals.TASK__FILE_NAME)
		}
		val targetFolders = modelGeneration.targetFolder
		if (targetFolders.size > 1) {
			error("At most one test folder can be specified.", GenmodelModelPackage.Literals.TASK__TARGET_FOLDER)
		}
	}
	
	@Check
	def checkTimeSpecification(TimeSpecification timeSpecification) {
		if (!typeDeterminator.isInteger(timeSpecification.getValue())) {
			error("Time values must be of type integer.", InterfaceModelPackage.Literals.TIME_SPECIFICATION__VALUE)
		}
	}
	
	@Check
	def checkConstraint(AsynchronousInstanceConstraint constraint) {
		val analysisModelTransformation = EcoreUtil2.getContainerOfType(constraint, AnalysisModelTransformation)
		val component = analysisModelTransformation.component
		if (!component.isAsynchronous) {
			error("Asynchronous component constraints must refer to an asynchronous component.", GenmodelModelPackage.Literals.ASYNCHRONOUS_INSTANCE_CONSTRAINT__ORCHESTRATING_CONSTRAINT)
			return
		}
		val scheduling = EcoreUtil2.getContainerOfType(constraint, SchedulingConstraint)
		val instance = constraint.instance
		if (instance !== null) {
			val lastInstance = instance.componentInstanceHierarchy.last
			if (!lastInstance.isAsynchronous) {
				error("Asynchronous component constraints must contain a reference to a contained asynchronous instance.", GenmodelModelPackage.Literals.ASYNCHRONOUS_INSTANCE_CONSTRAINT__INSTANCE)
			}
		}
		if (component instanceof AsynchronousCompositeComponent) {
			if (instance === null) {
				error("Asynchronous component constraints must contain a reference to a contained instance.", GenmodelModelPackage.Literals.ASYNCHRONOUS_INSTANCE_CONSTRAINT__INSTANCE)
			}
			if (scheduling.instanceConstraint.filter[ecoreUtil.helperEquals(it.instance, instance)].size > 1) {
				error("The scheduling constraints for a certain asynchronous component can be defined at most once.", GenmodelModelPackage.Literals.ASYNCHRONOUS_INSTANCE_CONSTRAINT__INSTANCE)
			}
		}
		if (component instanceof AsynchronousAdapter) {
			if (scheduling.instanceConstraint.size > 1) {
				error("Asynchronous adapters can contain at most one constraint.", GenmodelModelPackage.Literals.ASYNCHRONOUS_INSTANCE_CONSTRAINT__ORCHESTRATING_CONSTRAINT)
			}
		}
	}
	
	@Check
	def checkMinimumMaximumOrchestrationPeriodValues(OrchestratingConstraint orchestratingConstraint) {
		try {
			val minimum = orchestratingConstraint.minimumPeriod
			val maximum = orchestratingConstraint.maximumPeriod
			if (minimum !== null) {
				if (maximum !== null) {
					var minimumIntegerValue = minimum.evaluateMilliseconds
					var maximumIntegerValue = maximum.evaluateMilliseconds
					if (minimumIntegerValue < 0) {
						error("Time value must be positive.", GenmodelModelPackage.Literals.ORCHESTRATING_CONSTRAINT__MINIMUM_PERIOD)
					}
					if (maximumIntegerValue < 0) {
						error("Time value must be positive.", GenmodelModelPackage.Literals.ORCHESTRATING_CONSTRAINT__MAXIMUM_PERIOD)
					}
					if (maximumIntegerValue < minimumIntegerValue) {
						error("The minimum orchestrating period value must be greater than the maximum orchestrating period value.", GenmodelModelPackage.Literals.ORCHESTRATING_CONSTRAINT__MINIMUM_PERIOD)
					}
				}
			}
		} catch (IllegalArgumentException e) {
			error('''Both the minimum and maximum values must be of type integer.''', GenmodelModelPackage.Literals.ORCHESTRATING_CONSTRAINT__MINIMUM_PERIOD)
		}
	}
	
	@Check
	def checkTasks(CodeGeneration codeGeneration) {
		if (codeGeneration.packageName.size > 1) {
			error("At most one package name can be specified.", GenmodelModelPackage.Literals.ABSTRACT_CODE_GENERATION__PACKAGE_NAME)
		}
		if (codeGeneration.language.size != 1) {
			error("A single programming language must be specified.", GenmodelModelPackage.Literals.ABSTRACT_CODE_GENERATION__PACKAGE_NAME)
		}
	}
	
	@Check
	def checkTasks(TestGeneration testGeneration) {
		if (testGeneration.packageName.size > 1) {
			error("At most one package name can be specified.", GenmodelModelPackage.Literals.ABSTRACT_CODE_GENERATION__PACKAGE_NAME)
		}
		if (testGeneration.language.size != 1) {
			error("A single programming language must be specified.", GenmodelModelPackage.Literals.ABSTRACT_CODE_GENERATION__PACKAGE_NAME)
		}
	}
	
	// Additional validation rules
	
	@Check
	def checkGammaImports(GenModel genmodel) {
		val packageImports = genmodel.packageImports.toSet
		for (codeGenerationTask : genmodel.tasks.filter(CodeGeneration)) {
			val parentPackage = codeGenerationTask.component.containingPackage
			packageImports.remove(parentPackage)
		}
		for (analysisModelTransformationTask : genmodel.tasks.filter(AnalysisModelTransformation)) {
			val parentPackage = analysisModelTransformationTask.component.containingPackage
			packageImports.remove(parentPackage)
			for (coverage : analysisModelTransformationTask.coverages) {
				for (instance : coverage.include + coverage.exclude) {
					val instanceParentPackage = instance.containingPackage
					packageImports.remove(instanceParentPackage)
				}
			}
		}
		for (statechartCompilationTask : genmodel.tasks.filter(StatechartCompilation)) {
			for (interfaceMapping : statechartCompilationTask.interfaceMappings) {
				val parentPackage = interfaceMapping.gammaInterface.containingPackage
				packageImports.remove(parentPackage)
			}
		}
		for (eventPriorityTransformationTask : genmodel.tasks.filter(EventPriorityTransformation)) {
			val parentPackage = eventPriorityTransformationTask.statechart.containingPackage
			packageImports.remove(parentPackage)
		}
		for (adaptiveContractTestGenerationTask : genmodel.tasks.filter(AdaptiveContractTestGeneration)) {
			val parentPackage = adaptiveContractTestGenerationTask.statechartContract.containingPackage
			packageImports.remove(parentPackage)
		}
		for (phaseStatechartGenerationTask : genmodel.tasks.filter(PhaseStatechartGeneration)) {
			val parentPackage = phaseStatechartGenerationTask.statechart.containingPackage
			packageImports.remove(parentPackage)
		}
		for (packageImport : packageImports) {
			val index = genmodel.packageImports.indexOf(packageImport);
			warning("This Gamma package import is not used.", GenmodelModelPackage.Literals.GEN_MODEL__PACKAGE_IMPORTS, index)
		}
	}

	@Check
	def checkYakinduImports(GenModel genmodel) {
		val statechartImports = genmodel.statechartImports.toSet
		for (statechartCompilationTask : genmodel.tasks.filter(YakinduCompilation)) {
			statechartImports -= statechartCompilationTask.statechart
		}
		for (statechartImport : statechartImports) {
			val index = genmodel.statechartImports.indexOf(statechartImport);
			warning("This Yakindu import is not used.", GenmodelModelPackage.Literals.GEN_MODEL__STATECHART_IMPORTS, index);
		}
	}
	
	@Check
	def checkTraceImports(GenModel genmodel) {
		val traceImports = genmodel.traceImports.toSet
		for (testGenerationTask : genmodel.tasks.filter(TestGeneration)) {
			traceImports -= testGenerationTask.executionTrace
		}
		for (testReplayModelGeneration : genmodel.tasks.filter(TestReplayModelGeneration)) {
			traceImports -= testReplayModelGeneration.executionTrace
		}
		for (traceImport : traceImports) {
			val index = genmodel.traceImports.indexOf(traceImport);
			warning("This execution trace import is not used.", GenmodelModelPackage.Literals.GEN_MODEL__TRACE_IMPORTS, index);
		}
	}
	
	@Check
	def checkParameters(AnalysisModelTransformation analysisModelTransformation) {
		val type = analysisModelTransformation.component
		if (analysisModelTransformation.getArguments().size() != type.getParameterDeclarations().size()) {
			error("The number of arguments is wrong.", ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS)
		}
	}
	
	@Check
	def checkComponentInstanceArguments(AnalysisModelTransformation analysisModelTransformation) {
		try {
			val type = analysisModelTransformation.component
			val parameters = type.getParameterDeclarations();
			for (var i = 0; i < parameters.size(); i++) {
				val parameter = parameters.get(i);
				val argument = analysisModelTransformation.getArguments().get(i);
				val declarationType = parameter.getType();
				val argumentType = typeDeterminator.getType(argument);
				if (!typeDeterminator.equals(declarationType, argumentType)) {
					error("The types of the declaration and the right hand side expression are not the same: " +
							typeDeterminator.transform(declarationType).toString().toLowerCase() + " and " +
							argumentType.toString().toLowerCase() + ".",
							ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS, i);
				} 
			}
		} catch (Exception exception) {
			// There is a type error on a lower level, no need to display the error message on this level too
		}
	}
	
	@Check
	def checkIfAllInterfacesMapped(StatechartCompilation statechartCompilation) {
		val interfaces = statechartCompilation.statechart.scopes.filter(InterfaceScope).toSet
		val mappedInterfaces = statechartCompilation.interfaceMappings.map[it.yakinduInterface].toSet
		interfaces.removeAll(mappedInterfaces)
		if (!interfaces.empty) {
			val interfacesWithEvents = interfaces.filter[!it.events.empty].toSet
			val interfacesWithoutEvents = interfaces.filter[it.events.empty].toSet
			if (!interfacesWithEvents.empty) {
				error("The following interfaces with events are not mapped: " + interfacesWithEvents.map[it.name] + ".", GenmodelModelPackage.Literals.YAKINDU_COMPILATION__STATECHART)
			}
			if (!interfacesWithoutEvents.empty) {
				info("The following interfaces without events are not mapped: " + interfacesWithoutEvents.map[it.name] + ".", GenmodelModelPackage.Literals.YAKINDU_COMPILATION__STATECHART)
			}
		}
	}
	
	@Check
	def checkInterfaceConformance(InterfaceMapping mapping) {
		if (!(mapping.checkConformance)) {
			switch mapping.realizationMode {
				case RealizationMode.PROVIDED:
					error("In case of provided realization mode number of in/out events must equal to the number of in/out events in the Gamma interface and vice versa.", GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)
				case RealizationMode.REQUIRED:
					error("In case of required realization mode number of in/out events must equal to the number of out/in events in the Gamma interface and vice versa", GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)
				default:
					throw new IllegalArgumentException("Such interface realization mode is not supported: " + mapping.realizationMode)
			}
		}
	}
	
	/** It checks the events of the parent interfaces as well. */
	private def boolean checkConformance(InterfaceMapping mapping) {
		val yOut = mapping.yakinduInterface.events.filter[it.direction == Direction.OUT].size
		val yIn = mapping.yakinduInterface.events.filter[it.direction == Direction.IN].size
		val gOut = mapping.gammaInterface.allEventDeclarations.filter[it.direction != EventDirection.IN].size // Regarding in-out events
		val gIn = mapping.gammaInterface.allEventDeclarations.filter[it.direction != EventDirection.OUT].size // Regarding in-out events
		val realMode = mapping.realizationMode
		return (realMode == RealizationMode.PROVIDED && yOut == gOut && yIn == gIn) ||
			(realMode == RealizationMode.REQUIRED && yOut == gIn && yIn == gOut)
	}
	
	@Check
	def checkInterfaceMappingWithoutEventMapping(InterfaceMapping mapping) {
		// 0 event mapping is acceptable if the two interfaces are equal
		val realizationMode = mapping.realizationMode
		if (mapping.eventMappings.size == 0) {
			// If the interface has in-out events, 0 event mapping is surely not acceptable
			if (!mapping.gammaInterface.events.filter[it.direction == EventDirection.INOUT].empty) {
				error("The Gamma interface has in-out events, thus an automatic mapping is not possible", GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)
				return
			}
			for (yakinduEvent : mapping.yakinduInterface.events) {
				val gammaEvents = mapping.gammaInterface.events.map[it.event].filter[it.name.equals(yakinduEvent.name)]
				val gammaEvent = gammaEvents.head
				if (!(gammaEvents.size == 1 && checkParameters(yakinduEvent, gammaEvent)
					&& realizationMode.areWellDirected(yakinduEvent, gammaEvent.eContainer as EventDeclaration))) {
					val typeName = if (yakinduEvent.type !== null) {" : " + yakinduEvent.type.name} else {""}
					error("Interface mapping without event mapping is only possible if the names and types of the events of the interfaces are equal. " 
						+ yakinduEvent.name + typeName + " has no equivalent event in the Gamma interface.", GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE
					)
				}			
			}
		}
	}
	
	/**
	 * Checks whether the event directions conform to the realization mode.
	 */
	private def areWellDirected(RealizationMode interfaceType, Event yEvent, EventDeclaration gEvent) {
		if (interfaceType == RealizationMode.PROVIDED) {
			return (yEvent.direction == Direction.OUT && gEvent.direction != EventDirection.IN) ||
			(yEvent.direction == Direction.IN && gEvent.direction != EventDirection.OUT)
		}
		else if (interfaceType == RealizationMode.REQUIRED) {
			return (yEvent.direction == Direction.OUT && gEvent.direction != EventDirection.OUT) ||
			(yEvent.direction == Direction.IN && gEvent.direction != EventDirection.IN)
		}
		else {
			throw new IllegalArgumentException("No such direction: " + interfaceType)
		}
	}
	
	@Check
	def checkMappingCount(InterfaceMapping mapping) {
		// Check only if the interface mapping is not trivial (size != 0)
		if (mapping.eventMappings.size != 0 && mapping.yakinduInterface.events.size != mapping.eventMappings.size) {
			error("Each Yakindu event has to be mapped exactly once.", GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)
		}
	}
	
	@Check
	def checkYakinduInterfaceUniqueness(InterfaceMapping mapping) {
		val interfaces = new HashSet<InterfaceScope>
		val statechartCompilation = mapping.eContainer as StatechartCompilation
		for (interface : statechartCompilation.interfaceMappings.map[it.yakinduInterface]) {
			if (interfaces.contains(interface)){
				error("Each Yakindu event has to be mapped exactly once.", GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)
			}
			else {
				interfaces.add(interface)
			}			
		}
	}
	
	@Check
	def checkEventMappingCount(InterfaceMapping mapping) {
		val mappedYakinduEvents = new HashSet<Event>
		val mappedGammaEvents = new HashMap<hu.bme.mit.gamma.statechart.interface_.Event, Set<Event>>
		for (eventMapping : mapping.eventMappings) {
			val yakinduEvent = eventMapping.yakinduEvent
			val gammaEvent = eventMapping.gammaEvent
			// Yakindu validation
			if (mappedYakinduEvents.contains(yakinduEvent)) {
				error("This event is mapped multiple times: " + yakinduEvent.name + ".", GenmodelModelPackage.Literals.INTERFACE_MAPPING__EVENT_MAPPINGS)
			}
			else {
				mappedYakinduEvents += yakinduEvent			
			}
			// Gamma validation
			if (mappedGammaEvents.containsKey(gammaEvent)) {
				val gammaEventDeclaration = gammaEvent.eContainer as EventDeclaration
				if (gammaEventDeclaration.direction == EventDirection.INOUT) {
					val yakinduEventSet = mappedGammaEvents.get(gammaEvent)
					yakinduEventSet += yakinduEvent
					// A single in and a single out event has to be now in yakinduEventSet
					if (!(yakinduEventSet.filter[it.direction == Direction.IN].size == 1 &&
							yakinduEventSet.filter[it.direction == Direction.OUT].size == 1)) {
						error("A single in and a single out event has to be mapped onto this Gamma event: " + gammaEvent.name + ".",
							GenmodelModelPackage.Literals.INTERFACE_MAPPING__EVENT_MAPPINGS)
					}
				}
				else {
					// Not an in-out event
					error("Multiple Yakindu events are mapped to this Gamma event: " + gammaEvent.name + ".", GenmodelModelPackage.Literals.INTERFACE_MAPPING__EVENT_MAPPINGS)
				}
			}
			else {
				// First entry
				mappedGammaEvents.put(gammaEvent, newHashSet(yakinduEvent))			
			}
		}		
	}
	
	@Check
	def checkEventConformance(EventMapping mapping) {		
		val ifReal = mapping.eContainer as InterfaceMapping
		if (!(mapping.checkConformance)) {
			switch (ifReal.realizationMode) {
				case RealizationMode.PROVIDED:
					error("In case of provided realization mode Yakindu events must have the same direction and parameter as Gamma events.", GenmodelModelPackage.Literals.EVENT_MAPPING__YAKINDU_EVENT)
				case RealizationMode.REQUIRED:
					error("In case of required realization mode Yakindu events must have the opposite direction and same parameter of Gamma events.", GenmodelModelPackage.Literals.EVENT_MAPPING__YAKINDU_EVENT)		
			default:
				throw new IllegalArgumentException("Such interface realization mode is not supported: " + ifReal.realizationMode)				
			}
		}
	}
	
	@Check
	def checkTraces(TestGeneration testGeneration) {
		val genmodel = testGeneration.eContainer as GenModel
		val usedInterfaces = testGeneration.executionTrace.component.ports
								.map[it.interfaceRealization.interface]
								.map[it.name].toSet
		val transformedInterfaces = genmodel.tasks.filter(InterfaceCompilation)
								.map[it.statechart.scopes].flatten
								.filter(InterfaceScope).map[it.name].toSet
		usedInterfaces.retainAll(transformedInterfaces)
		if (!usedInterfaces.isEmpty) {
			warning("This trace depends on interfaces " + usedInterfaces + ", which seem to be about to be recompiled. " + 
				"The recompilation of interfaces just before the generation of tests might cause a break in the generated test suite.",
				 GenmodelModelPackage.Literals.TEST_GENERATION__EXECUTION_TRACE)
		}
	}
	
	private def boolean checkConformance(EventMapping mapping) {
		val yEvent = mapping.yakinduEvent
		val gEvent = mapping.gammaEvent.eContainer as EventDeclaration
		val ifReal = mapping.eContainer as InterfaceMapping
		val realMode = ifReal.realizationMode
		return checkEventConformance(yEvent, gEvent, realMode)
	}
	
	private def checkEventConformance(Event yEvent, EventDeclaration gEvent, RealizationMode realMode) {
		switch (realMode) {
			 // Regarding in-out events
			case RealizationMode.PROVIDED:
				return yEvent.direction == Direction.IN && gEvent.direction != EventDirection.OUT && checkParameters(yEvent, gEvent.event) ||
					yEvent.direction == Direction.OUT && gEvent.direction != EventDirection.IN && checkParameters(yEvent, gEvent.event)
			case RealizationMode.REQUIRED:
				return yEvent.direction == Direction.IN && gEvent.direction != EventDirection.IN && checkParameters(yEvent, gEvent.event) ||
					yEvent.direction == Direction.OUT && gEvent.direction != EventDirection.OUT && checkParameters(yEvent, gEvent.event)
			default:
				throw new IllegalArgumentException("Such interface realization mode is not supported: " + realMode)				
		}
	}
	
	private def checkParameters(Event yEvent, hu.bme.mit.gamma.statechart.interface_.Event gEvent) {
		// event.type is null not void if no explicit type is declared
		if (yEvent.type === null && gEvent.parameterDeclarations.empty) {
			return true
		}
		if (!gEvent.parameterDeclarations.empty) {
			switch (gEvent.parameterDeclarations.head.type) {
				IntegerTypeDefinition: {
					if (yEvent.type === null) {
						return false
					}
					return yEvent.type.name.equals("integer") ||
						yEvent.type.name.equals("string") // strings are mapped to integers					
				}
				BooleanTypeDefinition: {
					if (yEvent.type === null) {
						return false
					}
					return yEvent.type.name.equals("boolean")					
				}
				DecimalTypeDefinition: {
					if (yEvent.type === null) {
						return false
					}
					return yEvent.type.name.equals("real")					
				}
				default:
					throw new IllegalArgumentException("Not known type: " + gEvent.parameterDeclarations.head.type)
			}		
		}
		return false
	}
	
	@Check
	def checkComponentInstanceReferences(ComponentInstanceReference reference) {
		val instances = reference.getComponentInstanceHierarchy
		if (instances.empty) {
			return
		}
		for (var i = 0; i < instances.size - 1; i++) {
			val instance = instances.get(i)
			val nextInstance = instances.get(i + 1)
			val type = instance.derivedType
			val containedInstances = type.eContents
			if (!containedInstances.contains(nextInstance)) {
				error(instance.name + " does not contain component instance " + nextInstance.name,
					CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE__COMPONENT_INSTANCE_HIERARCHY, i)
			}
		}
		val model = ecoreUtil.getContainerOfType(reference, AnalysisModelTransformation)
		if (model !== null) {
			val component = model.component
			val containedComponents = component.eContents.filter(ComponentInstance).toList
			val firstInstance = instances.head
			if (!containedComponents.contains(firstInstance)) {
				error("The first component instance must be the component of " + component.name,
					CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE__COMPONENT_INSTANCE_HIERARCHY, 0)
			}
		}
	}
	
}
