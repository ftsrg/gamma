/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.derivedfeatures;

import java.math.BigInteger;
import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Optional;
import java.util.Queue;
import java.util.Set;
import java.util.function.Predicate;
import java.util.stream.Collectors;

import org.eclipse.emf.common.util.TreeIterator;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.EcoreUtil;

import hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures;
import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.expression.model.ArgumentedElement;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.FunctionDeclaration;
import hu.bme.mit.gamma.expression.model.NamedElement;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.statechart.composite.AbstractAsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.AbstractSynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.BroadcastChannel;
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.Channel;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.CompositeComponent;
import hu.bme.mit.gamma.statechart.composite.ControlFunction;
import hu.bme.mit.gamma.statechart.composite.ControlSpecification;
import hu.bme.mit.gamma.statechart.composite.EventPassing;
import hu.bme.mit.gamma.statechart.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.composite.MessageQueue;
import hu.bme.mit.gamma.statechart.composite.PortBinding;
import hu.bme.mit.gamma.statechart.composite.SchedulableCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.ScheduledAsynchronousCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.SimpleChannel;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.contract.AdaptiveContractAnnotation;
import hu.bme.mit.gamma.statechart.contract.HasInitialOutputsBlockAnnotation;
import hu.bme.mit.gamma.statechart.contract.NegativeContractStatechartAnnotation;
import hu.bme.mit.gamma.statechart.contract.ScenarioAllowedWaitAnnotation;
import hu.bme.mit.gamma.statechart.contract.ScenarioContractAnnotation;
import hu.bme.mit.gamma.statechart.contract.StateContractAnnotation;
import hu.bme.mit.gamma.statechart.interface_.AnyTrigger;
import hu.bme.mit.gamma.statechart.interface_.Clock;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.ComponentAnnotation;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration;
import hu.bme.mit.gamma.statechart.interface_.EventDirection;
import hu.bme.mit.gamma.statechart.interface_.EventReference;
import hu.bme.mit.gamma.statechart.interface_.EventSource;
import hu.bme.mit.gamma.statechart.interface_.EventTrigger;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.InterfaceParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.interface_.InterfaceRealization;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.PackageAnnotation;
import hu.bme.mit.gamma.statechart.interface_.Persistency;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.RealizationMode;
import hu.bme.mit.gamma.statechart.interface_.SimpleTrigger;
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.interface_.TimeUnit;
import hu.bme.mit.gamma.statechart.interface_.TopComponentArgumentsAnnotation;
import hu.bme.mit.gamma.statechart.interface_.Trigger;
import hu.bme.mit.gamma.statechart.interface_.UnfoldedPackageAnnotation;
import hu.bme.mit.gamma.statechart.interface_.WrapperComponentAnnotation;
import hu.bme.mit.gamma.statechart.phase.History;
import hu.bme.mit.gamma.statechart.phase.MissionPhaseAnnotation;
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateAnnotation;
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference;
import hu.bme.mit.gamma.statechart.statechart.AsynchronousStatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger;
import hu.bme.mit.gamma.statechart.statechart.ChoiceState;
import hu.bme.mit.gamma.statechart.statechart.ClockTickReference;
import hu.bme.mit.gamma.statechart.statechart.CompositeElement;
import hu.bme.mit.gamma.statechart.statechart.DeepHistoryState;
import hu.bme.mit.gamma.statechart.statechart.EntryState;
import hu.bme.mit.gamma.statechart.statechart.ForkState;
import hu.bme.mit.gamma.statechart.statechart.InitialState;
import hu.bme.mit.gamma.statechart.statechart.JoinState;
import hu.bme.mit.gamma.statechart.statechart.MergeState;
import hu.bme.mit.gamma.statechart.statechart.MutantAnnotation;
import hu.bme.mit.gamma.statechart.statechart.OnCycleTrigger;
import hu.bme.mit.gamma.statechart.statechart.PortEventReference;
import hu.bme.mit.gamma.statechart.statechart.PseudoState;
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction;
import hu.bme.mit.gamma.statechart.statechart.Region;
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction;
import hu.bme.mit.gamma.statechart.statechart.ShallowHistoryState;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StateAnnotation;
import hu.bme.mit.gamma.statechart.statechart.StateNode;
import hu.bme.mit.gamma.statechart.statechart.StatechartAnnotation;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.SynchronousStatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration;
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference;
import hu.bme.mit.gamma.statechart.statechart.Transition;
import hu.bme.mit.gamma.statechart.statechart.TransitionAnnotation;
import hu.bme.mit.gamma.statechart.statechart.TransitionIdAnnotation;
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority;
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;

public class StatechartModelDerivedFeatures extends ActionModelDerivedFeatures {
	
	protected static final StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
	
	//
	
	public static Set<TypeDeclaration> getReferencedTypedDeclarations(Package _package) {
		Set<TypeDeclaration> types = new LinkedHashSet<TypeDeclaration>();
		
		// Explicit imports
		for (Package importedPackage : StatechartModelDerivedFeatures.getComponentImports(_package)) {
			types.addAll(importedPackage.getTypeDeclarations());
		}
		
		// Native references in the case of unfolded packages
		Collection<TypeReference> references = new ArrayList<TypeReference>();
		references.addAll(
				ecoreUtil.getAllContentsOfType(_package, TypeReference.class));
		
		// Events and parameters
		for (InterfaceRealization realization :
				ecoreUtil.getAllContentsOfType(_package, InterfaceRealization.class)) {
			Interface _interface = realization.getInterface();
			references.addAll(
					ecoreUtil.getAllContentsOfType(_interface, TypeReference.class));
		}
		
		// Collecting the type declarations
		for (TypeReference reference : references) {
			TypeDeclaration typeDeclaration = reference.getReference();
			types.add(typeDeclaration);
			Type containedType = typeDeclaration.getType();
			Type type = getTypeDefinition(containedType);
			if (type instanceof RecordTypeDefinition recordType) {
				Collection<TypeDeclaration> containedTypeDeclarations =
						getAllTypeDeclarations(recordType);
				types.addAll(containedTypeDeclarations);
			}
		}
		
		return types;
	}
	
	public static List<ParameterDeclaration> getParameterDeclarations(ArgumentedElement element) {
		if (element instanceof RaiseEventAction raiseEventAction) {
			Event event = raiseEventAction.getEvent();
			return event.getParameterDeclarations();
		}
		if (element instanceof ComponentInstance instance) {
			Component type = getDerivedType(instance);
			return type.getParameterDeclarations();
		}
		if (element instanceof FunctionAccessExpression functionAccess) {
			Declaration declaration = expressionUtil.getDeclaration(
					functionAccess.getOperand());
			if (declaration instanceof FunctionDeclaration functionDeclaration) {
				return functionDeclaration.getParameterDeclarations();
			}
			// Invalid model
			throw new IllegalArgumentException("No function declaration: " + declaration);
		}
		if (element instanceof StateContractAnnotation annotation) {
			StatechartDefinition statechart = annotation.getContractStatechart();
			return statechart.getParameterDeclarations();
		}
		throw new IllegalArgumentException("Not supported element: " + element);
	}

	public static boolean isBroadcast(InterfaceRealization interfaceRealization) {
		return isProvided(interfaceRealization) &&
			getAllEventDeclarations(interfaceRealization.getInterface()).stream()
				.allMatch(it -> it.getDirection() == EventDirection.OUT);
	}
	
	public static boolean isBroadcastMatcher(InterfaceRealization interfaceRealization) {
		return isRequired(interfaceRealization) &&
			getAllEventDeclarations(interfaceRealization.getInterface()).stream()
				.allMatch(it -> it.getDirection() == EventDirection.OUT);
	}
	
	public static boolean isProvided(InterfaceRealization interfaceRealization) {
		return interfaceRealization.getRealizationMode() == RealizationMode.PROVIDED;
	}
	
	public static boolean isRequired(InterfaceRealization interfaceRealization) {
		return interfaceRealization.getRealizationMode() == RealizationMode.REQUIRED;
	}
	
	public static RealizationMode getOpposite(RealizationMode realizationMode) {
		switch (realizationMode) {
			case PROVIDED:
				return RealizationMode.REQUIRED;
			case REQUIRED:
				return RealizationMode.PROVIDED;
			default:
				throw new IllegalArgumentException("Not known realization mode: " + realizationMode);
		}
	}
	
	public static boolean isBroadcast(Port port) {
		return isBroadcast(port.getInterfaceRealization());
	}
	
	public static boolean isBroadcastMatcher(Port port) {
		return isBroadcastMatcher(port.getInterfaceRealization());
	}
	
	public static boolean isBroadcastOrBroadcastMatcher(Port port) {
		return isBroadcast(port) || isBroadcastMatcher(port);
	}
	
	public static boolean isProvided(InstancePortReference port) {
		return isProvided(port.getPort());
	}
	
	public static boolean isProvided(Port port) {
		return isProvided(port.getInterfaceRealization());
	}
	
	public static boolean isRequired(InstancePortReference port) {
		return isRequired(port.getPort());
	}
	
	public static boolean isRequired(Port port) {
		return isRequired(port.getInterfaceRealization());
	}
	
	public static boolean isInternal(Port port) {
		List<EventDeclaration> eventDeclarations = getAllEventDeclarations(port);
		return eventDeclarations.stream().anyMatch(
				it -> it.getDirection() == EventDirection.INTERNAL);
	}
	
	public static boolean isMappableToInputPort(Port port) {
		List<Port> simplePorts = getAllBoundSimplePorts(port);
		Set<Component> statecharts = simplePorts.stream()
				.map(it -> getContainingComponent(it))
				.collect(Collectors.toSet());
		
		for (Component statechart : statecharts) {
			for (RaiseEventAction raiseEventAction : 
					ecoreUtil.getAllContentsOfType(statechart, RaiseEventAction.class)) {
				Port raisedPort = raiseEventAction.getPort();
				if (simplePorts.contains(raisedPort)) {
					return false;
				}
			}
		}
		
		return true;
	}
	
	public static boolean isMappableToOutputPort(Port port) {
		List<Port> simplePorts = getAllBoundSimplePorts(port);
		for (Port simplePort : simplePorts) {
			Component statechart = getContainingComponent(simplePort);
			if (isTriggeredVia(statechart, simplePort)) {
				return false;
			}
		}
		return true;
	}
	
	public static boolean isInternal(InstancePortReference port) {
		return isInternal(port.getPort());
	}
	
	public static Interface getInterface(Port port) {
		return port.getInterfaceRealization().getInterface();
	}
	
	public static boolean contains(Component component, Port port) {
		List<Port> ports = getAllPorts(component);
		return ports.contains(port);
	}
	
	public static EventDirection getOpposite(EventDirection eventDirection) {
		switch (eventDirection) {
			case IN:
				return EventDirection.OUT;
			case OUT:
				return EventDirection.IN;
			case INTERNAL:
				return EventDirection.INTERNAL;
			default:
				throw new IllegalArgumentException("Not known event direction: " + eventDirection);
		}
	}
	
	public static EventDirection adjust(EventDirection eventDirection,
			RealizationMode realizationMode) {
		switch (realizationMode) {
			case PROVIDED:
				return eventDirection;
			case REQUIRED:
				return getOpposite(eventDirection);
			default:
				throw new IllegalArgumentException("Not known realization mode: " + realizationMode);
		}
	}
	
	public static List<Expression> getTopComponentArguments(Package unfoldedPackage) {
		List<Expression> topComponentArguments = new ArrayList<Expression>();
		for (PackageAnnotation annotation : unfoldedPackage.getAnnotations()) {
			if (annotation instanceof TopComponentArgumentsAnnotation) {
				TopComponentArgumentsAnnotation argumentsAnnotation =
						(TopComponentArgumentsAnnotation) annotation;
				topComponentArguments.addAll(argumentsAnnotation.getArguments());
				return topComponentArguments; // There must be only one annotation
			}
		}
		return topComponentArguments;
	}
	
	public static boolean isUnfolded(EObject object) {
		return isUnfolded(
				getContainingPackage(object));
	}
	
	public static boolean isUnfolded(Package gammaPackage) {
		return hasAnnotation(gammaPackage, UnfoldedPackageAnnotation.class);
	}
	
	public static boolean isWrapped(EObject object) {
		return hasWrapperComponent(
				getContainingPackage(object));
	}
	
	public static boolean hasWrapperComponent(Package gammaPackage) {
		return isWrapperComponent(
				getFirstComponent(gammaPackage));
	}
	
	public static boolean hasAnnotation(Package gammaPackage,
			Class<? extends PackageAnnotation> annotation) {
		return gammaPackage.getAnnotations().stream().anyMatch(it -> annotation.isInstance(it));
	}
	
	public static boolean hasAnnotation(StatechartDefinition statechart,
			Class<? extends StatechartAnnotation> annotation) {
		return statechart.getAnnotations().stream().anyMatch(it -> annotation.isInstance(it));
	}
	
	public static TimeUnit getSmallestTimeUnit(NamedElement element) {
		TimeUnit[] supportedTimeUnits = new TimeUnit[] { TimeUnit.NANOSECOND, // Order is important
				TimeUnit.MICROSECOND, TimeUnit.MILLISECOND, TimeUnit.SECOND, TimeUnit.HOUR };
		//
		List<TimeSpecification> timeUnits = ecoreUtil.getAllContentsOfType(
				element, TimeSpecification.class);
		for (TimeUnit timeUnit : supportedTimeUnits) {
			if (timeUnits.stream().anyMatch(it -> it.getUnit() == timeUnit)) {
				return timeUnit;
			}
		}
		// If none of the above: ms is default
		return TimeUnit.MILLISECOND;
	}
	
	public static long getMultiplicator(TimeUnit unit, TimeUnit base) {
		long value = 1;
		switch (unit) {
			case NANOSECOND: {
				break;
			}
			case MICROSECOND: {
				value *= 1000;
				break;
			}
			case MILLISECOND: {
				value *= 1000000;
				break;
			}
			case SECOND: {
				value *= 1000000000;
				break;
			}
			case HOUR: {
				value *= 1000000000 * 60 * 60;
				break;
			}
			default:
				throw new IllegalArgumentException("Unexpected value: " + unit);
		}
		// Value is now in nanoseconds
		switch (base) {
			case NANOSECOND: {
				break;
			}
			case MICROSECOND: {
				value /= 1000;
				break;
			}
			case MILLISECOND: {
				value /= 1000000;
				break;
			}
			case SECOND: {
				value /= 1000000000;
				break;
			}
			case HOUR: {
				value /= 1000000000 * 60 * 60;
				break;
			}
			default:
				throw new IllegalArgumentException("Unexpected value: " + unit);
		}
		
		return value;
	}
	
	public static Set<Package> getImportableInterfacePackages(Component component) {
		List<Port> ports = getAllPorts(component);
		return ports.stream().map(it -> getContainingPackage(
				getInterface(it))).collect(Collectors.toSet());
	}
	
	public static Set<Package> getImportableComponentPackages(Component component) {
		Set<Package> importablePackages = new LinkedHashSet<Package>();
		
		for (ComponentInstance instance : getInstances(component)) {
			Component type = getDerivedType(instance);
			Package containingPackage = getContainingPackage(type);
			importablePackages.add(containingPackage);
		}
		
		return importablePackages;
	}
	
	public static Set<Package> getImportableAnnotationPackages(Component component) {
		Set<Package> importablePackages = new LinkedHashSet<Package>();
		for (AdaptiveContractAnnotation annotation :
				ecoreUtil.getContentsOfType(component, AdaptiveContractAnnotation.class)) {
			Component monitoredComponent = annotation.getMonitoredComponent();
			Package containingPackage = getContainingPackage(monitoredComponent);
			importablePackages.add(containingPackage);
		}
		for (ScenarioContractAnnotation annotation :
				ecoreUtil.getContentsOfType(component, ScenarioContractAnnotation.class)) {
			Component monitoredComponent = annotation.getMonitoredComponent();
			Package containingPackage = getContainingPackage(monitoredComponent);
			importablePackages.add(containingPackage);
		}
		for (StateContractAnnotation annotation :
				ecoreUtil.getContentsOfType(component, StateContractAnnotation.class)) {
			StatechartDefinition contract = annotation.getContractStatechart();
			Package containingPackage = getContainingPackage(contract);
			importablePackages.add(containingPackage);
		}
		return importablePackages;
	}
	
	public static Set<Package> getImportablePackages(Component component) {
		Set<Package> importablePackages = new LinkedHashSet<Package>();
		
		importablePackages.addAll(getImportableInterfacePackages(component));
		importablePackages.addAll(getImportableComponentPackages(component));
		importablePackages.addAll(getImportableAnnotationPackages(component));
		// Expression packages manually
		importablePackages.addAll(
				javaUtil.filterIntoList(
						getImportableDeclarationPackages(component), Package.class));
		// If referenced components are in the same package
		if (isContainedByPackage(component)) {
			Package _package = getContainingPackage(component);
			importablePackages.remove(_package);
		}
		
		return importablePackages;
	}
	
