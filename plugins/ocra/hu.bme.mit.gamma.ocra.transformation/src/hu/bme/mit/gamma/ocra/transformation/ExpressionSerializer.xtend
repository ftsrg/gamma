package hu.bme.mit.gamma.ocra.transformation;

import hu.bme.mit.gamma.expression.model.*;


class ExpressionSerializer {
		    
    def dispatch String serializeExpression(Expression expression) {
    	throw new IllegalArgumentException("Not known expression: " + expression)	
    }
    
    def dispatch String serializeExpression(TrueExpression expression) '''true'''
    
    def dispatch String serializeExpression(FalseExpression expression) '''false'''
    
    def dispatch String serializeExpression(DirectReferenceExpression expression) '''«expression.declaration.name»'''
    
    def dispatch String serializeExpression(IntegerLiteralExpression expression) '''«expression.getValue.toString»'''
    
    def dispatch String serializeExpression(RationalLiteralExpression expression) ''''''
    
    def dispatch String serializeExpression(OrExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' or '»«operand.serializeExpression»«ENDFOR»)'''

	def dispatch String serializeExpression(XorExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' xor '»«operand.serializeExpression»«ENDFOR»)'''

	def dispatch String serializeExpression(AndExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' and '»«operand.serializeExpression»«ENDFOR»)'''

	def dispatch String serializeExpression(ImplyExpression expression) '''(«expression.leftOperand.serializeExpression» -> «expression.rightOperand.serializeExpression»)''' //??

	def dispatch String serializeExpression(EqualityExpression expression) '''(«expression.leftOperand.serializeExpression» = «expression.rightOperand.serializeExpression»)''' //??

	def dispatch String serializeExpression(IfThenElseExpression expression) '''((«expression.condition.serializeExpression») ? («expression.then.serializeExpression») : («expression.^else.serializeExpression»))'''    
    
    
}