package hu.bme.mit.gamma.xsts.uppaal.transformation

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.PredicateExpression
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import org.eclipse.xtend.lib.annotations.Data
import uppaal.expressions.Expression
import uppaal.templates.Selection

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class HavocHandler {
	// Singleton
	public static final HavocHandler INSTANCE = new HavocHandler
	protected new() {
		val ntaName = Namings.name
		this.ntaBuilder = new NtaBuilder(ntaName) // Random NTA is created
	}
	//
	
	protected final NtaBuilder ntaBuilder
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	
	// Entry point
	
	def createSelection(VariableDeclaration variable) {
		val type = variable.type
		return type.createSelection(variable)
	}
	
	//
	
	def dispatch SelectionStruct createSelection(TypeReference type, VariableDeclaration variable) {
		val typeDeclaration = type.reference
		val typeDefinition = typeDeclaration.type
		return typeDefinition.createSelection(variable)
	}
	
	def dispatch SelectionStruct createSelection(BooleanTypeDefinition type, VariableDeclaration variable) {
		val name = Namings.name
		val selection = ntaBuilder.createBooleanSelection(name)
		
		return new SelectionStruct(selection, null)
	}
	
	def dispatch SelectionStruct createSelection(EnumerationTypeDefinition type, VariableDeclaration variable) {
		val name = Namings.name
		val upperLiteral = type.literals.size - 1
		
		val lowerBound = ntaBuilder.createLiteralExpression("0")
		val upperBound = ntaBuilder.createLiteralExpression(upperLiteral.toString)
		val selection = ntaBuilder.createIntegerSelection(name, lowerBound, upperBound)
		
		return new SelectionStruct(selection, null)
	}
	
	def dispatch SelectionStruct createSelection(IntegerTypeDefinition type, VariableDeclaration variable) {
		val root = variable.root
		
		val predicates = root.getAllContentsOfType(PredicateExpression).filter(BinaryExpression)
		val expressions = newArrayList
		
		expressions += predicates.filter[it.leftOperand instanceof ReferenceExpression]
			.filter[it.leftOperand.declaration === variable]
			.map[it.rightOperand]
		expressions += predicates.filter[it.rightOperand instanceof ReferenceExpression]
			.filter[it.rightOperand.declaration === variable]
			.map[it.leftOperand]
			
		val integerValues = newHashSet
		integerValues += expressions.map[it.evaluateInteger]
		
		if (integerValues.empty) {
			// Sometimes input parameters are not referenced
			return new SelectionStruct(null, null)
		}
		
		val defaultValue = type.defaultExpression.evaluateInteger // 0
		val elseValue = integerValues.contains(defaultValue) ? integerValues.max + 1 : defaultValue
		integerValues += elseValue // Adding another value for an "else" branch
		
		val name = Namings.name
		val min = integerValues.min
		val max = integerValues.max
		val selection = ntaBuilder.createIntegerSelection(name,
			ntaBuilder.createLiteralExpression(min.toString),
			ntaBuilder.createLiteralExpression(max.toString)
		)
		
		if (integerValues.size == max - min + 1) {
			// A  continuous range, no need for additional guards
			return new SelectionStruct(selection, null)
		}
		
		val equalities = newArrayList // Filters the "interesting" values from the range
		for (integerValue : integerValues) {
			equalities += ntaBuilder.createEqualityExpression(
				selection, ntaBuilder.createLiteralExpression(integerValue.toString))
		}
		
		val guard = ntaBuilder.wrapIntoOrExpression(equalities)
		
		return new SelectionStruct(selection, guard)
	}
	
	def dispatch SelectionStruct createSelection(ArrayTypeDefinition type, VariableDeclaration variable) {
		throw new IllegalArgumentException("Array havoc is not supported: " + type)
	}
	
	// Auxiliary structures
	
	@Data
	static class SelectionStruct {
		Selection selection
		Expression guard
	}
	
	static class Namings {
				
		static int id		
		def static String getName() '''_«id++»_«id.hashCode»'''
		
	}
	
}