	public static Set<Package> getImportablePackages(Package _package) {
		Set<Package> importablePackages = new LinkedHashSet<Package>();

		for (Component component : _package.getComponents()) {
			importablePackages.addAll(
					getImportablePackages(component));
		}
		
		return importablePackages;
	}
	
	public static Set<Package> getImportableTypeDeclarationPackages(Component component) {
		Package _package = getContainingPackage(component);
		return getImportableTypeDeclarationPackages(_package);
	}
	
	public static Set<Package> getImportableTypeDeclarationPackages(Package _package) {
		// Different functionality from importable interface and component packages...
		Set<Package> importedPackages = new LinkedHashSet<Package>();
		List<Package> importablePackages = new ArrayList<Package>();
		
		importablePackages.add(_package);
		importablePackages.addAll(_package.getImports());
		for (Package importablePackage : importablePackages) {
			List<TypeDeclaration> typeDeclarations = importablePackage.getTypeDeclarations();
			if (!typeDeclarations.isEmpty()) {
				importedPackages.add(importablePackage);
			}
		}
		
		return importedPackages;
	}
	
	public static Set<Package> getSelfAndImports(Package gammaPackage) {
		Set<Package> imports = new HashSet<Package>();
		
		imports.add(gammaPackage);
		imports.addAll(gammaPackage.getImports());
		
		return imports;
	}
	
	public static Set<Package> getComponentImports(Package gammaPackage) {
		Set<Package> imports = new HashSet<Package>();
		
		imports.addAll(gammaPackage.getImports());
		for (Component component : gammaPackage.getComponents()) {
			for (ComponentInstance componentInstance : getAllInstances(component)) {
				Component type = getDerivedType(componentInstance);
				Package referencedPackage = getContainingPackage(type);
				imports.addAll(
						getSelfAndImports(referencedPackage));
			}
		}
		
		return imports;
	}
	
	public static Set<Package> getSelfAndAllImports(Package gammaPackage) {
		Set<Package> imports = new LinkedHashSet<Package>();
		
		imports.add(gammaPackage);
		imports.addAll(getAllImports(gammaPackage));
		
		return imports;
	}
	
	public static Set<Package> getAllImports(Package gammaPackage) {
		Set<Package> imports = new LinkedHashSet<Package>();
		
		Queue<Package> packages = new LinkedList<Package>();
		packages.add(gammaPackage);
		// Queue-based recursive approach instead of a recursive function
		while (!packages.isEmpty()) {
			Package _package = packages.poll();
			List<Package> insideImports = _package.getImports();
			
			for (Package insideImport : insideImports) {
				// To counter possible inconsistent import hierarchies
				if (!imports.contains(insideImport)) {
					packages.add(insideImport);
				}
			}
			
			imports.addAll(insideImports);
		}
		
		return imports;
	}
	
	public static Set<Package> getImportsWithComponentsOrInterfacesOrTypes(Package gammaPackage) {
		Set<Package> imports = new LinkedHashSet<Package>();
		
		for (Package importedPackage : gammaPackage.getImports()) {
			if (containsComponentsOrInterfacesOrTypes(importedPackage)) {
				imports.add(importedPackage);
			}
		}
		
		return imports;
	}
	
	public static boolean containsComponentsOrInterfacesOrTypes(Package gammaPackage) {
		return !gammaPackage.getInterfaces().isEmpty() ||
				!gammaPackage.getComponents().isEmpty() ||
				!gammaPackage.getTypeDeclarations().isEmpty();
	}
	
	public static Component getFirstComponent(Package _package) {
		return _package.getComponents().get(0);
	}
	
	public static Set<Component> getAllComponents(Package parentPackage) {
		Set<Component> types = new LinkedHashSet<Component>();
		for (Package importedPackage : parentPackage.getImports()) {
			for (Component importedComponent : importedPackage.getComponents()) {
				types.add(importedComponent);
			}
		}
		for (Component siblingComponent : parentPackage.getComponents()) {
			types.add(siblingComponent);
		}
		return types;
	}
	
	public static Set<SynchronousComponent> getAllSynchronousComponents(Package parentPackage) {
		Set<SynchronousComponent> types = new LinkedHashSet<SynchronousComponent>();
		for (Component component : getAllComponents(parentPackage)) {
			if (component instanceof SynchronousComponent synchronousComponent) {
				types.add(synchronousComponent);
			}
		}
		return types;
	}
	
	public static Set<AsynchronousComponent> getAllAsynchronousComponents(Package parentPackage) {
		Set<AsynchronousComponent> types = new LinkedHashSet<AsynchronousComponent>();
		for (Component component : getAllComponents(parentPackage)) {
			if (component instanceof AsynchronousComponent asynchronousComponent) {
				types.add(asynchronousComponent);
			}
		}
		return types;
	}
	
	public static Set<StatechartDefinition> getAllStatechartComponents(Package parentPackage) {
		Set<StatechartDefinition> types = new LinkedHashSet<StatechartDefinition>();
		for (Component component : getAllSynchronousComponents(parentPackage)) {
			if (component instanceof StatechartDefinition statechart) {
				types.add(statechart);
			}
		}
		return types;
	}
	
	public static boolean areInterfacesEqual(Component lhs, Component rhs) {
		List<Port> lhsPorts = lhs.getPorts();
		List<Port> rhsPorts = rhs.getPorts();
		if (lhsPorts.size() != rhsPorts.size()) {
			return false;
		}
		for (Port lhsPort : lhsPorts) {
			if (!rhsPorts.stream().anyMatch(it -> ecoreUtil.helperEquals(lhsPort, it))) {
				return false;
			}
		}
		return true;
	}
	
	public static List<ComponentInstance> getInstances(ComponentInstance instance) {
		Component type = getDerivedType(instance);
		return getInstances(type);
	}
	
	public static List<ComponentInstance> getInstances(Component component) {
		List<ComponentInstance> instances = new ArrayList<ComponentInstance>();
		if (component instanceof AbstractAsynchronousCompositeComponent) {
			AbstractAsynchronousCompositeComponent asynchronousCompositeComponent =
					(AbstractAsynchronousCompositeComponent) component;
			for (AsynchronousComponentInstance instance : asynchronousCompositeComponent.getComponents()) {
				instances.add(instance);
			}
		}
		else if (component instanceof AsynchronousAdapter asynchronousAdapter) {
			SynchronousComponentInstance wrappedComponent = asynchronousAdapter.getWrappedComponent();
			instances.add(wrappedComponent);
		}
		else if (component instanceof AbstractSynchronousCompositeComponent) {
			AbstractSynchronousCompositeComponent synchronousCompositeComponent =
					(AbstractSynchronousCompositeComponent) component;
			for (SynchronousComponentInstance instance : synchronousCompositeComponent.getComponents()) {
				instances.add(instance);
			}
		}
		return instances;
	}
	
	public static Set<Component> getAllComponents(Component component) {
		return new LinkedHashSet<Component>(
			getAllInstances(component).stream().map(it -> getDerivedType(it))
				.toList());
	}
	
	public static Set<Component> getSelfAndAllComponents(Component component) {
		Set<Component> selfAndAllComponents = new LinkedHashSet<Component>();
		
		selfAndAllComponents.add(component);
		selfAndAllComponents.addAll(
				getAllComponents(component));
		
		return selfAndAllComponents;
	}
	
	public static List<ComponentInstance> getAllInstances(Component component) {
		List<ComponentInstance> instances = new ArrayList<ComponentInstance>();
		if (component instanceof AbstractAsynchronousCompositeComponent asynchronousCompositeComponent) {
			for (AsynchronousComponentInstance instance : asynchronousCompositeComponent.getComponents()) {
				instances.add(instance);
				AsynchronousComponent type = instance.getType();
				instances.addAll(
						getAllInstances(type));
			}
		}
		else if (component instanceof AsynchronousAdapter asynchronousAdapter) {
			SynchronousComponentInstance wrappedComponent = asynchronousAdapter.getWrappedComponent();
			instances.add(wrappedComponent);
			instances.addAll(
					getAllInstances(wrappedComponent.getType()));
		}
		else if (component instanceof AbstractSynchronousCompositeComponent) {
			AbstractSynchronousCompositeComponent synchronousCompositeComponent =
					(AbstractSynchronousCompositeComponent) component;
			for (SynchronousComponentInstance instance : synchronousCompositeComponent.getComponents()) {
				instances.add(instance);
				SynchronousComponent type = instance.getType();
				instances.addAll(
						getAllInstances(type));
			}
		}
		return instances;
	}
	
	public static List<SynchronousComponentInstance> getAllSimpleInstances(ComponentInstance instance) {
		Component type = getDerivedType(instance);
		return getAllSimpleInstances(type);
	}
	
	public static List<SynchronousComponentInstance> getAllSimpleInstances(Component component) {
		List<SynchronousComponentInstance> simpleInstances = new ArrayList<SynchronousComponentInstance>();
		if (component instanceof AbstractAsynchronousCompositeComponent) {
			AbstractAsynchronousCompositeComponent asynchronousCompositeComponent =
					(AbstractAsynchronousCompositeComponent) component;
			for (AsynchronousComponentInstance instance : asynchronousCompositeComponent.getComponents()) {
				simpleInstances.addAll(
						getAllSimpleInstances(instance));
			}
		}
		else if (component instanceof AsynchronousAdapter asynchronousAdapter) {
			SynchronousComponentInstance wrappedInstance = asynchronousAdapter.getWrappedComponent();
			if (isStatechart(wrappedInstance)) {
				simpleInstances.add(wrappedInstance);
			}
			else {
				simpleInstances.addAll(
						getAllSimpleInstances(wrappedInstance));
			}
		}
		else if (component instanceof AbstractSynchronousCompositeComponent) {
			AbstractSynchronousCompositeComponent synchronousCompositeComponent =
					(AbstractSynchronousCompositeComponent) component;
			for (SynchronousComponentInstance instance : synchronousCompositeComponent.getComponents()) {
				if (isStatechart(instance)) {
					simpleInstances.add(instance);
				}
				else {
					simpleInstances.addAll(
							getAllSimpleInstances(instance));
				}
			}
		}
		return simpleInstances;
	}
	
	public static List<AsynchronousComponentInstance> getAllAsynchronousSimpleInstances(Component component) {
		List<ComponentInstance> adapterInstances =
				getAllInstances(component).stream()
					.filter(it -> isAdapter(it))
					.collect(Collectors.toList());
		return javaUtil.filterIntoList(adapterInstances, AsynchronousComponentInstance.class);
	}
	
	public static List<AsynchronousComponentInstance> getAllScheduledInstances(Component component) {
		List<ComponentInstance> adapterInstances =
				getAllInstances(component).stream()
					.filter(it -> isAdapter(it) || it instanceof ScheduledAsynchronousCompositeComponent)
					.collect(Collectors.toList());
		return javaUtil.filterIntoList(adapterInstances, AsynchronousComponentInstance.class);
	}
	
	public static int getSchedulingIndex(AsynchronousComponentInstance instance) {
		Package _package = getContainingPackage(instance);
		Component firstComponent = getFirstComponent(_package);
		List<AsynchronousComponentInstance> scheduledInstances = getAllScheduledInstances(firstComponent);
		return scheduledInstances.indexOf(instance) + 1; // + 1 to avoid 0s
	}
	
	public static AsynchronousComponentInstance getScheduledInstance(Component component, int i) {
		List<AsynchronousComponentInstance> allScheduledInstances = getAllScheduledInstances(component);
		return allScheduledInstances.get(i - 1); // - 1 needed, see getSchedulingIndex
	}
	
	public static boolean needsScheduling(ComponentInstance instance) {
		EObject container = instance.eContainer();
		return container instanceof AsynchronousCompositeComponent &&
			!(getDerivedType(instance) instanceof AsynchronousCompositeComponent); // Scheduled or Adapter
	}
	
	public static List<ComponentInstance> getInitallyScheduledInstances(
			SchedulableCompositeComponent component) {
		List<ComponentInstance> initallyScheduledInstances = new ArrayList<ComponentInstance>();
		for (ComponentInstanceReferenceExpression instanceReference : component.getInitialExecutionList()) {
			ComponentInstance componentInstance = instanceReference.getComponentInstance(); // No child
			initallyScheduledInstances.add(componentInstance);
		}
		return initallyScheduledInstances;
	}
	
	public static List<ComponentInstance> getAllInitallyScheduledAsynchronousSimpleInstances(
			AbstractAsynchronousCompositeComponent component) {
		List<ComponentInstance> initallyScheduledInstances = new ArrayList<ComponentInstance>();
		
		if (component instanceof SchedulableCompositeComponent schedulableComponent) {
			for (ComponentInstanceReferenceExpression instanceReference :
						schedulableComponent.getInitialExecutionList()) {
				ComponentInstance componentInstance = instanceReference.getComponentInstance(); // No child
				Component subtype = getDerivedType(componentInstance);
				if (subtype instanceof SchedulableCompositeComponent) {
					initallyScheduledInstances.addAll(
						getAllAsynchronousSimpleInstances(subtype));
				}
				else { // Asynchronous adapter
					initallyScheduledInstances.add(componentInstance);
				}
			}
		}
		// No else - not recursive/transitive property
		
		return initallyScheduledInstances;
	}
	
	public static List<? extends ComponentInstance> getScheduledInstances(Component component) {
		if (component instanceof AbstractSynchronousCompositeComponent synchronousComponent) {
			return getScheduledInstances(synchronousComponent);
		}
		else if (component instanceof AbstractAsynchronousCompositeComponent asynchronousComponent) {
			return getScheduledInstances(asynchronousComponent);
		}
		else if (component instanceof AsynchronousAdapter asynchronusAdapter) {
			return List.of(asynchronusAdapter.getWrappedComponent());
		}
		throw new IllegalArgumentException("Not known component: " + component);
	}
	
	public static List<SynchronousComponentInstance> getScheduledInstances(
			AbstractSynchronousCompositeComponent component) {
		if (component instanceof CascadeCompositeComponent cascade) {
			List<ComponentInstanceReferenceExpression> executionList = cascade.getExecutionList();
			if (!executionList.isEmpty()) {
				List<SynchronousComponentInstance> instances =
						new ArrayList<SynchronousComponentInstance>();
				for (ComponentInstanceReferenceExpression instanceReference : executionList) {
					SynchronousComponentInstance componentInstance =
						(SynchronousComponentInstance) instanceReference.getComponentInstance();
					instances.add(componentInstance);
				}
				return instances;
			}
		}
		return component.getComponents();
	}
	
	public static List<AsynchronousComponentInstance> getScheduledInstances(
			AbstractAsynchronousCompositeComponent component) {
		if (component instanceof ScheduledAsynchronousCompositeComponent) {
			ScheduledAsynchronousCompositeComponent scheduledComponent =
					(ScheduledAsynchronousCompositeComponent) component;
			List<ComponentInstanceReferenceExpression> executionList = scheduledComponent.getExecutionList();
			if (!executionList.isEmpty()) {
				List<AsynchronousComponentInstance> instances =
						new ArrayList<AsynchronousComponentInstance>();
				for (ComponentInstanceReferenceExpression instanceReference : executionList) {
					AsynchronousComponentInstance componentInstance =
						(AsynchronousComponentInstance) instanceReference.getComponentInstance();
					instances.add(componentInstance);
				}
				return instances;
			}
		}
		return component.getComponents();
	}
	
//	public static List<AsynchronousComponentInstance> getAllScheduledAsynchronousSimpleInstances(
//			AbstractAsynchronousCompositeComponent component) {
//		List<AsynchronousComponentInstance> simpleInstances =
//				new ArrayList<AsynchronousComponentInstance>();
//		for (AsynchronousComponentInstance instance : getScheduledInstances(component)) {
//			if (isAdapter(instance)) {
//				simpleInstances.add(instance);
//			}
//			else {
//				AbstractAsynchronousCompositeComponent type =
//						(AbstractAsynchronousCompositeComponent) instance.getType();
//				simpleInstances.addAll(
//						getAllScheduledAsynchronousSimpleInstances(type));
//			}
//		}
//		return simpleInstances;
//	}
	
	public static List<ComponentInstanceReferenceExpression> getAllSimpleInstanceReferences(
			ComponentInstance instance) {
		Component type = getDerivedType(instance);
		return getAllSimpleInstanceReferences(type);
	}
	
