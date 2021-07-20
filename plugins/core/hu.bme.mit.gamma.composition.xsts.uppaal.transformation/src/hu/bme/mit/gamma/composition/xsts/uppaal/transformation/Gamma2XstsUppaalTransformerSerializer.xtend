package hu.bme.mit.gamma.composition.xsts.uppaal.transformation

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.lowlevel.xsts.transformation.TransitionMerging
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.transformation.util.annotations.AnnotatablePreprocessableElements
import hu.bme.mit.gamma.transformation.util.annotations.DataflowCoverageCriterion
import hu.bme.mit.gamma.transformation.util.annotations.InteractionCoverageCriterion
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.transformation.api.Gamma2XstsTransformerSerializer
import hu.bme.mit.gamma.xsts.uppaal.transformation.api.Xsts2UppaalTransformerSerializer
import java.util.List

class Gamma2XstsUppaalTransformerSerializer {

	protected final Component component
	protected final List<Expression> arguments
	protected final String targetFolderUri
	protected final String fileName
	protected final Integer schedulingConstraint
	// Configuration
	protected final boolean optimize
	protected final boolean extractGuards
	protected final TransitionMerging transitionMerging
	// Slicing
	protected final PropertyPackage propertyPackage
	// Annotation
	protected final AnnotatablePreprocessableElements annotatableElements
	
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
			true, false, TransitionMerging.HIERARCHICAL,
			null, new AnnotatablePreprocessableElements(
				null, null, null, null, null,
				InteractionCoverageCriterion.EVERY_INTERACTION,	InteractionCoverageCriterion.EVERY_INTERACTION,
				null, DataflowCoverageCriterion.ALL_USE,
				null, DataflowCoverageCriterion.ALL_USE
			)
		)
	}
	
	new(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName,
			Integer schedulingConstraint,
			boolean optimize, boolean extractGuards,
			TransitionMerging transitionMerging,
			PropertyPackage propertyPackage,
			AnnotatablePreprocessableElements annotatableElements) {
		this.component = component
		this.arguments = arguments
		this.targetFolderUri = targetFolderUri
		this.fileName = fileName
		this.schedulingConstraint = schedulingConstraint
		//
		this.optimize = optimize
		this.extractGuards = extractGuards
		this.transitionMerging = transitionMerging
		//
		this.propertyPackage = propertyPackage
		//
		this.annotatableElements = annotatableElements
	}
	
	def execute() {
		val xStsTransformer = new Gamma2XstsTransformerSerializer(component,
			arguments, targetFolderUri,
			fileName, schedulingConstraint,
			optimize, false /* UPPAAL cannot handle havoc actions */, extractGuards, 
			transitionMerging,
			propertyPackage, annotatableElements)
		xStsTransformer.execute
		val xSts = targetFolderUri.normalLoad(fileName.emfXStsFileName) as XSTS
		val uppaalTransformer = new Xsts2UppaalTransformerSerializer(xSts,
			targetFolderUri, fileName)
		uppaalTransformer.execute
	}
	
}