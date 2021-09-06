package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.expression.model.ConstantDeclaration
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.property.model.AtomicFormula
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference
import hu.bme.mit.gamma.property.model.ComponentInstanceVariableReference
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.lowlevel.transformation.ExpressionTransformer
import hu.bme.mit.gamma.transformation.util.PropertyUnfolder
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.property.derivedfeatures.PropertyModelDerivedFeatures.*

class InitialStateHandler {
	
	protected final XSTS xSts
	protected final Component component
	protected final PropertyPackage initialState
	protected final InitialStateSetting initialStateSetting
	protected final ReferenceToXstsVariableMapper mapper
	
	protected final extension PropertyExpressionTransformer expressionTransformer
	
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new(XSTS xSts, Component component, PropertyPackage initialState) {
		this(xSts, component, initialState, InitialStateSetting.EXECUTE_ENTRY_ACTIONS)
	}
	
	new(XSTS xSts, Component component,
			PropertyPackage initialState, InitialStateSetting initialStateSetting) {
		this.xSts = xSts
		this.component = component // Unfolded
		
		if (initialState.unfolded) {
			this.initialState = initialState
		}
		else {
			val propertyUnfolder = new PropertyUnfolder(initialState, component)
			this.initialState = propertyUnfolder.execute // Unfolded
		}
		this.initialStateSetting = initialStateSetting
		
		this.mapper = new ReferenceToXstsVariableMapper(xSts)
		this.expressionTransformer = new PropertyExpressionTransformer(mapper)
	}
	
	def execute() {
		val xStsVariableAssignments = newArrayList
		
		for (property : initialState.formulas) {
			val formula = property.formula
			checkState(formula instanceof AtomicFormula, formula + " is not an atomic formula")
			val atomicFormula = formula as AtomicFormula
			val expression = atomicFormula.expression
			
			xStsVariableAssignments += expression.transform
		}
		
		// Setting the initial state according to the input
		switch (initialStateSetting) {
			case EXECUTE_ENTRY_ACTIONS: {
				val configurationAction = xSts.configurationInitializingTransition.action
				configurationAction.appendToAction(xStsVariableAssignments)
				// entryEventTransition remains untouched
			}
			case SKIP_ENTRY_ACTIONS: {
				// Replacing the entryEventTransition
				xSts.entryEventTransition.action = xStsVariableAssignments.createSequentialAction
			}
			default: {
				throw new IllegalArgumentException(
					"Not known initial state setting: " + initialStateSetting)
			}
		}
		
	}
	
	protected def dispatch transform(EqualityExpression expression) {
		val lhs = expression.leftOperand
		val rhs = expression.rightOperand
		
		checkState(lhs instanceof ComponentInstanceVariableReference,
				lhs + " is not a variable reference")
		
		val xStsLhs = lhs.transformExpression
				.filter(DirectReferenceExpression).toList // Casting
		val xStsRhs = rhs.transformExpression
		
		// Filtering null declarations (references to optimized variables)
		for (var i = 0; i < xStsLhs.size; i++) {
			val reference = xStsLhs.get(i)
			if (reference.declaration === null) {
				xStsLhs.remove(i)
				xStsRhs.remove(i)
			}
		}
		
		return xStsLhs.createAssignmentActions(xStsRhs)
	}
	
	protected def dispatch transform(ComponentInstanceStateConfigurationReference expression) {
		val region = expression.region
		val state = expression.state
		
		val xStsRegionVariable = mapper.getRegionVariable(region)
		val xStsStateLiteral = mapper.getStateLiteral(state)
		
		return #[
			xStsRegionVariable.createAssignmentAction(
					xStsStateLiteral.createEnumerationLiteralExpression)
		]
	}
	
	// Sufficient - the XSTS expression transformer would change only the variable references
	static class PropertyExpressionTransformer extends ExpressionTransformer {
		
		protected final ReferenceToXstsVariableMapper mapper
	
		new(ReferenceToXstsVariableMapper mapper) {
			this.mapper = mapper
		}
	
		def dispatch List<Expression> transformExpression(
				ComponentInstanceVariableReference expression) {
			val variable = expression.variable
			val xStsVariables = mapper.getVariableVariables(variable)
			return xStsVariables.map[it.createReferenceExpression]
		}
		
		override dispatch List<Expression> transformExpression(
				DirectReferenceExpression expression) {
			val declaration = expression.declaration
			if (declaration instanceof ConstantDeclaration) {
				val value = declaration.expression
				return value.transformExpression
			}
			return super.transformExpression(expression)
		}
		
	}
	
}