	public static List<ComponentInstanceReferenceExpression> getAllSimpleInstanceReferences(Component component) {
		List<ComponentInstanceReferenceExpression> instanceReferences = new ArrayList<ComponentInstanceReferenceExpression>();
		if (component instanceof AbstractAsynchronousCompositeComponent) {
			AbstractAsynchronousCompositeComponent asynchronousCompositeComponent =
					(AbstractAsynchronousCompositeComponent) component;
			for (AsynchronousComponentInstance instance : asynchronousCompositeComponent.getComponents()) {
				if (isStatechart(instance)) {
					ComponentInstanceReferenceExpression instanceReference =
							statechartUtil.createInstanceReference(instance);
					instanceReferences.add(instanceReference);
				}
				else {
					List<ComponentInstanceReferenceExpression> childReferences = getAllSimpleInstanceReferences(instance);
					instanceReferences.addAll(
							statechartUtil.prepend(childReferences, instance));
				}
			}
		}
		else if (component instanceof AsynchronousAdapter adapter) {
			SynchronousComponentInstance instance = adapter.getWrappedComponent();
			if (isStatechart(instance)) {
				ComponentInstanceReferenceExpression instanceReference = statechartUtil.createInstanceReference(instance);
				instanceReferences.add(instanceReference);
			}
			else {
				List<ComponentInstanceReferenceExpression> childReferences = getAllSimpleInstanceReferences(instance);
				instanceReferences.addAll(
						statechartUtil.prepend(childReferences, instance));
			}
		}
		else if (component instanceof AbstractSynchronousCompositeComponent) {
			AbstractSynchronousCompositeComponent synchronousCompositeComponent =
					(AbstractSynchronousCompositeComponent) component;
			for (SynchronousComponentInstance instance : synchronousCompositeComponent.getComponents()) {
				if (isStatechart(instance)) {
					ComponentInstanceReferenceExpression instanceReference =
							statechartUtil.createInstanceReference(instance);
					instanceReferences.add(instanceReference);
				}
				else {
					List<ComponentInstanceReferenceExpression> childReferences = getAllSimpleInstanceReferences(instance);
					instanceReferences.addAll(
							statechartUtil.prepend(childReferences, instance));
				}
			}
		}
		return instanceReferences;
	}
	
	public static List<ComponentInstanceReferenceExpression> getAllScheduledInstanceReferences(Component component) {
		List<ComponentInstanceReferenceExpression> instanceReferences = new ArrayList<ComponentInstanceReferenceExpression>();
		
		if (component instanceof AsynchronousCompositeComponent compositeComponent) {
			for (AsynchronousComponentInstance instance : compositeComponent.getComponents()) {
				Component type = getDerivedType(instance);
				List<ComponentInstanceReferenceExpression> childReferences = getAllScheduledInstanceReferences(type);
				if (childReferences.isEmpty()) {
					ComponentInstanceReferenceExpression instanceReference =
							statechartUtil.createInstanceReference(instance);
					instanceReferences.add(instanceReference);
				}
				else {
					instanceReferences.addAll(
							statechartUtil.prepend(childReferences, instance));
				}
			}
		}
		
		return instanceReferences;
	}
	
	public static Collection<StatechartDefinition> getAllContainedStatecharts(Component component) {
		List<StatechartDefinition> statecharts = new ArrayList<StatechartDefinition>();
		for (SynchronousComponentInstance instance : getAllSimpleInstances(component)) {
			statecharts.add(
					getStatechart(instance));
		}
		return statecharts;
	}
	
	public static Collection<StatechartDefinition> getSelfOrAllContainedStatecharts(
			Component component) {
		if (component instanceof StatechartDefinition statechart) {
			return List.of(statechart);
		}
		return getAllContainedStatecharts(component);
	}
	
	public static List<Interface> getAllParents(Interface _interface) {
		List<Interface> interfaces = new ArrayList<Interface>();
		for (Interface parent : _interface.getParents()) {
			interfaces.addAll(
					getAllParents(parent));
		}
		interfaces.addAll(_interface.getParents());
		return interfaces;
	}
	
	public static List<Interface> getAllParentsAndSelf(Interface _interface) {
		List<Interface> interfaces = getAllParents(_interface);
		interfaces.add(_interface);
		return interfaces;
	}
	
	public static List<EventDeclaration> getAllEventDeclarations(Interface _interface) {
		List<EventDeclaration> eventDeclarations = new ArrayList<EventDeclaration>();
		List<Interface> interfaces = getAllParentsAndSelf(_interface);
		for (Interface parentInterface : interfaces) {
			eventDeclarations.addAll(parentInterface.getEvents());
		}
		return eventDeclarations;
	}
	
	public static List<Event> getAllEvents(Interface _interface) {
		return getAllEventDeclarations(_interface).stream()
				.map(it -> it.getEvent()).collect(Collectors.toList());
	}
	
	public static List<Event> getAllInternalEvents(Interface _interface) {
		return getAllEventDeclarations(_interface).stream()
				.filter(it -> it.getDirection() == EventDirection.INTERNAL)
				.map(it -> it.getEvent()).collect(Collectors.toList());
	}
	
	public static boolean isPersistent(Event event) {
		Persistency persistency = event.getPersistency();
		return persistency == Persistency.PERSISTENT;
	}
	
	public static boolean isTransient(Event event) {
		Persistency persistency = event.getPersistency();
		return persistency == Persistency.TRANSIENT;
	}
	
	public static boolean isPersistent(ParameterDeclaration parameter) {
		Event event = getContainingEvent(parameter);
		return isPersistent(event);
	}
	
	public static boolean isTransient(ParameterDeclaration parameter) {
		Event event = getContainingEvent(parameter);
		return isTransient(event);
	}
	
	public static boolean isInternal(Event event) {
		EventDirection direction = getDirection(event);
		return direction == EventDirection.INTERNAL;
	}
	
	public static EventDirection getDirection(Event event) {
		EventDeclaration eventDeclaration = ecoreUtil.getContainerOfType(event, EventDeclaration.class);
		return eventDeclaration.getDirection();
	}
	
	public static BigInteger getPriorityValue(Event event) {
		BigInteger priority = event.getPriority();
		if (priority == null) {
			return BigInteger.ZERO;
		}
		return priority;
	}
	
	public static List<ParameterDeclaration> getParametersOfTypeDefinition(
			Event event, TypeDefinition type) {
		return event.getParameterDeclarations().stream()
			.filter(it -> getTypeDefinition(it) == type)
			.collect(Collectors.toList());
	}
	
	public static int getIndexOfParametersWithSameTypeDefinition(ParameterDeclaration parameter) {
		Event event = getContainingEvent(parameter);
		TypeDefinition typeDefinition = getTypeDefinition(parameter);
		List<ParameterDeclaration> parametersOfTypeDefinition =
				getParametersOfTypeDefinition(event, typeDefinition);
		return parametersOfTypeDefinition.indexOf(parameter);
	}
	
	public static Event getContainingEvent(ParameterDeclaration parameter) {
		return (Event) parameter.eContainer();
	}
	
	public static EventDeclaration getContainingEventDeclaration(Event event) {
		return (EventDeclaration) event.eContainer();
	}
	
	public static Interface getContainingInterface(EObject object) {
		return ecoreUtil.getContainerOfType(object, Interface.class);
	}
	
	public static List<EventDeclaration> getAllEventDeclarations(Port port) {
		return getAllEventDeclarations(port.getInterfaceRealization().getInterface());
	}
	
	public static List<Event> getAllEvents(Port port) {
		return getAllEvents(port.getInterfaceRealization().getInterface());
	}
	
	public static List<Event> getInputEvents(Iterable<? extends Port> ports) {
		List<Event> events = new ArrayList<Event>();
		for (Port port : ports) {
			events.addAll(getInputEvents(port));
		}
		return events;
	}
	
	public static List<Event> getInputEvents(Port port) {
		List<Event> events = new ArrayList<Event>();
		InterfaceRealization interfaceRealization = port.getInterfaceRealization();
		Collection<EventDeclaration> allEventDeclarations = getAllEventDeclarations(port);
		RealizationMode realizationMode = interfaceRealization.getRealizationMode();
		if (realizationMode == RealizationMode.PROVIDED) {
			events.addAll(allEventDeclarations.stream()
					.filter(it -> it.getDirection() == EventDirection.IN ||
							 it.getDirection() == EventDirection.INOUT ||
							 it.getDirection() == EventDirection.INTERNAL)
					.map(it -> it.getEvent())
					.collect(Collectors.toList()));
		}
		else if (realizationMode == RealizationMode.REQUIRED) {
			events.addAll(allEventDeclarations.stream()
					.filter(it -> it.getDirection() == EventDirection.OUT ||
							 it.getDirection() == EventDirection.INOUT ||
							 it.getDirection() == EventDirection.INTERNAL)
					.map(it -> it.getEvent())
					.collect(Collectors.toList()));
		}
		return events;
	}
	
	public static boolean hasInputEvents(Port port) {
		return !getInputEvents(port).isEmpty();
	}
	
	public static List<Event> getOutputEvents(Iterable<? extends Port> ports) {
		List<Event> events = new ArrayList<Event>();
		for (Port port : ports) {
			events.addAll(getOutputEvents(port));
		}
		return events;
	}
	
	public static List<Event> getOutputEvents(Port port) {
		List<Event> events = new ArrayList<Event>();
		InterfaceRealization interfaceRealization = port.getInterfaceRealization();
		Collection<EventDeclaration> allEventDeclarations = getAllEventDeclarations(port);
		RealizationMode realizationMode = interfaceRealization.getRealizationMode();
		if (realizationMode == RealizationMode.PROVIDED) {
			events.addAll(allEventDeclarations.stream()
					.filter(it -> it.getDirection() == EventDirection.OUT ||
							 it.getDirection() == EventDirection.INOUT ||
							 it.getDirection() == EventDirection.INTERNAL)
					.map(it -> it.getEvent())
					.collect(Collectors.toList()));
		}
		if (realizationMode == RealizationMode.REQUIRED) {
			events.addAll(allEventDeclarations.stream()
					.filter(it -> it.getDirection() == EventDirection.IN ||
							 it.getDirection() == EventDirection.INOUT ||
							 it.getDirection() == EventDirection.INTERNAL)
					.map(it -> it.getEvent())
					.collect(Collectors.toList()));
		}
		return events;
	}
	
	public static boolean hasOutputEvents(Port port) {
		return !getOutputEvents(port).isEmpty();
	}
	
	public static List<Event> getInternalEvents(Iterable<? extends Port> ports) {
		List<Event> events = new ArrayList<Event>();
		for (Port port : ports) {
			events.addAll(getInternalEvents(port));
		}
		return events;
	}
	
	public static List<Event> getInternalEvents(Port port) {
		List<Event> events = new ArrayList<Event>();
		Collection<EventDeclaration> allEventDeclarations = getAllEventDeclarations(port);
		events.addAll(allEventDeclarations.stream()
				.filter(it -> it.getDirection() == EventDirection.INTERNAL)
				.map(it -> it.getEvent())
				.collect(Collectors.toList()));
		return events;
	}
	
	public static boolean hasInternalEvents(Port port) {
		return !getInternalEvents(port).isEmpty();
	}
	
	public static boolean isInputEvent(Port port, Event event) {
		return getInputEvents(port).contains(event);
	}
	
	public static boolean isOutputEvent(Port port, Event event) {
		return getOutputEvents(port).contains(event);
	}
	
	public static boolean isInternalEvent(Port port, Event event) {
		return getInternalEvents(port).contains(event);
	}
	
	public static boolean isTopInPackage(Component component) {
		Package _package = getContainingPackage(component);
		for (Component containedComponent : _package.getComponents()) {
			for (ComponentInstance componentInstance : getInstances(containedComponent)) {
				Component type = getDerivedType(componentInstance);
				if (type == component) {
					return false;
				}
			}
		}
		return true;
	}
	
	public static Set<Interface> getInterfaces(Component component) {
		return getAllPorts(component).stream()
				.map(it -> getInterface(it)).collect(Collectors.toSet());
	}
	
	public static List<Port> getAllPorts(AsynchronousAdapter wrapper) {
		List<Port> allPorts = new ArrayList<Port>(wrapper.getPorts());
		allPorts.addAll(wrapper.getWrappedComponent().getType().getPorts());
		return allPorts;
	}
	
	public static List<Port> getAllPorts(Component component) {
		if (component instanceof AsynchronousAdapter) {
			return getAllPorts((AsynchronousAdapter) component);
		}		
		return component.getPorts();
	}
	
	public static List<Port> getAllInternalPorts(Component component) {
		List<Port> allPorts = getAllPorts(component);
		return allPorts.stream().filter(it -> isInternal(it))
				.collect(Collectors.toList());
	}
	
	public static boolean hasInternalPort(Component component) {
		return !getAllInternalPorts(component).isEmpty();
	}
	
	public static List<Port> getAllPortsWithInput(Component component) {
		return getAllPorts(component).stream().filter(it -> hasInputEvents(it))
			.collect(Collectors.toList());
	}
	
	public static List<Port> getAllPortsWithOutput(Component component) {
		return getAllPorts(component).stream().filter(it -> hasOutputEvents(it))
			.collect(Collectors.toList());
	}
	
	public static List<ControlSpecification> getControlSpecifications(
			AsynchronousAdapter adapter, Object eventReference) {
		List<ControlSpecification> controlSpecifications = new ArrayList<ControlSpecification>();
		
		for (ControlSpecification controlSpecification : adapter.getControlSpecifications()) {
			SimpleTrigger trigger = controlSpecification.getTrigger();
			if (trigger instanceof AnyTrigger) {
				controlSpecifications.add(controlSpecification);
			}
			if (trigger instanceof EventTrigger eventTrigger) {
				EventReference controlEventReference = eventTrigger.getEventReference();
				if (eventReference instanceof Entry<?, ?>) { // Port-event
					List<Entry<Port, Event>> inputEvents = getInputEvents(controlEventReference);
					@SuppressWarnings("unchecked")
					Entry<Port, Event> portEvent = (Entry<Port, Event>) eventReference;
					if (inputEvents.contains(portEvent)) {
						controlSpecifications.add(controlSpecification);
					}
				}
				else if (eventReference instanceof Clock clock) { // Clock
					if (controlEventReference instanceof ClockTickReference clockTickReference) {
						if (clockTickReference.getClock() == clock) {
							controlSpecifications.add(controlSpecification);
						}
					}
				}
			}
		}
		
		return controlSpecifications;
	}
	
	public static boolean isWhenAnyRunOnce(AsynchronousAdapter adapter) {
		List<ControlSpecification> controlSpecifications = adapter.getControlSpecifications();
		for (ControlSpecification controlSpecification : controlSpecifications) {
			SimpleTrigger trigger = controlSpecification.getTrigger();
			ControlFunction controlFunction = controlSpecification.getControlFunction();
			if (trigger instanceof AnyTrigger && controlFunction == ControlFunction.RUN_ONCE) {
				return true;
			}
		}
		
		return false;
	}
	
	public static boolean isRunSpecification(AsynchronousAdapter adapter, Object eventReference) {
		List<ControlSpecification> controlSpecifications =
				getControlSpecifications(adapter, eventReference);
		
		return controlSpecifications.stream()
				.anyMatch(it -> it.getControlFunction() == ControlFunction.RUN_ONCE);
	}
	
	public static boolean isComponentResetSpecification(AsynchronousAdapter adapter, Object eventReference) {
		List<ControlSpecification> controlSpecifications =
				getControlSpecifications(adapter, eventReference);
		
		return controlSpecifications.stream()
				.anyMatch(it -> it.getControlFunction() == ControlFunction.RESET);
	}
	
	public static Collection<? extends MessageQueue> getResetQueues(
			AsynchronousAdapter adapter, Object eventReference) {
		Set<MessageQueue> resetMessageQueues = new LinkedHashSet<MessageQueue>();
		
		List<ControlSpecification> controlSpecifications =
				getControlSpecifications(adapter, eventReference);
		List<MessageQueue> messageQueues = adapter.getMessageQueues();
		
		boolean resetQueue = controlSpecifications.stream()
					.anyMatch(it -> it.getControlFunction() == ControlFunction.RESET_MESSAGE_QUEUE);
		boolean resetQueues = controlSpecifications.stream()
				.anyMatch(it -> it.getControlFunction() == ControlFunction.RESET_MESSAGE_QUEUES);
		boolean resetOtherQueues = controlSpecifications.stream()
				.anyMatch(it -> it.getControlFunction() == ControlFunction.RESET_OTHER_MESSAGE_QUEUES);
		
		for (MessageQueue messageQueue : messageQueues) {
			if (isStoredInMessageQueue(eventReference, messageQueue)) {
				if (resetQueue) {
					resetMessageQueues.add(messageQueue);
				}
				if (resetQueues) {
					resetMessageQueues.addAll(messageQueues);
				}
				if (resetOtherQueues) {
					List<MessageQueue> otherMessageQueues = new ArrayList<MessageQueue>(messageQueues);
					otherMessageQueues.remove(messageQueue);
					
					resetMessageQueues.addAll(otherMessageQueues);
				}
			}
		}
		
		return resetMessageQueues;
	}
	
	public static List<MessageQueue> getFunctioningMessageQueues(AsynchronousAdapter adapter) {
		return adapter.getMessageQueues().stream()
				.filter(it -> isFunctioning(it))
				.collect(Collectors.toList());
	}
	
	public static List<MessageQueue> getFunctioningMessageQueuesInPriorityOrder(
				AsynchronousAdapter adapter) {
		List<MessageQueue> messageQueues = getFunctioningMessageQueues(adapter);
		messageQueues.sort(
				(l, r) -> r.getPriority().compareTo(l.getPriority()));
		return messageQueues;
	}
	
