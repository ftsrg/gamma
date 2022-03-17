package hu.bme.mit.gamma.xsts.promela.transformation.util

import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import java.util.ArrayList
import java.util.Set
import org.eclipse.emf.ecore.EObject
import hu.bme.mit.gamma.expression.model.PredicateExpression
import hu.bme.mit.gamma.expression.model.BinaryExpression

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.LessEqualExpression
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression
import hu.bme.mit.gamma.expression.model.LessExpression
import hu.bme.mit.gamma.expression.model.GreaterExpression
import hu.bme.mit.gamma.expression.model.InequalityExpression

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
	
	static class PredicateHandler {
		// Singleton
		public static final PredicateHandler INSTANCE = new PredicateHandler
		protected new() {}
		//
		
		protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
		protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
		protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
		
		protected def int getIntegerValue(BinaryExpression predicate, VariableDeclaration variable) {
			val left = predicate.leftOperand
			val right = predicate.rightOperand
			
			if (left instanceof ReferenceExpression) {
				val declaration = left.declaration
				if (declaration === variable) {
					return right.evaluateInteger
				}
			}
			else if (right instanceof ReferenceExpression) {
				val declaration = right.declaration
				if (declaration === variable) {
					return left.evaluateInteger
				}
			}
			
			throw new IllegalArgumentException("No referenced variable")
		}
		
		// Should handle intervals, this is just an initial iteration
		
		def dispatch int calculateIntegerValue(EqualityExpression predicate, VariableDeclaration variable) {
			return predicate.getIntegerValue(variable)
		}
		
		def dispatch int calculateIntegerValue(LessEqualExpression predicate, VariableDeclaration variable) {
			return predicate.getIntegerValue(variable)
		}
		
		def dispatch int calculateIntegerValue(GreaterEqualExpression predicate, VariableDeclaration variable) {
			return predicate.getIntegerValue(variable)
		}
		
		def dispatch int calculateIntegerValue(LessExpression predicate, VariableDeclaration variable) {
			val value = predicate.getIntegerValue(variable)
			val left = predicate.leftOperand
			return (left instanceof ReferenceExpression) ? value - 1 : value + 1
		}
		
		def dispatch int calculateIntegerValue(GreaterExpression predicate, VariableDeclaration variable) {
			val value = predicate.getIntegerValue(variable)
			val left = predicate.leftOperand
			return (left instanceof ReferenceExpression) ? value + 1 : value - 1
		}
		
		def dispatch int calculateIntegerValue(InequalityExpression predicate, VariableDeclaration variable) {
			return predicate.getIntegerValue(variable) - 1
		}
		
		///
		
		def Set<Integer> calculateIntegerValues(EObject root, VariableDeclaration variable) {
			val integerValues = newHashSet
			val predicates = root.getAllContentsOfType(PredicateExpression).filter(BinaryExpression)
			
			for (predicate : predicates) {
				try {
					integerValues += predicate.calculateIntegerValue(variable)
				} catch (IllegalArgumentException e) {
					// Predicate does not contain variable references
				}
			}
			
			return integerValues
		}
	}
}