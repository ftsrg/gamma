package hu.bme.mit.gamma.composition.xsts.uppaal.transformation

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.transformation.util.annotations.DataflowCoverageCriterion
import hu.bme.mit.gamma.transformation.util.annotations.InteractionCoverageCriterion
import hu.bme.mit.gamma.transformation.util.annotations.ModelAnnotatorPropertyGenerator.ComponentInstancePortReferences
import hu.bme.mit.gamma.transformation.util.annotations.ModelAnnotatorPropertyGenerator.ComponentInstancePortStateTransitionReferences
import hu.bme.mit.gamma.transformation.util.annotations.ModelAnnotatorPropertyGenerator.ComponentInstanceReferences
import hu.bme.mit.gamma.transformation.util.annotations.ModelAnnotatorPropertyGenerator.ComponentInstanceVariableReferences
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.XSTS
import java.util.List
import hu.bme.mit.gamma.xsts.transformation.api.Gamma2XstsTransformerSerializer
import hu.bme.mit.gamma.xsts.uppaal.transformation.api.Xsts2UppaalTransformerSerializer

class Gamma2XstsUppaalTransformerSerializer {

	protected final Component component
	protected final List<Expression> arguments
	protected final String targetFolderUri
	protected final String fileName
	protected final Integer schedulingConstraint
	// Slicing
	protected final boolean optimize
	protected final PropertyPackage propertyPackage
	// Annotation
	protected final ComponentInstanceReferences testedComponentsForStates
	protected final ComponentInstanceReferences testedComponentsForTransitions
	protected final ComponentInstanceReferences testedComponentsForTransitionPairs
	protected final ComponentInstancePortReferences testedComponentsForOutEvents
	protected final ComponentInstancePortStateTransitionReferences testedInteractions
	protected final InteractionCoverageCriterion senderCoverageCriterion
	protected final InteractionCoverageCriterion receiverCoverageCriterion
	protected final ComponentInstanceVariableReferences dataflowTestedVariables
	protected final DataflowCoverageCriterion dataflowCoverageCriterion
	protected final ComponentInstancePortReferences testedComponentsForInteractionDataflow
	protected final DataflowCoverageCriterion interactionDataflowCoverageCriterion
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	
	new(Component component, String targetFolderUri, String fileName) {
		this(component, #[], targetFolderUri, fileName)
	}

	new(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName) {
		this(component, arguments, targetFolderUri, fileName, null)
	}
	
	new(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName,
			Integer schedulingConstraint) {
		this(component, arguments, targetFolderUri, fileName, schedulingConstraint,
			true, null,
			null, null, null, null, null,
			InteractionCoverageCriterion.EVERY_INTERACTION,	InteractionCoverageCriterion.EVERY_INTERACTION,
			null, DataflowCoverageCriterion.ALL_USE,
			null, DataflowCoverageCriterion.ALL_USE)
	}
	
	new(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName,
			Integer schedulingConstraint,
			boolean optimize, PropertyPackage propertyPackage,
			ComponentInstanceReferences testedComponentsForStates,
			ComponentInstanceReferences testedComponentsForTransitions,
			ComponentInstanceReferences testedComponentsForTransitionPairs,
			ComponentInstancePortReferences testedComponentsForOutEvents,
			ComponentInstancePortStateTransitionReferences testedInteractions,
			InteractionCoverageCriterion senderCoverageCriterion,
			InteractionCoverageCriterion receiverCoverageCriterion,
			ComponentInstanceVariableReferences dataflowTestedVariables,
			DataflowCoverageCriterion dataflowCoverageCriterion,
			ComponentInstancePortReferences testedComponentsForInteractionDataflow,
			DataflowCoverageCriterion interactionDataflowCoverageCriterion) {
		this.component = component
		this.arguments = arguments
		this.targetFolderUri = targetFolderUri
		this.fileName = fileName
		this.schedulingConstraint = schedulingConstraint
		//
		this.optimize = optimize
		this.propertyPackage = propertyPackage
		//
		this.testedComponentsForStates = testedComponentsForStates
		this.testedComponentsForTransitions = testedComponentsForTransitions
		this.testedComponentsForTransitionPairs = testedComponentsForTransitionPairs
		this.testedComponentsForOutEvents = testedComponentsForOutEvents
		this.testedInteractions = testedInteractions
		this.senderCoverageCriterion = senderCoverageCriterion
		this.receiverCoverageCriterion = receiverCoverageCriterion
		this.dataflowTestedVariables = dataflowTestedVariables
		this.dataflowCoverageCriterion = dataflowCoverageCriterion
		this.testedComponentsForInteractionDataflow = testedComponentsForInteractionDataflow
		this.interactionDataflowCoverageCriterion = interactionDataflowCoverageCriterion
	}
	
	def execute() {
		val xStsTransformer = new Gamma2XstsTransformerSerializer(component,
			arguments, targetFolderUri,
			fileName, schedulingConstraint,
			optimize, propertyPackage,
			testedComponentsForStates, testedComponentsForTransitions,
			testedComponentsForTransitionPairs, testedComponentsForOutEvents,
			testedInteractions, senderCoverageCriterion, receiverCoverageCriterion,
			dataflowTestedVariables, dataflowCoverageCriterion,
			testedComponentsForInteractionDataflow, interactionDataflowCoverageCriterion)
		xStsTransformer.execute
		val xSts = targetFolderUri.normalLoad(fileName.emfXStsFileName) as XSTS
		val uppaalTransformer = new Xsts2UppaalTransformerSerializer(xSts,
			targetFolderUri, fileName)
		uppaalTransformer.execute
	}
	
}