	public static List<MessageQueue> getHigherPriorityQueues(MessageQueue queue) {
		AsynchronousAdapter adapter = (AsynchronousAdapter) getContainingComponent(queue);
		List<MessageQueue> queues = getFunctioningMessageQueues(adapter);
		
		queues.removeIf(it -> it.getPriority().compareTo(queue.getPriority()) <= 0);
		
		return queues;
	}
	
	public static List<MessageQueue> getStoringMessageQueues(Clock clock) {
		List<MessageQueue> queues = new ArrayList<MessageQueue>();
		
		AsynchronousAdapter adapter = ecoreUtil.getContainerOfType(clock, AsynchronousAdapter.class);
		for (MessageQueue queue : adapter.getMessageQueues()) {
			if (isStoredInMessageQueue(clock, queue)) {
				queues.add(queue);
			}
		}
		
		return queues;
	}
	
	public static boolean storesOnlyInternalEvents(MessageQueue queue) {
		List<Entry<Port, Event>> storedEvents = getStoredEvents(queue);
		return storedEvents.stream().allMatch(it -> isInternal(it.getKey()));
	}
	
	public static boolean storesOnlyNotInternalEvents(MessageQueue queue) {
		List<Entry<Port, Event>> storedEvents = getStoredEvents(queue);
		return storedEvents.stream().allMatch(it -> !isInternal(it.getKey()));
	}
	
	public static boolean storesClockTickEvents(MessageQueue queue) {
		List<Clock> storedClocks = getStoredClocks(queue);
		return !storedClocks.isEmpty();
	}
	
	public static List<Port> getStoredPorts(MessageQueue queue) {
		Collection<Port> ports = new LinkedHashSet<Port>();
		// To filter possible duplicates
		for (EventReference eventReference : getSourceEventReferences(queue)) {
			ports.addAll(
					getInputEvents(eventReference).stream()
					.map(it -> it.getKey())
					.collect(Collectors.toList()));
		}
		return List.copyOf(ports);
	}
	
	public static List<Clock> getStoredClocks(MessageQueue queue) {
		Collection<Clock> clocks = new LinkedHashSet<Clock>();
		// To filter possible duplicates
		clocks.addAll(
				getClockTickReferences(queue).stream().map(it -> it.getClock()).toList());
		return List.copyOf(clocks);
	}
	
	public static List<Entry<Port, Event>> getStoredEvents(MessageQueue queue) {
		Collection<Entry<Port, Event>> events = new LinkedHashSet<Entry<Port, Event>>();
		// To filter possible duplicates
		for (EventReference eventReference : getSourceEventReferences(queue)) {
			events.addAll(
					getInputEvents(eventReference));
		}
		return List.copyOf(events);
	}
	
	public static List<Entry<Port, Event>> getTargetEvents(MessageQueue queue) {
		Collection<Entry<Port, Event>> events = new LinkedHashSet<Entry<Port, Event>>();
		// To filter possible duplicates
		for (EventReference eventReference : getTargetEventReferences(queue)) {
			events.addAll(
					getInputEvents(eventReference));
		}
		return List.copyOf(events);
	}
	
	public static List<EventReference> getSourceEventReferences(MessageQueue queue) {
		return queue.getEventPassings().stream()
				.map(it -> it.getSource())
				.filter(it -> it != null) // Can be null due to reductions
				.collect(Collectors.toList());
	}
	
	public static List<EventReference> getTargetEventReferences(MessageQueue queue) {
		return queue.getEventPassings().stream()
				.map(it -> it.getTarget())
				.filter(it -> it != null) // Can be null due to reductions
				.collect(Collectors.toList());
	}
	
	public static EventPassing getEventPassing(MessageQueue queue, Object eventReference) {
		for (EventPassing eventPassing : queue.getEventPassings()) {
			EventReference source = eventPassing.getSource();
			if (source != null) { // Can be null due to reductions
				// Entry<Port, Event>
				if (eventReference instanceof Entry<?, ?> portEvent) {
					List<Entry<Port, Event>> inputEvents = getInputEvents(source);
					if (inputEvents.contains(portEvent)) {
						return eventPassing;
					}
				}
				// Clock
				else if (eventReference instanceof Clock clock) {
					if (source instanceof ClockTickReference clockTickReference) {
						if (clockTickReference.getClock() == clock) {
							return eventPassing;
						}
					}
				}
			}
		}
		throw new IllegalArgumentException("Not found event passing: " + eventReference);
	}
	
	public static boolean isEventPassingCompatible(Port source, Port target) {
		List<Event> sourceInputEvents = StatechartModelDerivedFeatures.getInputEvents(source);
		List<Event> targetInputEvents = StatechartModelDerivedFeatures.getInputEvents(target);
		
		boolean isAcceptable = sourceInputEvents.size() == targetInputEvents.size();
		for (int i = 0; i < sourceInputEvents.size() && isAcceptable; i++) {
			Event sourceEvent = sourceInputEvents.get(i);
			Event targetEvent = targetInputEvents.get(i);
			
			isAcceptable = isEventPassingCompatible(sourceEvent, targetEvent);
		}
		
		return isAcceptable; 
	}

	public static boolean isEventPassingCompatible(Event source, Event target) {
		List<ParameterDeclaration> sourceParameters = source.getParameterDeclarations();
		List<ParameterDeclaration> targetParameters = target.getParameterDeclarations();
		boolean isAcceptable = sourceParameters.size() == targetParameters.size();
		if (isAcceptable) {
			for (int j = 0; j < sourceParameters.size() && isAcceptable; j++) {
				ParameterDeclaration sourceParameter = sourceParameters.get(j);
				ParameterDeclaration targetParameter = targetParameters.get(j);
				
				TypeDefinition sourceType = StatechartModelDerivedFeatures.getTypeDefinition(sourceParameter);
				TypeDefinition targetType = StatechartModelDerivedFeatures.getTypeDefinition(targetParameter);

				isAcceptable = ecoreUtil.helperEquals(sourceType, targetType);
			}
		}
		return isAcceptable;
	}
	
	public static EventReference getTargetEventReference(MessageQueue queue, Object eventReference) {
		EventPassing eventPassing = getEventPassing(queue, eventReference);
		EventReference target = eventPassing.getTarget();
		if (target != null) {
			return target;
		}
		else {
			EventReference source = eventPassing.getSource();
			return source;
		}
	}
	
	public static Entry<Port, Event> getTargetPortEvent(MessageQueue queue, Object eventReference) {
		EventReference target = getTargetEventReference(queue, eventReference);
		if (target instanceof ClockTickReference) {
			return null; // We cannot forward anything in this case
		}
		else if (target instanceof AnyPortEventReference anyPortEventReference) {
			@SuppressWarnings("unchecked")
			Entry<Port, Event> sourcePortEvent = (Entry<Port, Event>) eventReference;
			Port sourcePort = sourcePortEvent.getKey();
			Event sourceEvent = sourcePortEvent.getValue();
			
			Port targetPort = anyPortEventReference.getPort();
			if (!isEventPassingCompatible(sourcePort, targetPort)) {
				throw new IllegalArgumentException("Not the same interface: " + targetPort);
			}
			
			List<Event> sourceEvents = getInputEvents(sourcePort);
			int index = sourceEvents.indexOf(sourceEvent);
			List<Entry<Port, Event>> targetEventIds = getInputEvents(target);
			return targetEventIds.get(index);
		}
		else if (target instanceof PortEventReference portEventReference) {
			Port port = portEventReference.getPort();
			Event targetEvent = portEventReference.getEvent();
			return new SimpleEntry<Port, Event>(port, targetEvent);
		}
		throw new IllegalArgumentException("Not known target: " + eventReference);
	}
	
	public static List<EventReference> getSourceAndTargetEventReferences(MessageQueue queue) {
		List<EventReference> eventReferences = new ArrayList<EventReference>();
		for (EventPassing eventPassing : queue.getEventPassings()) {
			EventReference source = eventPassing.getSource();
			eventReferences.add(source);
			EventReference target = eventPassing.getTarget();
			if (target != null) {
				eventReferences.add(target);
			}
		}
		return eventReferences;
	}
	
	public static List<ClockTickReference> getClockTickReferences(MessageQueue queue) {
		List<ClockTickReference> eventReferences = new ArrayList<ClockTickReference>();
		for (EventPassing eventPassing : queue.getEventPassings()) {
			EventReference source = eventPassing.getSource();
			if (source instanceof ClockTickReference clockTickReference) {
				eventReferences.add(clockTickReference);
			}
		}
		return eventReferences;
	}
	
	public static int getEventId(MessageQueue queue, Clock clock) {
		List<Entry<Port, Event>> storedEvents = getStoredEvents(queue);
		int size = storedEvents.size();
		
		List<ClockTickReference> clockTickEventPassings = getClockTickReferences(queue);
		ClockTickReference reference = javaUtil.getOnlyElement(
				clockTickEventPassings.stream().filter(it -> it.getClock() == clock).toList());
		int index = clockTickEventPassings.indexOf(reference) + 1; // Starts from event size + 1
		
		return size + index;
	}
	
	public static int getEventId(MessageQueue queue, Entry<Port, Event> portEvent) {
		List<Entry<Port, Event>> storedEvents = getStoredEvents(queue);
		return storedEvents.indexOf(portEvent) + 1; // Starts from 1, 0 is the "empty cell"
	}
	
	public static int getMinEventId(MessageQueue queue) {
		return 1; // Starts from 1, size is the max
	}
	
	public static int getMaxEventId(MessageQueue queue) {
		List<Entry<Port, Event>> storedEvents = getStoredEvents(queue);
		return storedEvents.size(); // Starts from 1, size is the max
	}
	
	public static List<Integer> getEventIdsOfNonInternalEvents(MessageQueue queue) {
		return getEventIds(queue,
				it -> !isInternal(it));
	}
	
	public static List<Integer> getEventIdsOfPorts(MessageQueue queue, Collection<? extends Port> ports) {
		List<Port> asynchronousSimplePorts = getAllBoundAsynchronousSimplePorts(ports);
		
		return getEventIds(queue,
				it -> asynchronousSimplePorts.contains(it));
	}
	
	public static List<Integer> getEventIds(MessageQueue queue, Predicate<Port> isConsideredPort) {
		List<Integer> ids = new ArrayList<Integer>();
		
		List<Entry<Port, Event>> storedEvents = getStoredEvents(queue);
		int size = storedEvents.size();
		for (int i = 0; i < size; i++) {
			Entry<Port, Event> storedEvent = storedEvents.get(i);
			Port port = storedEvent.getKey();
			if (isConsideredPort.test(port)) {
				ids.add(
					getEventId(queue, storedEvent)); // Starts from 1, size is the max
			}
		}
		return ids;
	}
	
	public static Entry<Port, Event> getEvent(MessageQueue queue, int eventId) {
		List<Entry<Port,Event>> storedEvents = getStoredEvents(queue);
		return storedEvents.get(eventId - 1); // Starts from 1, 0 is the "empty cell"
	}
	
	public static boolean isStoredInMessageQueue(Object eventReference, MessageQueue queue) {
		if (eventReference instanceof Entry<?, ?>) {
			List<Entry<Port, Event>> storedEvents = getStoredEvents(queue);
			@SuppressWarnings("unchecked")
			Entry<Port, Event> portEvent = (Entry<Port, Event>) eventReference;
			return storedEvents.contains(portEvent);
		}
		if (eventReference instanceof Clock clock) {
			List<Clock> storedClocks = getStoredClocks(queue);
			return storedClocks.contains(clock);
		}
		throw new IllegalArgumentException("Not known event reference: " + eventReference);
	}
	
	public static boolean isTargetedInMessageQueue(
			Entry<Port, Event> portEvent, MessageQueue queue) {
		List<Entry<Port, Event>> targetEvents = getTargetEvents(queue);
		return targetEvents.contains(portEvent);
	}
	
	public static int countAssignedMessageQueues(
			Entry<Port, Event> portEvent, AsynchronousAdapter adapter) {
		int count = 0;
		for (MessageQueue queue : adapter.getMessageQueues()) {
			if (isStoredInMessageQueue(portEvent, queue)) {
				++count;
			}
		}
		return count;
	}
	
	public static int countTargetingMessageQueues(
			Entry<Port, Event> portEvent, AsynchronousAdapter adapter) {
		int count = 0;
		for (MessageQueue queue : adapter.getMessageQueues()) {
			if (isTargetedInMessageQueue(portEvent, queue)) {
				++count;
			}
		}
		return count;
	}
	
	public static boolean isStoredInMessageQueue(
			Entry<Port, Event> portEvent, AsynchronousAdapter adapter) {
		return adapter.getMessageQueues().stream()
				.anyMatch(it -> isStoredInMessageQueue(portEvent, it));
	}
	
	public static boolean isStoredInMessageQueue(Clock clock, MessageQueue queue) {
		for (EventReference eventReference : getSourceEventReferences(queue)) {
			if (eventReference instanceof ClockTickReference clockTickReference) {
				if (clockTickReference.getClock() == clock) {
					return true;
				}
			}
		}
		return false;
	}
	
	public static boolean isStoredInMessageQueue(Clock clock, AsynchronousAdapter adapter) {
		return adapter.getMessageQueues().stream()
				.anyMatch(it -> isStoredInMessageQueue(clock, it));
	}
	
	public static boolean isEnvironmental(MessageQueue queue,
			Collection<? extends Port> systemPorts) {
		if (!storesOnlyNotInternalEvents(queue)) {
			return false;
		}
		if (storesClockTickEvents(queue)) {
			return false;
		}
		List<Port> topBoundPorts = getStoredEvents(queue).stream()
				.map(it -> getBoundTopComponentPort(it.getKey())).collect(Collectors.toList());
		return systemPorts.containsAll(topBoundPorts);
	}
	
	public static boolean isFunctioning(MessageQueue queue) {
		Expression capacity = queue.getCapacity();
		return evaluator.evaluateInteger(capacity) > 0;
	}
	
	public static List<Entry<Port, Event>> getInputEvents(EventReference eventReference) {
		List<Entry<Port, Event>> events = new ArrayList<Entry<Port, Event>>();
		if (eventReference instanceof PortEventReference portEventReference) {
			Port port = portEventReference.getPort();
			Event event = portEventReference.getEvent();
			List<Event> inputEvents = getInputEvents(port);
			if (inputEvents.contains(event)) {
				events.add(
						new SimpleEntry<Port, Event>(port, event));
			}
		}
		else if (eventReference instanceof AnyPortEventReference anyPortEventReference) {
			Port port = anyPortEventReference.getPort();
			for (Event inputEvent : getInputEvents(port)) {
				events.add(
						new SimpleEntry<Port, Event>(port, inputEvent));
			}
		}
		else if (eventReference instanceof ClockTickReference) {
			// No op
		}
		else {
			throw new IllegalArgumentException("Not supported event reference: " + eventReference);
		}
		return events;
	}
	
	public static List<Entry<Port, Event>> getTriggeringInputEvents(StatechartDefinition statechart) {
		List<Entry<Port, Event>> events = new ArrayList<Entry<Port, Event>>();
		
		for (Transition transition : statechart.getTransitions()) {
			events.addAll(
					getTriggeringInputEvents(transition));
		}
		
		return events;
	}

	private static List<Entry<Port, Event>> getTriggeringInputEvents(Transition transition) {
		List<Entry<Port, Event>> events = new ArrayList<Entry<Port, Event>>();
		
		Trigger trigger = transition.getTrigger();
		if (trigger != null) {
			List<EventReference> eventReferences = ecoreUtil.getSelfAndAllContentsOfType(trigger, EventReference.class);
			for (EventReference eventReference : eventReferences) {
				events.addAll(
						getInputEvents(eventReference));
			}
		}
		
		return events;
	}
	
	public static List<Event> getInputEvents(Component component) {
		return getInputEvents(
				getAllPorts(component));
	}
	
	public static List<Event> getOutputEvents(Component component) {
		return getOutputEvents(
				getAllPorts(component));
	}
	
	public static Port getBoundCompositePort(Port port) {
		Package _package = getContainingPackage(port);
		List<PortBinding> portBindings = ecoreUtil.getAllContentsOfType(_package, PortBinding.class);
		for (PortBinding portBinding : portBindings) {
			InstancePortReference instancePortReference = portBinding.getInstancePortReference();
			if (instancePortReference.getPort() == port) {
				return portBinding.getCompositeSystemPort();
			}
		}
		return null;
	}
	public static boolean hasBoundCompositePort(Port port) {
		return getBoundCompositePort(port) != null;
	}
	
	public static Collection<PortBinding> getPortBindings(Port port) {
		EObject component = port.eContainer();
		List<PortBinding> portBindings = new ArrayList<PortBinding>();
		if (component instanceof CompositeComponent compositeComponent) {
			for (PortBinding portBinding : compositeComponent.getPortBindings()) {
				if (portBinding.getCompositeSystemPort() == port) {
					portBindings.add(portBinding);
				}
			}
		}		
		return portBindings;
	}
	
