package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.expression.util.FieldHierarchy
import hu.bme.mit.gamma.statechart.interface_.Port
import java.util.List
import java.util.Queue

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class ValueDeclarationAccessor {
	// Singleton
	public static final ValueDeclarationAccessor INSTANCE = new ValueDeclarationAccessor
	protected new() {}
	//
	protected final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
	
	// Read
	
	def access(String objectId, VariableDeclaration declaration) {
		return objectId.access(declaration, declaration.customizeNames)
	}
	
	def accessOut(String objectId, Port port, ParameterDeclaration declaration) {
		return objectId.access(declaration, declaration.customizeOutNames(port))
	}
	
	def accessIn(String objectId, Port port, ParameterDeclaration declaration) {
		return objectId.access(declaration, declaration.customizeInNames(port))
	}
	
	def protected access(String objectId, ValueDeclaration declaration, List<String> fieldNames) {
		val Queue<String> names = newLinkedList
		names += fieldNames
		objectId.access(declaration, names)
	}
	
	protected def access(String objectId, ValueDeclaration declaration, Queue<String> fieldNames) {
		val type = declaration.typeDefinition
		if (type.native) {
			return '''«objectId».get«fieldNames.remove.toFirstUpper»()'''
		}
		if (type instanceof RecordTypeDefinition) {
			return '''«objectId.access(type, fieldNames)»'''
		}
	}
	
	protected def String access(String objectId,
			RecordTypeDefinition type, Queue<String> fieldNames) '''
		new «type.typeDeclaration.name»(
			«FOR field : type.fieldDeclarations SEPARATOR ", "»
				«objectId.access(field, fieldNames)»
			«ENDFOR»
		)
	'''
	
	// Write
	
	def writeIn(String objectId, Port port, ParameterDeclaration declaration, String valueId) {
		val type = declaration.typeDefinition
		val fieldNames = declaration.customizeInNames(port)
		if (type.native) {
			return '''«objectId».set«fieldNames.get(0).toFirstUpper»(«valueId»);'''
		}
		if (type instanceof RecordTypeDefinition) {
			val fields = type.fieldHierarchies
			return '''«objectId.write(fieldNames, valueId, fields)»'''
		}
	}
	
	protected def String write(String objectId, List<String> fieldNames,
			String valueId, List<FieldHierarchy> fields) '''
		«FOR i : 0 ..< fieldNames.size»
			«objectId.write(fieldNames.get(i), valueId, fields.get(i))»
		«ENDFOR»
	'''
	
	protected def String write(String objectId, String fieldName,
			String valueId, FieldHierarchy field) '''
		«objectId».set«fieldName.toFirstUpper»(«valueId»«field.fields
			.map['''.get«it.name.toFirstUpper»()'''].join»);
	'''
	
}