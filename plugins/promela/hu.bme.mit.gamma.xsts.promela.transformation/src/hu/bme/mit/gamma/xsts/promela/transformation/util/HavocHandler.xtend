package hu.bme.mit.gamma.xsts.promela.transformation.util

import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.PredicateHandler
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.ArrayList

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class HavocHandler {
	// Singelton
	public static final HavocHandler INSTANCE = new HavocHandler
	protected new() {}
	
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension PredicateHandler predicateHandler = PredicateHandler.INSTANCE
	
	def ArrayList<String> createSet(VariableDeclaration variable) {
		val type = variable.type
		return type.createSet(variable)
	}
	
	def dispatch ArrayList<String> createSet(TypeReference type, VariableDeclaration variable) {
		val typeDefinition = type.typeDefinition
		return typeDefinition.createSet(variable)
	}
	
	def dispatch createSet(BooleanTypeDefinition type, VariableDeclaration variable) {
		var list = newArrayList
		list.add("true")
		list.add("false")
		return list
	}
	
	def dispatch createSet(EnumerationTypeDefinition type, VariableDeclaration variable) {
		var list = newArrayList
		for (literal : type.literals) {
			list.add(type.typeDeclaration.name + literal.name)
		}
		return list
	}
	
	def dispatch createSet(IntegerTypeDefinition type, VariableDeclaration variable) {
		var list = newArrayList
		val root = variable.root
		
		val integerValues = root.calculateIntegerValues(variable)
		
		if (integerValues.empty) {
			// Sometimes input parameters are not referenced
			list.add("0")
			return list
		}
		
		for (i : integerValues)
			list.add(i.toString)
		
		return list
	}
}