	public static List<Port> getAllBoundSimplePorts(Component component) {
		List<Port> simplePorts = new ArrayList<Port>();
		for (Port port : getAllPorts(component)) {
			simplePorts.addAll(
					getAllBoundSimplePorts(port));
		}
		// Note that one port can be in the list multiple times iff the component is NOT unfolded
		return simplePorts;
	}
	
	public static List<Port> getAllBoundSimplePorts(Port port) {
		List<Port> simplePorts = new ArrayList<Port>();
		Component component = getContainingComponent(port);
		if (component instanceof StatechartDefinition) {
			simplePorts.add(port);
		}
		else if (component instanceof CompositeComponent composite) {
			for (PortBinding portBinding : composite.getPortBindings()) {
				if (portBinding.getCompositeSystemPort() == port) {
					// Makes sense only if the containment hierarchy is a tree structure
					InstancePortReference instancePortReference = portBinding.getInstancePortReference();
					simplePorts.addAll(
						getAllBoundSimplePorts(
							instancePortReference.getPort()));
				}
			}
		}
		// Note that one port can be in the list multiple times iff the component is NOT unfolded
		return simplePorts;
	}
	
	public static Entry<List<ComponentInstance>, Port> getBoundSimplePort(Port port) {
		Component component = getContainingComponent(port);
		if (component instanceof StatechartDefinition) {
			List<ComponentInstance> instances = new ArrayList<ComponentInstance>();
			return new SimpleEntry<
					List<ComponentInstance>, Port>(instances, port);
		}
		else if (component instanceof AsynchronousAdapter) {
			return null; // Not bound to statechart port
		}
		else if (component instanceof CompositeComponent composite) {
			for (PortBinding portBinding : composite.getPortBindings()) {
				if (portBinding.getCompositeSystemPort() == port) { // Returning only the first one
					// Makes sense only if the containment hierarchy is a tree structure
					InstancePortReference instancePortReference = portBinding.getInstancePortReference();
					ComponentInstance instance = instancePortReference.getInstance();
					Port subport = instancePortReference.getPort();
					
					Entry<List<ComponentInstance>, Port> sub = getBoundSimplePort(subport);
					if (sub == null) {
						return null;
					}
					
					List<ComponentInstance> instances = sub.getKey();
					//
					if (isAdapter(instance)) {
						AsynchronousAdapter adapter = (AsynchronousAdapter) getDerivedType(instance);
						SynchronousComponentInstance adaptedInstance = adapter.getWrappedComponent();
						
						instances.add(0, adaptedInstance);
					}
					//
					instances.add(0, instance);
					
					return sub;
				}
			}
		}
		return null; // Not bound to statechart port
	}
	
	public static List<Port> getAllBoundAsynchronousSimplePorts(AsynchronousComponent component) {
		List<Port> simplePorts = new ArrayList<Port>();
		for (Port port : getAllPorts(component)) {
			simplePorts.addAll(
					getAllBoundAsynchronousSimplePorts(port));
		}
		return simplePorts;
	}
	
	public static List<Port> getAllBoundAsynchronousSimplePorts(Port port) {
		List<Port> simplePorts = new ArrayList<Port>();
		Component component = getContainingComponent(port);
		if (component instanceof AbstractAsynchronousCompositeComponent composite) {
			for (PortBinding portBinding : composite.getPortBindings()) {
				if (portBinding.getCompositeSystemPort() == port) {
					// Makes sense only if the containment hierarchy is a tree structure
					InstancePortReference instancePortReference = portBinding.getInstancePortReference();
					simplePorts.addAll(
						getAllBoundAsynchronousSimplePorts(
							instancePortReference.getPort()));
				}
			}
		}
		else {
			// If it is an asynchronous adapter or synchronous component, we "return"
			// If 'port' is contained by a synchronous component, we "return" right away,
			// even if that component is not contained by any asynchronous components
			simplePorts.add(port);
		}
		// Note that one port can be in the list multiple times iff the component is NOT unfolded
		return simplePorts;
	}
	
	public static List<Port> getAllBoundAsynchronousSimplePorts(Collection<? extends Port> ports) {
		List<Port> simplePorts = new ArrayList<Port>();
		
		for (Port port : ports) {
			simplePorts.addAll(
					getAllBoundAsynchronousSimplePorts(port));
		}
		
		return simplePorts;
	}
	
	public static boolean isTopComponentPort(Port port) {
		Port boundTopComponentPort = getBoundTopComponentPort(port);
		return boundTopComponentPort == port;
	}
	
	public static Port getBoundTopComponentPort(Port port) {
		Package _package = getContainingPackage(port);
		List<PortBinding> portBindings = ecoreUtil.getAllContentsOfType(_package, PortBinding.class);
		for (PortBinding portBinding : portBindings) {
			if (portBinding.getInstancePortReference().getPort() == port) {
				Port systemPort = portBinding.getCompositeSystemPort();
				// Correct as even broadcast ports cannot be bound to multiple system ports (would be unnecessary)
				return getBoundTopComponentPort(systemPort);
			}
		}
		return port;
	}
	
	public static List<Port> getPortsConnectedViaChannel(Port port) {
		Package _package = getContainingPackage(port);
		List<Channel> channels = ecoreUtil.getAllContentsOfType(_package, Channel.class);
		channels.addAll(ecoreUtil.getAllContentsOfType(_package, BroadcastChannel.class));
		for (Channel channel : channels) {
			Port providedPort = channel.getProvidedPort().getPort();
			List<Port> requiredPorts = getRequiredPorts(channel).stream()
					.map(it -> it.getPort()).collect(Collectors.toList());
			if (port == providedPort) {
				return requiredPorts;
			}
			if (requiredPorts.contains(port)) {
				return List.of(providedPort);
			}
		}
		return Collections.emptyList();
	}
	
	public static List<Port> getAllConnectedAsynchronousSimplePorts(Port port) {
		List<Port> portsConnectedViaChannel = new ArrayList<Port>();
		Port actualPort = port;
		while (actualPort != null /* Broadcast ports can go through multiple levels */) {
			portsConnectedViaChannel.addAll(getPortsConnectedViaChannel(actualPort));
			actualPort = getBoundCompositePort(actualPort);
		}
		List<Port> asynchronousSimplePorts = new ArrayList<Port>();
		for (Port portConnectedViaChannel : portsConnectedViaChannel) {
			asynchronousSimplePorts.addAll(
					getAllBoundAsynchronousSimplePorts(portConnectedViaChannel));
		}
		return asynchronousSimplePorts;
	}
	
	public static boolean isInChannel(Port port) {
		Package _package = getContainingPackage(port);
		List<Channel> channels = ecoreUtil.getAllContentsOfType(_package, Channel.class);
		channels.addAll(ecoreUtil.getAllContentsOfType(_package, BroadcastChannel.class));
		for (Channel channel : channels) {
			if (channel.getProvidedPort().getPort() == port ||
					getRequiredPorts(channel).stream().anyMatch(it -> it.getPort() == port)) {
				return true;
			}
		}
		List<PortBinding> portBindings = ecoreUtil.getAllContentsOfType(_package, PortBinding.class);
		for (PortBinding portBinding : portBindings) {
			if (portBinding.getInstancePortReference().getPort() == port) {
				Port systemPort = portBinding.getCompositeSystemPort();
				if (isInChannel(systemPort)) {
					return true;
				}
			}
		}
		return false;
	}
	
	public static List<InstancePortReference> getRequiredPorts(Channel channel) {
		if (channel instanceof SimpleChannel simpleChannel) {
			return Collections.singletonList(simpleChannel.getRequiredPort());
		}
		if (channel instanceof BroadcastChannel broadcastChannel) {
			return Collections.unmodifiableList(broadcastChannel.getRequiredPorts());
		}
		throw new IllegalArgumentException("Not known channel type: " + channel);
	}
	
	public static boolean equals(InstancePortReference p1, InstancePortReference p2) {
		return p1.getInstance() == p2.getInstance() && p1.getPort() == p2.getPort();
	}
	
	public static Set<Port> getUnusedPorts(ComponentInstance instance) {
		Component container = (CompositeComponent) getContainingComponent(instance);
		Component type = StatechartModelDerivedFeatures.getDerivedType(instance);
		
		Set<Port> usedPorts = ecoreUtil.getAllContentsOfType(
				container, InstancePortReference.class).stream()
				.filter(it -> it.getInstance() == instance)
				.map(it -> it.getPort()).collect(Collectors.toSet());
		//
		Set<Port> unusedPorts = new HashSet<Port>(
				getAllPorts(type));
		unusedPorts.removeAll(usedPorts);
		unusedPorts.removeAll(
				getAllInternalPorts(type)); // Internal ports are always used...
		unusedPorts.addAll(
				getUnusedInternalPorts(type)); // Except if no internal event is raised
		
		return unusedPorts;
	}
	
	public static Set<Port> getUnusedInternalPorts(ComponentInstance instance) {
		Component type = StatechartModelDerivedFeatures.getDerivedType(instance);
		return getUnusedInternalPorts(type);
	}

	private static Set<Port> getUnusedInternalPorts(Component type) {
		List<Port> ports = getAllPorts(type);
		return ports.stream()
				.filter(it -> isInternal(it) && isMappableToInputPort(it)) // No raised events
				.collect(Collectors.toSet());
	}
	
	public static EventSource getEventSource(EventTrigger eventTrigger) {
		EventReference eventReference = eventTrigger.getEventReference();
		return getEventSource(eventReference);
	}
	
	public static EventSource getEventSource(EventReference eventReference) {
		if (eventReference instanceof PortEventReference portEventReference) {
			return portEventReference.getPort();
		}
		if (eventReference instanceof AnyPortEventReference anyPortEventReference) {
			return anyPortEventReference.getPort();
		}
		if (eventReference instanceof ClockTickReference clockTickReference) {
			return clockTickReference.getClock();
		}
		if (eventReference instanceof TimeoutEventReference timeoutEventReference) {
			return timeoutEventReference.getTimeout();
		}
		throw new IllegalArgumentException("Not known type: " + eventReference);
	}
	
	public static Component getDerivedType(ComponentInstance instance) {
		if (instance instanceof SynchronousComponentInstance synchronousInstance) {
			return synchronousInstance.getType();
		}
		if (instance instanceof AsynchronousComponentInstance asynchronousInstance) {
			return asynchronousInstance.getType();
		}
		throw new IllegalArgumentException("Not known type: " + instance);
	}
	
	public static List<? extends ComponentInstance> getContainedComponents(Component component) {
		if (component instanceof CompositeComponent composite) {
			return getDerivedComponents(composite);
		}
		if (component instanceof AsynchronousAdapter adapter) {
			return List.of(
					adapter.getWrappedComponent());
		}
		if (component instanceof StatechartDefinition) {
			return List.of();
		}
		throw new IllegalArgumentException("Not known type: " + component);
	}
	
	public static List<? extends ComponentInstance> getDerivedComponents(CompositeComponent composite) {
		if (composite instanceof AbstractSynchronousCompositeComponent synchronousCompositeComponent) {
			return synchronousCompositeComponent.getComponents();
		}
		if (composite instanceof AbstractAsynchronousCompositeComponent asynchronousCompositeComponent) {
			return asynchronousCompositeComponent.getComponents();
		}
		throw new IllegalArgumentException("Not known type: " + composite);
	}
	
	@SuppressWarnings("unchecked")
	public static List<ComponentInstance> getModifiableDerivedComponents(CompositeComponent composite) {
		return (List<ComponentInstance>) getDerivedComponents(composite);
	}
	
    public static boolean isTimed(Component component) {
    	if (component instanceof StatechartDefinition statechart) {
    		return statechart.getTimeoutDeclarations().size() > 0;
    	}
    	else if (component instanceof AbstractSynchronousCompositeComponent composite) {
    		return composite.getComponents().stream().anyMatch(it -> isTimed(it.getType()));
    	}
    	else if (component instanceof AsynchronousAdapter adapter) {
    		List<Clock> clocks = adapter.getClocks();
    		SynchronousComponent type = adapter.getWrappedComponent().getType();
			return isTimed(type) || !clocks.isEmpty();
    	}
    	else if (component instanceof AbstractAsynchronousCompositeComponent composite) {
    		return composite.getComponents().stream().anyMatch(it -> isTimed(it.getType()));
    	}
		throw new IllegalArgumentException("Not known component: " + component);
    }
	
    public static boolean isSynchronous(Component component) {
    	return component instanceof SynchronousComponent;
    }
    
    public static boolean isAsynchronous(Component component) {
    	return component instanceof AsynchronousComponent;
    }
    
    public static boolean isAdapter(Component component) {
    	return component instanceof AsynchronousAdapter;
    }
    
    public static boolean isStatechart(Component component) {
    	return component instanceof StatechartDefinition;
    }
    
    public static boolean isSynchronousStatechart(Component component) {
    	return component instanceof SynchronousStatechartDefinition;
    }
    
    public static boolean isAsynchronousStatechart(Component component) {
    	return component instanceof AsynchronousStatechartDefinition;
    }
	
    public static boolean isCascade(ComponentInstance instance) {
    	Component type = getDerivedType(instance);
		if (type instanceof StatechartDefinition) {
    		// Statecharts are cascade if contained by cascade composite components
    		return instance.eContainer() instanceof CascadeCompositeComponent;
   		}
   		return type instanceof CascadeCompositeComponent;
    }
    
    public static boolean isSynchronous(ComponentInstance instance) {
    	return isSynchronous(getDerivedType(instance));
    }
    
    public static boolean isAsynchronous(ComponentInstance instance) {
    	return isAsynchronous(getDerivedType(instance));
    }
    
    public static boolean isAdapter(ComponentInstance instance) {
    	return isAdapter(getDerivedType(instance));
    }
    
    public static boolean isStatechart(ComponentInstance instance) {
    	return isStatechart(getDerivedType(instance));
    }
    
    public static boolean isAsynchronousStatechart(ComponentInstance instance) {
    	return isAsynchronousStatechart(getDerivedType(instance));
    }
    
    public static StatechartDefinition getStatechart(ComponentInstance instance) {
    	return (StatechartDefinition) getDerivedType(instance);
    }
    
	public static boolean needsWrapping(Component component) {
		if (component instanceof AsynchronousAdapter adapter) {
			return !isSimplifiable(adapter);
		}
		return isStatechart(component);
	}
    
	public static String getWrapperInstanceName(Component component) {
		String name = component.getName();
		// The same as in Namings.getComponentClassName
		return Character.toUpperCase(name.charAt(0)) + name.substring(1);
	}
    
    public static boolean isSimplifiable(AsynchronousAdapter adapter) {
    	// Internal ports might induce multiple messages in message queues
    	if (hasInternalPort(adapter)) {
    		return false;
    	}
    	
    	List<MessageQueue> messageQueues = adapter.getMessageQueues();
		if (messageQueues.size() != 1) {
			return false;
		}
		// The capacity (and priority) do not matter, as they are from the environment
		// The method should check whether all port-events are contained
		List<Clock> clocks = adapter.getClocks();
		if (!clocks.isEmpty()) {
			return false;
		}
		List<ControlSpecification> controlSpecifications = adapter.getControlSpecifications();
		if (controlSpecifications.size() != 1) {
			return false;
		}
		// If this is the case, back-annotation will not work if we consider this simplifiable
		SynchronousComponentInstance wrappedComponent = adapter.getWrappedComponent();
		SynchronousComponent type = wrappedComponent.getType();
		if (type.getPorts().isEmpty()) {
			return false;
		}
		
		ControlSpecification controlSpecification = controlSpecifications.get(0);
		Trigger trigger = controlSpecification.getTrigger();
		ControlFunction controlFunction = controlSpecification.getControlFunction();
		return trigger instanceof AnyTrigger && controlFunction == ControlFunction.RUN_ONCE;
    }
	
	public static int getLevel(StateNode stateNode) {
		if (isTopRegion(
				getParentRegion(stateNode))) {
			return 1;
		}
		else {
			return getLevel(
					getParentState(stateNode)) + 1;
		}
	}
	
	public static List<Transition> getNonTrappingOutgoingTransitions(StateNode node) {
		List<Transition> nonTrappingOutgoingTransitions = new ArrayList<Transition>();
		for (Transition transition : getOutgoingTransitions(node)) {
			StateNode target = transition.getTargetState();
			List<Transition> outgoingTransitions = getOutgoingTransitions(target);
			if (!outgoingTransitions.isEmpty()) {
				nonTrappingOutgoingTransitions.add(transition);
			}
		}
		return nonTrappingOutgoingTransitions;
	}
	
	public static List<Transition> getOutgoingTransitions(StateNode node) {
		StatechartDefinition statechart = getContainingStatechart(node);
		return statechart.getTransitions().stream().filter(it -> it.getSourceState() == node)
				.collect(Collectors.toList());
	}
	
	public static List<Transition> getAllOutgoingTransitions(StateNode node) {
		List<StateNode> allStateNodes = ecoreUtil
				.getSelfAndAllContentsOfType(node, StateNode.class);
		StatechartDefinition statechart = getContainingStatechart(node);
		return statechart.getTransitions().stream()
				.filter(it -> allStateNodes.contains(it.getSourceState()))
				.collect(Collectors.toList());
	}
	
