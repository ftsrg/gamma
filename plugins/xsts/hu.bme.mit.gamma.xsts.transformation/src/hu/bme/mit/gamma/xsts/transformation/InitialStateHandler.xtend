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

class InitialStateHandler {
	
	protected final XSTS xSts
	protected final Component component
	protected final PropertyPackage initialState
	protected final ReferenceToXstsVariableMapper mapper
	
	protected final ExpressionTransformer lowlevelTransformer = new ExpressionTransformer
	protected final hu.bme.mit.gamma.lowlevel.xsts.transformation.ExpressionTransformer
		xStsTransformer = new hu.bme.mit.gamma.lowlevel.xsts.transformation.ExpressionTransformer
	
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new(XSTS xSts, Component component, PropertyPackage initialState) {
		this.xSts = xSts
		this.component = component // Unfolded
		
		val propertyUnfolder = new PropertyUnfolder(initialState, component)
		this.initialState = propertyUnfolder.execute // Unfolded
		
		this.mapper = new ReferenceToXstsVariableMapper(xSts)
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
		
		// TODO Handling xStsVariableAssignments according to the setting
		val configurationAction = xSts.configurationInitializingTransition.action
		configurationAction.appendToAction(xStsVariableAssignments)
		
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
	
	//
	
	protected def List<Expression> transformExpression(Expression expression) {
		val xStsExpressions = <Expression>newArrayList
		
		if (expression instanceof ComponentInstanceVariableReference) {
			val variable = expression.variable
			val xStsVariables = mapper.getVariableVariables(variable)
			xStsExpressions += xStsVariables.map[it.createReferenceExpression]
		}
		else if (expression instanceof DirectReferenceExpression) {
			val declaration = expression.declaration
			if (declaration instanceof ConstantDeclaration) {
				val value = declaration.expression
				xStsExpressions += value.transformExpression
				// Does not work if constants are referred again from composite expressions
			}
		}
		else {
			// Normal transformation chain
			xStsExpressions += lowlevelTransformer.transformExpression(expression)
					.map[xStsTransformer.transformExpression(it)]
		}
		
		return xStsExpressions
	}
	
}