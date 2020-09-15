package hu.bme.mit.gamma.ui.taskhandler;

import static com.google.common.base.Preconditions.checkArgument;

import java.io.File;
import java.io.IOException;
import java.util.AbstractMap.SimpleEntry;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Map.Entry;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;

import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.genmodel.model.Slicing;
import hu.bme.mit.gamma.property.model.AtomicFormula;
import hu.bme.mit.gamma.property.model.ComponentInstanceEventParameterReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceEventReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceVariableReference;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.transformation.util.reducer.SystemOutEventReducer;
import hu.bme.mit.gamma.transformation.util.reducer.WrittenOnlyVariableReducer;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class SlicingHandler extends TaskHandler  {

	public SlicingHandler(IFile file) {
		super(file);
	}
	
	/**
	 * Now it is used only for already UNFOLDED components (package).
	 */
	public void execute(Slicing slicing) throws IOException {
		setFileName(slicing);
		setTargetFolder(slicing);
		
		PropertyPackage propertyPackage = slicing.getPropertyPackage();
		
		Slicer slicer = new Slicer(propertyPackage, true);
		slicer.execute();
		
		// Saving like an EMF model
		Component component = propertyPackage.getComponent();
		Package containingPackage = StatechartModelDerivedFeatures.getContainingPackage(component);
		final String fileName = slicing.getFileName().get(0);
		ecoreUtil.normalSave(containingPackage, targetFolderUri, fileName);
	}
	
	/**
	 * Here the file name is the whole file name of the component with the extension.
	 */
	private void setFileName(Slicing slicing) {
		checkArgument(slicing.getFileName().size() <= 1);
		if (slicing.getFileName().isEmpty()) {
			Component component = slicing.getPropertyPackage().getComponent();
			String fileName = getContainingFileName(component);
			slicing.getFileName().add(fileName);
		}
	}
	
	/**
	 * Original target folder for the component under slicing.
	 */
	private void setTargetFolder(Slicing slicing) {
		checkArgument(slicing.getTargetFolder().size() <= 1);
		if (slicing.getTargetFolder().isEmpty()) {
			Component component = slicing.getPropertyPackage().getComponent();
			URI relativeUri = component.eResource().getURI();
			URI parentUri = relativeUri.trimSegments(1);
			String platformUri = parentUri.toPlatformString(true);
			String targetFolder = platformUri.substring(
				(File.separator + file.getProject().getName() + File.separator).length());
			slicing.getTargetFolder().add(targetFolder);
			// Setting the attribute, the target folder is a RELATIVE path now from the project
			targetFolderUri = URI.decode(projectLocation + File.separator + slicing.getTargetFolder().get(0));
		}
	}
	
	public static class Slicer {
		
		protected final PropertyPackage propertyPackage;
		protected final boolean removeOutEventRaisings;
		
		protected GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
		
		public Slicer(PropertyPackage propertyPackage) {
			this(propertyPackage, false);
		}
		
		public Slicer(PropertyPackage propertyPackage, boolean removeOutEventRaisings) {
			this.propertyPackage = propertyPackage;
			this.removeOutEventRaisings = removeOutEventRaisings;
		}
		
		public void execute() {
			Component component = propertyPackage.getComponent();
			Package containingPackage = StatechartModelDerivedFeatures.getContainingPackage(component);
			final List<AtomicFormula> atomicFormulas = ecoreUtil.getAllContentsOfType(propertyPackage, AtomicFormula.class);
			
			// Variable removal
			Collection<VariableDeclaration> relevantVariables = new HashSet<VariableDeclaration>();
			for (AtomicFormula atomicFormula : atomicFormulas) {
				List<ComponentInstanceVariableReference> variableReferences =
						ecoreUtil.getAllContentsOfType(atomicFormula, ComponentInstanceVariableReference.class);
				for (ComponentInstanceVariableReference variableReference : variableReferences) {
					relevantVariables.add(variableReference.getVariable());
				}
			}
			WrittenOnlyVariableReducer variableReducer = new WrittenOnlyVariableReducer(containingPackage, relevantVariables);
			variableReducer.execute();
			
			// Out-event and out-event parameter raising removal
			if (removeOutEventRaisings) {
				Collection<Entry<Port, Event>> relevantEvents = new HashSet<Entry<Port, Event>>();
				for (AtomicFormula atomicFormula : atomicFormulas) {
					List<ComponentInstanceEventReference> eventReferences =
							ecoreUtil.getAllContentsOfType(atomicFormula, ComponentInstanceEventReference.class);
					for (ComponentInstanceEventReference eventReference : eventReferences) {
						relevantEvents.add(new SimpleEntry<Port, Event>(eventReference.getPort(), eventReference.getEvent()));
					}
					List<ComponentInstanceEventParameterReference> parameterReferences =
							ecoreUtil.getAllContentsOfType(atomicFormula, ComponentInstanceEventParameterReference.class);
					for (ComponentInstanceEventParameterReference parameterReference : parameterReferences) {
						relevantEvents.add(
								new SimpleEntry<Port, Event>(parameterReference.getPort(), parameterReference.getEvent()));
					}
				}
				SystemOutEventReducer systemOutEventReducer = new SystemOutEventReducer(component, relevantEvents);
				systemOutEventReducer.execute();
			}
		}
		
	}

}