	public static Transition getOutgoingTransition(StateNode node) {
		List<Transition> outgoingTransitions = getOutgoingTransitions(node);
		return javaUtil.getOnlyElement(outgoingTransitions);
	}
	
	public static Collection<Transition> getOutgoingTransitionsOfAncestors(StateNode node) {
		Set<Transition> outgoingTransitionsOfAncestors = new LinkedHashSet<Transition>();
		List<State> ancestors = getAncestors(node);
		for (State ancestor : ancestors) {
			outgoingTransitionsOfAncestors.addAll(
					getOutgoingTransitions(ancestor));
		}
		return outgoingTransitionsOfAncestors;
	}
	
	public static List<Transition> getOutgoingTransitionsUntilState(StateNode node) {
		List<Transition> transitions = new ArrayList<Transition>();
		
		List<Transition> outgoingTransitions = getOutgoingTransitions(node);
		transitions.addAll(outgoingTransitions);
		
		for (Transition outgoingTransition : outgoingTransitions) {
			StateNode target = outgoingTransition.getTargetState();
			if (!isState(target)) {
				transitions.addAll(
						getOutgoingTransitionsUntilState(target));
			}
		}
		
		return transitions;
	}
	
	public static List<Transition> getIncomingTransitions(StateNode node) {
		StatechartDefinition statechart = getContainingStatechart(node);
		return statechart.getTransitions().stream().filter(it -> it.getTargetState() == node)
				.collect(Collectors.toList());
	}
	
	public static List<Transition> getAllIncomingTransitions(StateNode node) {
		List<StateNode> allStateNodes = ecoreUtil
				.getSelfAndAllContentsOfType(node, StateNode.class);
		StatechartDefinition statechart = getContainingStatechart(node);
		return statechart.getTransitions().stream()
				.filter(it -> allStateNodes.contains(it.getTargetState()))
				.collect(Collectors.toList());
	}
	
	public static Transition getIncomingTransition(StateNode node) {
		List<Transition> incomingTransitions = getIncomingTransitions(node);
		return javaUtil.getOnlyElement(incomingTransitions);
	}
	
	public static List<Transition> getLoopTransitions(StateNode node) {
		List<Transition> loopTransitions = new ArrayList<Transition>();
		loopTransitions.addAll(
				getIncomingTransitions(node));
		loopTransitions.retainAll(
				getOutgoingTransitions(node));
		return loopTransitions;
	}
	
	public static Transition getLoopTransition(StateNode node) {
		List<Transition> loopTransitions = getLoopTransitions(node);
		return javaUtil.getOnlyElement(loopTransitions);
	}
	
	public static Collection<StateNode> getAllStateNodes(CompositeElement compositeElement) {
		Set<StateNode> stateNodes = new LinkedHashSet<StateNode>();
		for (Region region : compositeElement.getRegions()) {
			for (StateNode stateNode : region.getStateNodes()) {
				stateNodes.add(stateNode);
				if (stateNode instanceof State state) {
					stateNodes.addAll(
							getAllStateNodes(state));
				}
			}
		}
		return stateNodes;
	}
	
	public static Collection<State> getAllStates(CompositeElement compositeElement) {
		Set<State> states = new LinkedHashSet<State>();
		for (StateNode stateNode : getAllStateNodes(compositeElement)) {
			if (stateNode instanceof State state) {
				states.add(state);
			}
		}
		return states;
	}
	
	public static Collection<State> getAllStates(Region region) {
		Set<State> states = new LinkedHashSet<State>();
		for (StateNode stateNode : region.getStateNodes()) {
			if (stateNode instanceof State state) {
				states.add(state);
				states.addAll(
						getAllStates(state));
			}
		}
		return states;
	}
	
	public static List<State> getStates(Region region) {
		List<State> states = new ArrayList<State>();
		for (StateNode stateNode : region.getStateNodes()) {
			if (stateNode instanceof State state) {
				states.add(state);
			}
		}
		return states;
	}
	
	public static List<PseudoState> getPseudoStates(Region region) {
		List<PseudoState> pseudoStates = new ArrayList<PseudoState>();
		for (StateNode stateNode : region.getStateNodes()) {
			if (stateNode instanceof PseudoState pseudoState) {
				pseudoStates.add(pseudoState);
			}
		}
		return pseudoStates;
	}
	
	public static Collection<StateNode> getAllStateNodes(Region region) {
		List<StateNode> states = new ArrayList<StateNode>();
		TreeIterator<Object> allContents = EcoreUtil.getAllContents(region, true);
		while (allContents.hasNext()) {
			Object next = allContents.next();
			if (next instanceof StateNode stateNode) {
				states.add(stateNode);
			}
		}
		return states;
	}
	
	public static Collection<Region> getAllRegions(EObject node) {
		if (node instanceof CompositeElement state) {
			return getAllRegions(state);
		}
		return List.of();
	}
	
	public static Collection<Region> getAllRegions(CompositeElement compositeElement) {
		Set<Region> regions = new LinkedHashSet<Region>(compositeElement.getRegions());
		for (State state : getAllStates(compositeElement)) {
			regions.addAll(
					getAllRegions(state)); // getRegions would be enough?
		}
		return regions;
	}
	
	public static Collection<Region> getAllRegions(Region region) {
		Set<Region> regions = new LinkedHashSet<Region>();
		regions.add(region);
		TreeIterator<Object> allContents = EcoreUtil.getAllContents(region, true);
		while (allContents.hasNext()) {
			Object next = allContents.next();
			if (next instanceof Region subregion) {
				regions.add(subregion);
			}
		}
		return regions;
	}
	
	public static State getParentState(StateAnnotation annotation) {
		return (State) annotation.eContainer();
	}
	
	public static Region getTopRegion(EObject object) {
		EObject container = object.eContainer();
		if (container instanceof StatechartDefinition) {
			return (Region) object;
		}
		return getTopRegion(container);
	}
	
	public static Region getParentRegion(StateNode node) {
		return (Region) node.eContainer();
	}
	
	public static boolean isTopRegion(Region region) {
		return getContainingCompositeElement(region) instanceof StatechartDefinition;
	}
	
	public static boolean isSubregion(Region region) {
		return !isTopRegion(region);
	}
	
	public static boolean isOrthogonal(Region region) {
		CompositeElement compositeElement = getContainingCompositeElement(region);
		return compositeElement.getRegions().size() >= 2;
	}
	
	public static boolean areOrthogonal(Region lhs, Region rhs) {
		return getContainingCompositeElement(lhs) == getContainingCompositeElement(rhs);
	}
	
	public static boolean hasOrthogonalRegions(CompositeElement element) {
		for (Region region : getAllRegions(element)) {
			if (isOrthogonal(region)) {
				return true;
			}
		}
		return false;
	}
	
	public static List<Region> getOrthogonalRegions(Region region) {
		CompositeElement compositeElement = getContainingCompositeElement(region);
		List<Region> orthogonalRegions = new ArrayList<Region>(
				compositeElement.getRegions());
		orthogonalRegions.remove(region);
		return orthogonalRegions;
	}
	
	public static boolean areTransitivelyOrthogonal(StateNode lhs, StateNode rhs) {
		List<Region> sourceAncestors = getRegionAncestors(lhs);
		List<Region> targetAncestors = getRegionAncestors(rhs);
		
		int minSize = Integer.min(sourceAncestors.size(), targetAncestors.size());
		for (int i = 0; i < minSize; ++i) {
			Region sourceAncestor = sourceAncestors.get(i);
			Region targetAncestor = targetAncestors.get(i);
			
			if (areOrthogonal(sourceAncestor, targetAncestor)) {
				return true;
			}
		}
		
		return false;
	}
	
	public static boolean isOrthogonal(Transition transition) {
		StateNode source = transition.getSourceState();
		StateNode target = transition.getTargetState();
		
		return areTransitivelyOrthogonal(source, target);
	}
	
	public static CompositeElement getContainingCompositeElement(Region region) {
		return (CompositeElement) region.eContainer();
	}

	public static State getParentState(Region region) {
		if (isTopRegion(region)) {
			throw new IllegalArgumentException("This region has no parent state: " + region);
		}
		return (State) getContainingCompositeElement(region);
	}
	
	public static boolean hasParentState(StateNode node) {
		Region parentRegion = getParentRegion(node);
		EObject container = parentRegion.eContainer();
		return container instanceof State;
	}
	
	public static State getParentState(StateNode node) {
		Region parentRegion = getParentRegion(node);
		return getParentState(parentRegion);
	}
	
	public static Region getParentRegion(Region region) {
		if (isTopRegion(region)) {
			return null;
		}
		return getParentRegion(
				(State) getContainingCompositeElement(region));
	}
	
	public static List<Region> getParentRegions(Region region) {
		if (isTopRegion(region)) {
			return new ArrayList<Region>();
		}
		Region parentRegion = getParentRegion(region);
		List<Region> parentRegions = new ArrayList<Region>();
		parentRegions.add(parentRegion);
		parentRegions.addAll(getParentRegions(parentRegion));
		return parentRegions;
	}
	
	public static List<Region> getSubregions(Region region) {
		List<Region> subregions = new ArrayList<Region>();
		for (List<Region> stateSubregions : getStates(region).stream().map(it -> it.getRegions())
				.collect(Collectors.toList())) {
			for (Region subregion : stateSubregions) {
				subregions.add(subregion);
				subregions.addAll(getSubregions(subregion));
			}
		}
		return subregions;
	}
	
	public static List<State> getCommonAncestors(
			StateNode lhs, StateNode rhs) {
		List<State> ancestors = getAncestors(lhs);
		ancestors.retainAll(getAncestors(rhs));
		return ancestors;
	}
	
	public static List<State> getAncestors(StateNode node) {
		EObject container = node.eContainer();
		EObject containerContainer = container.eContainer();
		if (containerContainer instanceof State) {
			State parentState = getParentState(node);
			List<State> ancestors = getAncestors(parentState);
			ancestors.add(parentState);
			return ancestors;
		}
		return new ArrayList<State>();
	}
	
	public static List<State> getAncestorsAndSelf(State node) {
		List<State> ancestors = getAncestors(node);
		ancestors.add(node);
		return ancestors;
	}
	
	public static List<Region> getRegionAncestors(StateNode node) {
		Region parentRegion = (Region) node.eContainer();
		if (parentRegion.eContainer() instanceof State) {
			State parentState = getParentState(node);
			List<Region> ancestors = getRegionAncestors(parentState);
			ancestors.add(getParentRegion(node));
			return ancestors;
		}
		List<Region> regionList = new ArrayList<Region>();
		regionList.add(parentRegion);
		return regionList;
	}
	
	public static List<Region> getCommonRegionAncestors(StateNode lhs, StateNode rhs) {
		List<Region> ancestors = getRegionAncestors(lhs);
		ancestors.retainAll(
				getRegionAncestors(rhs));
		return ancestors;
	}
	
	/**
	 * Returns whether the given region has deep history in one of its ancestor regions.
	 */
	private static boolean hasDeepHistoryAbove(Region region) {
		if (isTopRegion(region)) {
			return false;
		}
		Region parentRegion = getParentRegion(region);
		return parentRegion.getStateNodes().stream().anyMatch(it -> it instanceof DeepHistoryState) ||
			hasDeepHistoryAbove(parentRegion);
	}
	
	/**
	 * Returns whether the region has history or not.
	 */
	public static boolean hasHistory(Region region) {
		return hasDeepHistoryAbove(region) || 
			region.getStateNodes().stream().anyMatch(it -> it instanceof ShallowHistoryState) || 
			region.getStateNodes().stream().anyMatch(it -> it instanceof DeepHistoryState);
	}	
	
	public static String getFullContainmentHierarchy(StateNode state) {
		if (state == null) {
			return "";
		}
		Region parentRegion = getParentRegion(state);
		State parentState = null;
		if (parentRegion.eContainer() instanceof State) {
			parentState = getParentState(parentRegion);
		}
		String parentRegionName = parentRegion.getName();
		String stateName = state.getName();
		if (parentState == null) {
			// Yakindu bug? First character is set to lowercase in the case of top regions
			parentRegionName = parentRegionName.substring(0, 1).toLowerCase() +
					parentRegionName.substring(1); // toFirstLowerCase
			return parentRegionName + "_" + stateName;
		}
		return getFullContainmentHierarchy(parentState) + "_" + parentRegionName + "_" + stateName;
	}
	
	public static String getFullRegionPathName(Region lowestRegion) {
		if (!(lowestRegion.eContainer() instanceof State)) {
			return lowestRegion.getName();
		}
		String fullParentRegionPathName = getFullRegionPathName(getParentRegion(lowestRegion));
		return fullParentRegionPathName + "." + lowestRegion.getName(); // Only regions are in path - states could be added too
	}
	
	public static Component getReferringSubcomponent(Component rootComponent) {
		Set<Component> imports = new LinkedHashSet<Component>();
		
		Queue<Component> components = new LinkedList<Component>();
		components.add(rootComponent);
		// Queue-based recursive approach instead of a recursive function
		while (!components.isEmpty()) {
			Component component = components.poll();
			List<Component> insideComponents = StatechartModelDerivedFeatures
					.getInstances(component).stream()
					.map(it -> StatechartModelDerivedFeatures.getDerivedType(it))
					.collect(Collectors.toList());
			
			for (Component insideComponent : insideComponents) {
				if (insideComponent == rootComponent) {
					return component;
				}
				// To counter possible inconsistent import hierarchies
				if (!imports.contains(insideComponent)) {
					components.add(insideComponent);
				}
			}
			
			imports.addAll(insideComponents);
		}
		
		return null;
	}
	
	public static StatechartDefinition getContainingStatechart(EObject object) {
		return ecoreUtil.getContainerOfType(object, StatechartDefinition.class);
	}
	
	public static Component getContainingComponent(EObject object) {
		if (object == null) {
			throw new IllegalArgumentException("Not contained by a component: " + object);
		}
		if (object instanceof Component) {
			return (Component) object;
		}
		return getContainingComponent(object.eContainer());
	}
	
	public static Package getContainingPackage(EObject object) {
		if (object instanceof Package) {
			return (Package) object;
		}
		return getContainingPackage(object.eContainer());
	}
	
	public static boolean isContainedByPackage(EObject object) {
		try {
			getContainingPackage(object);
			return true;
		} catch (NullPointerException e) {
			return false;
		}
	}
	
	public static boolean hasSamePortEvent(RaiseEventAction lhs, RaiseEventAction rhs) {
		return lhs.getPort() == rhs.getPort() && lhs.getEvent() == rhs.getEvent();
	}
	
	public static TransitionIdAnnotation getIdAnnotation(Transition transition) {
		for (TransitionAnnotation annotation : transition.getAnnotations()) {
			if (annotation instanceof TransitionIdAnnotation) {
				return (TransitionIdAnnotation) annotation;
			}
		}
		return null;
	}
	
	public static String getId(Transition transition) {
		TransitionIdAnnotation idAnnotation = getIdAnnotation(transition);
		if (idAnnotation == null) {
			return null;
		}
		return idAnnotation.getName();
	}
	
	public static Collection<PortEventReference> getPortEventReferences(Transition transition) {
		return ecoreUtil.getAllContentsOfType(transition.getTrigger(),
				PortEventReference.class);
	}
	
	public static Collection<PortEventReference> getPortEventReferences(
			Collection<Transition> transitions) {
		Set<PortEventReference> portEventReferenes = new HashSet<PortEventReference>();
		for (Transition transition : transitions) {
			portEventReferenes.addAll(
					getPortEventReferences(transition));
		}
		return portEventReferenes;
	}
	
	public static Collection<Transition> getSelfAndPrecedingTransitions(Transition transition) {
		StateNode source = transition.getSourceState();
		Set<Transition> transitions = new HashSet<Transition>();
		transitions.add(transition);
		if (!(source instanceof State)) {
			for (Transition incomingTransition : getIncomingTransitions(source)) {
				transitions.addAll(
						getSelfAndPrecedingTransitions(incomingTransition));
			}
		}
		return transitions;
	}
	
	public static Collection<Transition> getPrioritizedTransitions(Transition gammaTransition) {
		StatechartDefinition gammaStatechart = getContainingStatechart(gammaTransition);
		TransitionPriority transitionPriority = gammaStatechart.getTransitionPriority();
		Collection<Transition> prioritizedTransitions = new ArrayList<Transition>();
		if (transitionPriority != TransitionPriority.OFF) {
			StateNode source = gammaTransition.getSourceState();
			List<Transition> gammaOutgoingTransitions = getOutgoingTransitions(source);
			for (Transition gammaOutgoingTransition : gammaOutgoingTransitions) {
				if (calculatePriority(gammaTransition).longValue() <
						calculatePriority(gammaOutgoingTransition).longValue()) {
					prioritizedTransitions.add(gammaOutgoingTransition);
				}
			}
		}
		return prioritizedTransitions;
	}
	
	public static BigInteger getHighestPriority(StateNode stateNode) {
		List<Transition> outgoingTransitions = getOutgoingTransitions(stateNode);
		BigInteger max = outgoingTransitions.get(0).getPriority();
		for (Transition transition : outgoingTransitions) {
			BigInteger priority = transition.getPriority();
			if (max.compareTo(priority) < 0) {
				max = priority;
			}
		}
		return max;
	}
	
	public static BigInteger calculatePriority(Transition transition) {
		StatechartDefinition statechart = getContainingStatechart(transition);
		TransitionPriority transitionPriority = statechart.getTransitionPriority();
		StateNode source = transition.getSourceState();
		List<Transition> outgoingTransitions = getOutgoingTransitions(source);
		// If it is an else transition, its priority is always the lowest
		Expression guard = transition.getGuard();
		if (isElseOrDefault(guard)) {
			BigInteger min = outgoingTransitions.stream()
				.filter(it -> !isElseOrDefault(it.getGuard()))
				.map(it -> calculatePriority(it)) // There must not be multiple else guards
				.min((lhs, rhs) -> lhs.compareTo(rhs))
				.orElse(BigInteger.ONE);
			return min.subtract(BigInteger.ONE); // Min - 1
		}
		// Normal transition
		switch (transitionPriority) {
			case ORDER_BASED : {
				int size = outgoingTransitions.size();
				int index = outgoingTransitions.indexOf(transition);
				int priority = size - index;
				return BigInteger.valueOf(priority);
			}
			case VALUE_BASED : {
				return transition.getPriority();
			}
			case OFF : { // Default value is 0
				return transition.getPriority();
			}
			default: {
				throw new IllegalArgumentException("Not supported literal: " + transitionPriority);
			}
		}
	}

	public static boolean areConnected(StateNode node, Transition transition) {
		StateNode source = transition.getSourceState();
		StateNode target = transition.getTargetState();
		
		return node == source || node == target;
	}
	
	public static boolean areConnected(Transition lhs, Transition rhs) {
		return getConnectingStateNode(lhs, rhs) != null;
	}
	
	public static StateNode getConnectingStateNode(Transition lhs, Transition rhs) {
		StateNode lhsSource = lhs.getSourceState();
		StateNode rhsSource = rhs.getSourceState();
		StateNode lhsTarget = lhs.getTargetState();
		StateNode rhsTarget = rhs.getTargetState();
		
		if (lhsSource == rhsSource) {
			return lhsSource;
		}
		else if (lhsTarget == rhsTarget) {
			return lhsTarget;
		}
		else if (lhsSource == rhsTarget) {
			return lhsSource;
		}
		else if (lhsTarget == rhsSource) {
			return lhsTarget;
		}
		
		return null;
	}
	
	public static boolean isSameRegion(Transition transition) {
		return getParentRegion(transition.getSourceState()) == getParentRegion(transition.getTargetState());
	}
	
	public static boolean isToHigher(Transition transition) {
		return isToHigher(transition.getSourceState(), transition.getTargetState());
	}
	
	public static boolean isToHigher(StateNode source, StateNode target) {
		Region sourceParentRegion = getParentRegion(source);
		if (isTopRegion(sourceParentRegion)) {
			return false;
		}
		State sourceParentState = getParentState(source);
		if (getParentRegion(sourceParentState) == getParentRegion(target)) {
			return true;
		}
		return isToHigher(sourceParentState, target);
	}
	
	public static boolean isToLower(Transition transition) {
		return isToLower(transition.getSourceState(), transition.getTargetState());
	}
	
	public static boolean isToLower(StateNode source, StateNode target) {
		Region targetParentRegion = getParentRegion(target);
		if (isTopRegion(targetParentRegion)) {
			return false;
		}
		State targetParentState = getParentState(target);
		if (getParentRegion(source) == getParentRegion(targetParentState)) {
			return true;
		}
		return isToLower(source, targetParentState);
	}
	
	public static boolean isToHigherAndLower(Transition transition) {
		return isToHigherAndLower(transition.getSourceState(), transition.getTargetState());
	}
	
	public static boolean isToHigherAndLower(StateNode source, StateNode target) {
		List<Region> sourceAncestors = getRegionAncestors(source);
		List<Region> targetAncestors = getRegionAncestors(target);
		List<Region> commonAncestors = new ArrayList<Region>(sourceAncestors);
		commonAncestors.retainAll(targetAncestors);
		if (commonAncestors.isEmpty()) {
			// Top region orthogonal invalid transitions
			return false;
		}
		sourceAncestors.removeAll(commonAncestors);
		if (sourceAncestors.isEmpty()) {
			// To lower level
			return false;
		}
		targetAncestors.removeAll(commonAncestors);
		if (targetAncestors.isEmpty()) {
			// To higher level
			return false;
		}
		return true;
	}
	
	public static boolean isTriggeredVia(Component component, Port port) {
		Set<SimpleTrigger> triggers = getAllSimpleTriggers(component);
		
		for (SimpleTrigger trigger : triggers) {
			if (trigger instanceof AnyTrigger) {
				return true;
			}
			if (trigger instanceof EventTrigger eventTrigger) {
				EventSource eventSource = getEventSource(eventTrigger);
				if (eventSource == port) {
					return true;
				}
			}
		}
		
		return false;
	}
	
	public static Set<SimpleTrigger> getAllSimpleTriggers(Component component) {
		Set<SimpleTrigger> triggers = new LinkedHashSet<SimpleTrigger>();
		
		for (StatechartDefinition statechart : getSelfOrAllContainedStatecharts(component)) {
			triggers.addAll(
					getAllSimpleTriggers(statechart));
		}
		
		return triggers;
	}
	
	public static Set<SimpleTrigger> getAllSimpleTriggers(StatechartDefinition statechart) {
		List<Transition> transitions = statechart.getTransitions();
		return getAllSimpleTriggers(transitions);
	}
	
	public static Set<SimpleTrigger> getAllSimpleTriggers(State state) {
		List<Transition> outgoingTransitions = getOutgoingTransitions(state);
		return getAllSimpleTriggers(outgoingTransitions);
	}
	
	public static Set<SimpleTrigger> getAllSimpleTriggers(Iterable<? extends Transition> transitions) {
		Set<SimpleTrigger> simpleTriggers = new HashSet<SimpleTrigger>();
		
		for (Transition transition : transitions) {
			simpleTriggers.addAll(
					getAllSimpleTriggers(transition));
		}
		
		return simpleTriggers;
	}
	
	public static Set<SimpleTrigger> getAllSimpleTriggers(Transition transition) {
		Trigger trigger = transition.getTrigger();
		return getAllSimpleTriggers(trigger);
	}
	
	public static Set<SimpleTrigger> getAllSimpleTriggers(Trigger trigger) {
		Set<SimpleTrigger> simpleTriggers = new HashSet<SimpleTrigger>();
		
		if (trigger == null) {
			return simpleTriggers;
		}
		
		if (trigger instanceof SimpleTrigger simpleTrigger) {
			simpleTriggers.add(simpleTrigger);
		}
		else if (trigger instanceof UnaryTrigger unaryTrigger) {
			Trigger operand = unaryTrigger.getOperand();
			simpleTriggers.addAll(
					getAllSimpleTriggers(operand));
		}
		else if (trigger instanceof BinaryTrigger binaryTrigger) {
			Trigger leftOperand = binaryTrigger.getLeftOperand();
			Trigger rightOperand = binaryTrigger.getRightOperand();
			simpleTriggers.addAll(
					getAllSimpleTriggers(leftOperand));
			simpleTriggers.addAll(
					getAllSimpleTriggers(rightOperand));
		}
		else {
			throw new IllegalArgumentException("Not known trigger: " + trigger);
		}
		
		return simpleTriggers;
	}
	
	public static List<EventTrigger> unfoldIntoEventTriggers(Trigger trigger) {
		if (trigger instanceof EventTrigger eventTrigger) {
			EventReference eventReference = eventTrigger.getEventReference();
			if (eventReference instanceof PortEventReference  || 
					eventReference instanceof ClockTickReference ||
					eventReference instanceof TimeoutEventReference) {
				return List.of(eventTrigger);
			}
			if (eventReference instanceof AnyPortEventReference anyPortEventReference) {
				List<EventTrigger> newEventTriggers = new ArrayList<EventTrigger>();
				
				Port port = anyPortEventReference.getPort();
				List<Event> inputEvents = getInputEvents(port);
				for (Event inputEvent : inputEvents) {
					EventTrigger newEventTrigger = statechartUtil.createEventTrigger(port, inputEvent);
					newEventTriggers.add(newEventTrigger);
				}
				
				return newEventTriggers;
			}
			else {
				throw new IllegalArgumentException("Not supported trigger: " + trigger);
			}
		}
		else if (trigger instanceof AnyTrigger) {
			List<EventTrigger> newEventTriggers = new ArrayList<EventTrigger>();
			
			StatechartDefinition statechart = getContainingStatechart(trigger);

			List<Port> ports = getAllPorts(statechart);
			for (Port port : ports) {
				List<Event> inputEvents = getInputEvents(port);
				for (Event inputEvent : inputEvents) {
					EventTrigger newEventTrigger = statechartUtil.createEventTrigger(port, inputEvent);
					newEventTriggers.add(newEventTrigger);
				}
			}
			
			return newEventTriggers;
		}
		else if (trigger instanceof UnaryTrigger unaryTrigger) {
			Trigger operand = unaryTrigger.getOperand();
			return unfoldIntoEventTriggers(operand);
		}
		else if (trigger instanceof BinaryTrigger binaryTrigger) {
			List<EventTrigger> newEventTriggers = new ArrayList<EventTrigger>();
			
			Trigger leftOperand = binaryTrigger.getLeftOperand();
			Trigger rightOperand = binaryTrigger.getRightOperand();
			
			newEventTriggers.addAll(
					unfoldIntoEventTriggers(leftOperand));
			newEventTriggers.addAll(
					unfoldIntoEventTriggers(rightOperand));
			
			return newEventTriggers;
		}
		// On cycle trigger
		throw new IllegalArgumentException("Not supported trigger: " + trigger);
	}
	
	public static boolean areTriggersDisjoint(Transition lhs, Transition rhs) {
		List<Transition> transitions = new ArrayList<Transition>();
		
		transitions.add(lhs);
		transitions.add(rhs);
		
		return areTriggersDisjoint(transitions);
	}
	
	public static boolean areTriggersDisjoint(List<? extends Transition> transitions) {
		if (transitions.size() < 2) {
			return true;
		}
		
		Map<Transition, List<EventTrigger>> triggers = new LinkedHashMap<Transition, List<EventTrigger>>();
		
		for (Transition transition : transitions) {
			Trigger trigger = transition.getTrigger();
			if (trigger instanceof OnCycleTrigger) {
				return false; // Note that 'transitions.size >= 2' at this point
			}
			
			if (trigger != null) { // 'null' trigger (e.g., transition leaving a choice) is disjoint from anything
				List<EventTrigger> eventTriggers = unfoldIntoEventTriggers(trigger);
				
				Collection<List<EventTrigger>> previousEventTriggers = triggers.values();
				for (List<EventTrigger> previousEventTrigger : previousEventTriggers) {
					if (!ecoreUtil.helperDisjoint(eventTriggers, previousEventTrigger)) {
						return false;
					}
				}
				
				triggers.put(transition, eventTriggers);
			}
		}
		
		return true;
	}
	
	public static boolean hasTrigger(Transition transition) {
		return transition.getTrigger() != null;
	}
	
	public static boolean needsTrigger(Transition transition) {
		StateNode source = transition.getSourceState();
		return !(source instanceof EntryState || source instanceof ChoiceState ||
				source instanceof MergeState || source instanceof ForkState ||
				source instanceof JoinState);
	}
	
	public static boolean hasGuard(Transition transition) {
		return transition.getGuard() != null;
	}
	
	public static boolean isEmpty(Transition transition) {
		return !hasTrigger(transition) && !hasGuard(transition) &&
			transition.getEffects().isEmpty();
	}
	
	public static boolean isElse(Transition transition) {
		return transition.getGuard() instanceof ElseExpression;
	}
	
	public static boolean isLeavingState(Transition transition) {
		return transition.getSourceState() instanceof State;
	}
	
	public static boolean isLoop(Transition transition) {
		return transition.getSourceState() == transition.getTargetState();
	}
	
	public static StateNode getSourceAncestor(Transition transition) {
		return getSourceAncestor(transition.getSourceState(), transition.getTargetState());
	}
	
	public static StateNode getSourceAncestor(StateNode source, StateNode target) {
		if (isToLower(source, target)) {
			return source;
		}
		Region sourceParentRegion = getParentRegion(source);
		if (isTopRegion(sourceParentRegion)) {
			throw new IllegalArgumentException("No source ancestor!");
		}
		State sourceParentState = getParentState(source);
		return getSourceAncestor(sourceParentState, target);
	}
	
	public static StateNode getTargetAncestor(Transition transition) {
		return getTargetAncestor(transition.getSourceState(), transition.getTargetState());
	}
	
	public static StateNode getTargetAncestor(StateNode source, StateNode target) {
		if (isToHigher(source, target)) {
			return source;
		}
		Region targetParentRegion = getParentRegion(target);
		if (isTopRegion(targetParentRegion)) {
			throw new IllegalArgumentException("No target ancestor!");
		}
		State targetParentState = getParentState(target);
		return getTargetAncestor(source, targetParentState);
	}
	
	public static boolean isComposite(StateNode node) {
		if (node instanceof State state) {
			return isComposite(state);
		}
		return false;
	}
	
	public static boolean isState(StateNode node) {
		return node instanceof State;
	}
	
	public static boolean isPseudoState(StateNode node) {
		return !isState(node);
	}
	
	public static boolean isComposite(State state) {
		return !state.getRegions().isEmpty();
	}
	
	public static EObject getContainingTransitionOrState(EObject object) {
		Transition containingTransition = ecoreUtil.getContainerOfType(
				object, Transition.class);
		if (containingTransition != null) {
			// Container is a transition
			return containingTransition;
		}
		// Container is a state
		return ecoreUtil.getContainerOfType(object, State.class);
	}
	
	public static EObject getSelfOrContainingTransitionOrState(EObject object) {
		if (object instanceof Transition || object instanceof State) {
			return object;
		}
		return getContainingTransitionOrState(object);
	}
	
	public static StateNode getContainingOrSourceStateNode(EObject object) {
		EObject container = getContainingTransitionOrState(object);
		if (container instanceof Transition transition) {
			return transition.getSourceState();
		}
		return (StateNode) container;
	}
	
	public static StateNode getSelfOrContainingOrSourceStateNode(EObject object) {
		EObject container = getSelfOrContainingTransitionOrState(object);
		if (container instanceof Transition transition) {
			return transition.getSourceState();
		}
		return (StateNode) container;
	}
	
	public static List<Action> getContainingActionList(EObject object) {
		EObject container = object.eContainer();
		if (container instanceof Transition transition) {
			return transition.getEffects();
		}
		if (container instanceof State state) {
			if (state.getEntryActions().contains(object)) {
				return state.getEntryActions();
			}
			if (state.getExitActions().contains(object)) {
				return state.getExitActions();
			}
		}
		// Nullptr if the object is not contained by any of the above
		return getContainingActionList(container);
	}
	
	public static int getLiteralIndex(State state) {
		Region parent = getParentRegion(state);
		List<State> states = getStates(parent);
		return states.indexOf(state) + 1 /* + 1 for __Inactive */;
	}
	
	public static EntryState getEntryState(Region region) {
		Collection<StateNode> entryStates = region.getStateNodes().stream()
				.filter(it -> it instanceof EntryState)
				.collect(Collectors.toList());
		Optional<StateNode> entryState = entryStates.stream().filter(it -> it instanceof InitialState).findFirst();
		if (entryState.isPresent()) {
			return (EntryState) entryState.get();
		}
		entryState = entryStates.stream().filter(it -> it instanceof DeepHistoryState).findFirst();
		if (entryState.isPresent()) {
			return (EntryState) entryState.get();
		}
		entryState = entryStates.stream().filter(it -> it instanceof ShallowHistoryState).findFirst();
		if (entryState.isPresent()) {
			return (EntryState) entryState.get();
		}
		throw new IllegalArgumentException("Not known initial states in the region. " + region.getName() + ": " + entryStates);
	}
	
	public static Transition getInitialTransition(Region region) {
		EntryState entryState = getEntryState(region);
		List<Transition> outgoingTransitions = getOutgoingTransitions(entryState);
		if (outgoingTransitions.size() != 1) {
			throw new IllegalArgumentException(outgoingTransitions.toString());
		}
		return outgoingTransitions.get(0);
	}
	
	public static Collection<State> getInitialStates(Region region) {
		EntryState entryState = getEntryState(region);
		Set<State> reachableStates = getReachableStates(entryState);
		return reachableStates;
	}
	
	public static State getInitialState(Region region) {
		Collection<State> initialStates = getInitialStates(region);
		if (initialStates.size() != 1) {
			throw new IllegalArgumentException("Not one state: " + initialStates);
		}
		return initialStates.iterator().next();
	}
	
	public static Set<State> getPrecedingStates(StateNode node) {
		Set<State> precedingStates = new LinkedHashSet<State>();
		for (Transition incomingTransition : getIncomingTransitions(node)) {
			StateNode source = incomingTransition.getSourceState();
			if (source instanceof State state) {
				precedingStates.add(state);
			}
			else {
				precedingStates.addAll(
						getReachableStates(source));
			}
		}
		return precedingStates;
	}
	
	public static Set<State> getReachableStates(StateNode node) { // Same level
		Set<State> reachableStates = new LinkedHashSet<State>();
		for (Transition outgoingTransition : getOutgoingTransitions(node)) {
			StateNode target = outgoingTransition.getTargetState();
			if (target instanceof State state) {
				reachableStates.add(state);
			}
			else {
				reachableStates.addAll(
						getReachableStates(target));
			}
		}
		return reachableStates;
	}
	
	public static Collection<State> getAllReachableStates(StateNode node) { // Every level
		Set<StateNode> visitedNodes = new HashSet<StateNode>();
		
		getTransitionDistances(node, visitedNodes, new HashSet<Region>());
		List<State> reachableStates = javaUtil.filterIntoList(visitedNodes, State.class);
		
		return reachableStates;
	}
	
	public static Map<StateNode, Integer> getContainedStateNodeDistances(CompositeElement composite) {
		Map<Transition, Integer> transitionDistances = getContainedTransitionDistances(composite);
		
		Map<StateNode, Integer> stateDistances = new LinkedHashMap<StateNode, Integer>();
		Map<StateNode, Integer> sourceDistances = new LinkedHashMap<StateNode, Integer>();
		Map<StateNode, Integer> targetDistances = new LinkedHashMap<StateNode, Integer>();
		for (Transition transition : transitionDistances.keySet()) {
			Integer distance = transitionDistances.get(transition);
			sourceDistances.put(transition.getSourceState(), distance);
			targetDistances.put(transition.getTargetState(), distance + 1);
		}
		
		javaUtil.collectMinimumValues(stateDistances, List.of(sourceDistances, targetDistances));
		
		return stateDistances;
	}
	
	
	public static Map<Transition, Integer> getContainedTransitionDistances(CompositeElement composite) {
		return getContainedTransitionDistances(composite, new HashSet<StateNode>(), new HashSet<Region>());
	}
	
	public static Map<Transition, Integer> getContainedTransitionDistances(
			CompositeElement composite, Set<StateNode> visitedNodes, Set<Region> visitedSubregionsBottomUp) {
		Map<Transition, Integer> distance = new LinkedHashMap<Transition, Integer>();
		
		List<Map<Transition, Integer>> distances = new ArrayList<Map<Transition, Integer>>();
		//
		if (composite instanceof State state) {
			visitedNodes.add(state);
		}
		//
		List<Region> regions = new ArrayList<Region>(composite.getRegions());
		regions.removeAll(visitedSubregionsBottomUp);
		for (Region region : regions) {
			List<EntryState> entryStates = ecoreUtil.getContentsOfType(region, EntryState.class); // Single level
			for (EntryState entryState : entryStates) {
				Map<Transition, Integer> subregionDistance = getTransitionDistances(
						entryState, visitedNodes, visitedSubregionsBottomUp);
				distances.add(subregionDistance);
			}
		}
		
		// Summing the minimal distances
		javaUtil.collectMinimumValues(distance, distances);
		
		return distance;
	}
	
	public static Map<Transition, Integer> getTransitionDistances(StateNode node) {
		return getTransitionDistances(node, new HashSet<StateNode>(), new HashSet<Region>());
	}
	
	public static Map<Transition, Integer> getTransitionDistances(
			StateNode node, Set<StateNode> visitedNodes, Set<Region> visitedSubregionsBottomUp) {
		Map<Transition, Integer> distance = new LinkedHashMap<Transition, Integer>();
		//
		if (visitedNodes.contains(node)) {
			return distance;
		}
		//
		visitedNodes.add(node);
		//
		
		List<Map<Transition, Integer>> distances = new ArrayList<Map<Transition, Integer>>();
		// Children
		if (node instanceof State state) {
			Map<Transition, Integer> subregionDistance = getContainedTransitionDistances(
					state, visitedNodes, visitedSubregionsBottomUp);
			distances.add(subregionDistance);
		}
		// Outgoing transitions
		List<Transition> outgoingTransitions = getOutgoingTransitions(node);
		for (Transition outgoingTransition : outgoingTransitions) {
			distance.put(outgoingTransition, 0);
			
			StateNode target = outgoingTransition.getTargetState();
			// If we enter a composite state from a "normal way", even though we entered it from bottom, we traverse it again
			if (target instanceof State targetState) {
				List<Region> targetRegions = targetState.getRegions();
				if (javaUtil.containsAny(targetRegions, visitedSubregionsBottomUp)) {
					visitedNodes.remove(targetState);
					visitedSubregionsBottomUp.removeAll(targetRegions);
				}
			}
			//
			Map<Transition, Integer> targetDistance = getTransitionDistances(
					target, visitedNodes, visitedSubregionsBottomUp);
			for (Transition transition : targetDistance.keySet()) {
				targetDistance.replace(transition,
						targetDistance.get(transition) + 1); // As this is the distance from a target node
			}
			distances.add(targetDistance);
		}
		// Parent
		if (hasParentState(node)) {
			// We do not want to enter again when checking subregions
			Region parentRegion = getParentRegion(node);
			visitedSubregionsBottomUp.add(parentRegion);
			//
			State ancestor = getParentState(node);
			Map<Transition, Integer> ancestorDistance = getTransitionDistances(
					ancestor, visitedNodes, visitedSubregionsBottomUp);
			distances.add(ancestorDistance);
			//
			visitedSubregionsBottomUp.remove(parentRegion);
		}
		
		// Summing the minimal distances
		javaUtil.collectMinimumValues(distance, distances);
		
		return distance;
	}
	
	public static TimeSpecification getTimeoutValue(TimeoutDeclaration timeout) {
		StatechartDefinition statechart = getContainingStatechart(timeout);
		TimeSpecification time = null;
		TreeIterator<Object> contents = EcoreUtil.getAllContents(statechart, true);
		while (contents.hasNext()) {
			Object it = contents.next();
			if (it instanceof SetTimeoutAction action) {
				if (action.getTimeoutDeclaration() == timeout) {
					if (time == null) {
						time = action.getTime();
					}
					else {
						throw new IllegalStateException("This timeout is assigned a value more than once: " + timeout);
					}
				}
			}
		}
		return time;
	}
	
	public static Expression getTimeInMilliseconds(TimeSpecification timeout) {
		Expression time = timeout.getValue();
		Expression clonedTime = ecoreUtil.clone(time);
		TimeUnit unit = timeout.getUnit();
		switch (unit) {
			case MILLISECOND:
				return clonedTime;
			case SECOND: {
				return statechartUtil.wrapIntoMultiply(clonedTime, 1000);
			}
			case HOUR: {
				return statechartUtil.wrapIntoMultiply(clonedTime, 1000 * 60 * 60);
			}
		default:
			throw new IllegalArgumentException("Unexpected value: " + unit);
		}
	}
	
	public static Component getMonitoredComponent(StatechartDefinition adaptiveContract) {
		List<ComponentAnnotation> annotations = adaptiveContract.getAnnotations();
		for (ComponentAnnotation annotation: annotations) { 
			if (annotation instanceof AdaptiveContractAnnotation adaptiveContractAnnotation) {
				return adaptiveContractAnnotation.getMonitoredComponent();
			}
		}
		throw new IllegalArgumentException("Not an adaptive contract statechart: " + adaptiveContract);
	}
	
	public static Collection<ComponentInstance> getReferencingComponentInstances(Component component) {
		Package _package = getContainingPackage(component);
		Collection<ComponentInstance> componentInstances = new HashSet<ComponentInstance>();
		for (Component siblingComponent : _package.getComponents()) {
			if (siblingComponent instanceof CompositeComponent compositeComponent) {
				for (ComponentInstance componentInstance : getDerivedComponents(compositeComponent)) {
					if (getDerivedType(componentInstance) == component) {
						componentInstances.add(componentInstance);
					}
				}
			}
			if (siblingComponent instanceof AsynchronousAdapter asynchronousAdapter) {
				SynchronousComponentInstance componentInstance = asynchronousAdapter.getWrappedComponent();
				if (componentInstance.getType() == component) {
					componentInstances.add(componentInstance);
				}
			}
		}
		return componentInstances;
	}
	
	public static ComponentInstance getReferencingComponentInstance(Component component) {
		Collection<ComponentInstance> instances = getReferencingComponentInstances(component);
		if (instances.size() != 1) {
			throw new IllegalArgumentException("Not one referencing instance: " + instances);
		}
		return instances.stream().findFirst().get();
	}
	
	public static Component getParentComponent(Component component) {
		ComponentInstance instance = getReferencingComponentInstance(component);
		Component parentComponent = StatechartModelDerivedFeatures.getContainingComponent(instance);
		return parentComponent;
	}
	
	public static ComponentInstance getContainingComponentInstance(EObject object) {
		StatechartDefinition statechart = getContainingStatechart(object);
		return getReferencingComponentInstance(statechart);
	}
	
	public static List<ComponentInstance> getParentComponentInstances(ComponentInstance instance) {
		Component container = ecoreUtil.getContainerOfType(instance, Component.class);
		try {
			ComponentInstance referencingComponentInstance = getReferencingComponentInstance(container);
			List<ComponentInstance> parentComponentInstances = getParentComponentInstances(referencingComponentInstance);
			parentComponentInstances.add(referencingComponentInstance);
			return parentComponentInstances;
		} catch (IllegalArgumentException e) {
			// Top component
			return new ArrayList<ComponentInstance>();
		}
	}
	
	public static List<ComponentInstance> getWrapperlessComponentInstanceChain(ComponentInstance instance) {
		List<ComponentInstance> componentInstanceChain = getComponentInstanceChain(instance);
		
		for (Iterator<ComponentInstance> it = componentInstanceChain.iterator(); it.hasNext(); ) {
			ComponentInstance componentInstance = it.next();
			Component component = getContainingComponent(componentInstance);
			if (isWrapperComponent(component)) {
				it.remove();
			}
		}
		
		return componentInstanceChain;
	}
	
	public static List<ComponentInstance> getComponentInstanceChain(ComponentInstance instance) {
		List<ComponentInstance> parentComponentInstances = getParentComponentInstances(instance);
		parentComponentInstances.add(instance);
		return parentComponentInstances;
	}
	
	public static List<ComponentInstance> getComponentInstanceChain(
			ComponentInstanceReferenceExpression reference) {
		ComponentInstance instance = reference.getComponentInstance();
		ComponentInstanceReferenceExpression child = reference.getChild();
		if (child == null) {
			List<ComponentInstance> instanceList = new ArrayList<ComponentInstance>();
			instanceList.add(instance);
			return instanceList;
		}
		else {
			List<ComponentInstance> children = getComponentInstanceChain(child);
			children.add(0, instance); // See above: mutable list is returned
			return children;
		}
	}
	
	public static ComponentInstanceReferenceExpression getParent(ComponentInstanceReferenceExpression reference) {
		return ecoreUtil.getContainerOfType(reference, ComponentInstanceReferenceExpression.class);
	}
	
	public static ComponentInstanceReferenceExpression getFirstInstanceReference(
			ComponentInstanceReferenceExpression reference) {
		ComponentInstanceReferenceExpression parent = getParent(reference);
		if (parent == null) {
			return reference;
		}
		return getFirstInstanceReference(parent);
	}
	
	public static ComponentInstanceReferenceExpression getLastInstanceReference(
			ComponentInstanceReferenceExpression reference) {
		ComponentInstanceReferenceExpression child = reference.getChild();
		if (child == null) {
			return reference;
		}
		return getLastInstanceReference(child);
	}
	
	public static ComponentInstance getLastInstance(ComponentInstanceReferenceExpression reference) {
		ComponentInstanceReferenceExpression lastInstanceReference =
				getLastInstanceReference(reference);
		ComponentInstance lastInstance = lastInstanceReference.getComponentInstance();
		return lastInstance;
	}
	
	public static boolean isFirst(ComponentInstanceReferenceExpression reference) {
		return getParent(reference) == null;
	}
	
	public static boolean isLast(ComponentInstanceReferenceExpression reference) {
		return reference.getChild() == null;
	}
	
	public static boolean isAtomic(ComponentInstanceReferenceExpression reference) {
		return isFirst(reference) && isLast(reference);
	}
	
	public static boolean contains(ComponentInstance potentialContainer, ComponentInstance instance) {
		List<ComponentInstance> instances = getInstances(potentialContainer);
		return instances.contains(instance);
	}
	
	public static int getScheduleCount(Component component) {
		if (isTop(component)) {
			return 1;
		}
		
		ComponentInstance instance = getReferencingComponentInstance(component);
		Component parentComponent = getParentComponent(component);
		List<? extends ComponentInstance> scheduledInstances = getScheduledInstances(parentComponent);
		
		int count = 0;
		for (ComponentInstance scheduledInstance : scheduledInstances) {
			if (scheduledInstance == instance) {
				++count;
			}
		}
		
		int parentScheduleCount = getScheduleCount(parentComponent);
		
		return parentScheduleCount * count;
	}
	
	public static boolean isTop(Component component) {
		try {
			Component parent = getParentComponent(component);
			return parent == null;
		} catch (IllegalArgumentException e) {
			return true;
		}
	}
	
	@SuppressWarnings("unchecked")
	protected static <T extends ComponentAnnotation> T getComponentAnnotation(
			Component component, Class<T> annotation) {
		Optional<ComponentAnnotation> componentAnnotation = component.getAnnotations().stream()
				.filter(it -> annotation.isInstance(it)).findFirst();
		if (componentAnnotation.isPresent()) {
			return (T) componentAnnotation.get();
		}
		return null;
	}
	
	protected static <T extends StatechartAnnotation> T getStatechartAnnotation(
			StatechartDefinition statechart, Class<T> annotation) {
		return getComponentAnnotation(statechart, annotation);
	}
	
	public static ScenarioAllowedWaitAnnotation getScenarioAllowedWaitAnnotation(
			StatechartDefinition statechart) {
		return getStatechartAnnotation(statechart, ScenarioAllowedWaitAnnotation.class);
	}
	
	public static boolean isMutant(Component component) {
		return getComponentAnnotation(component, MutantAnnotation.class) != null;
	}
	
	public static boolean isWrapperComponent(Component component) {
		return getComponentAnnotation(component, WrapperComponentAnnotation.class) != null;
	}
	
	public static boolean isMissionPhase(Component component) {
		return getComponentAnnotation(component, MissionPhaseAnnotation.class) != null;
	}
	
	public static boolean isAdaptiveContract(Component component) {
		return getComponentAnnotation(component, AdaptiveContractAnnotation.class) != null;
	}
	
	public static boolean hasHistory(MissionPhaseStateAnnotation annotation) {
		return annotation.getHistory() != History.NO_HISTORY || 
				!annotation.getVariableBindings().isEmpty();
	}
	
	public static boolean hasInternalPort(MissionPhaseStateAnnotation annotation) {
		// Internal ports are not really history, more like context dependency
		return annotation.getPortBindings().stream().anyMatch(
				it -> isInternal(it.getCompositeSystemPort()));
	}
	
	public static boolean hasHistoryOrInternalPort(MissionPhaseStateAnnotation annotation) {
		return hasHistory(annotation) || hasInternalPort(annotation);
	}
	
	public static boolean hasInitialOutputsBlock(Component component) {
		return getComponentAnnotation(component, HasInitialOutputsBlockAnnotation.class) != null;
	}
	
	public static boolean hasNegatedContractStatechartAnnotation(Component component) {
		return getComponentAnnotation(component, NegativeContractStatechartAnnotation.class) != null;
	}
	
	public static List<Expression> getInterfaceInvariants(Port port) {
		return port.getInterfaceRealization().getInterface().getInvariants();
	}
	
	public static List<Expression> mapInterfaceInvariantsToPort(Port port) {
		List<Expression> interfaceInvariants = ecoreUtil.clone(getInterfaceInvariants(port));
		
		for (Expression interfaceInvariant : interfaceInvariants) {
			List<InterfaceParameterReferenceExpression> interfaceParameterReferenceExpressions = ecoreUtil.getSelfAndAllContentsOfType(interfaceInvariant, InterfaceParameterReferenceExpression.class);
			for (InterfaceParameterReferenceExpression interfaceParameterReferenceExpression : interfaceParameterReferenceExpressions) {
				Expression portInvariant = statechartUtil.createEventParameterReference(port,
						interfaceParameterReferenceExpression.getParameter());
				ecoreUtil.replace(portInvariant, interfaceParameterReferenceExpression);
			}
		}
		
		return interfaceInvariants;
	}
	
}