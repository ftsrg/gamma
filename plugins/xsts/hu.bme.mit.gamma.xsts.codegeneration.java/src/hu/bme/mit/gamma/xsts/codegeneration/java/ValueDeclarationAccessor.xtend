package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.codegenerator.java.util.TypeSerializer
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition
import hu.bme.mit.gamma.expression.model.TypeDefinition
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.ExpressionTypeDeterminator3
import hu.bme.mit.gamma.expression.util.FieldHierarchy
import hu.bme.mit.gamma.expression.util.IndexHierarchy
import hu.bme.mit.gamma.statechart.interface_.Port
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class ValueDeclarationAccessor {
	// Singleton
	public static final ValueDeclarationAccessor INSTANCE = new ValueDeclarationAccessor
	protected new() {}
	//
	protected final extension ExpressionTypeDeterminator3 expressionTypeDeterminator = ExpressionTypeDeterminator3.INSTANCE
	protected final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	
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
		val type = declaration.typeDefinition
		val fieldHierachies = type.fieldHierarchies
		checkState(fieldHierachies.size == fieldNames.size)
		val fields = newArrayList
		for (var i = 0; i < fieldHierachies.size; i++) {
			fields += fieldHierachies.get(i) -> fieldNames.get(i)
		}
		return objectId.access(type, fields, new IndexHierarchy)
	}
	
	protected def String access(String id, TypeDefinition type,
			List<Pair<FieldHierarchy, String>> fields, IndexHierarchy indexes) {
		if (type.native) {
			checkState(fields.size == 1)
			val field = fields.head
			val name = field.value
			return '''«id».get«name.toFirstUpper»()«indexes.access»'''
		}
		if (type instanceof RecordTypeDefinition) {
			return '''
				new «type.typeDeclaration.name»(
					«FOR field : type.fieldDeclarations SEPARATOR ", "»
						«id.access(field.typeDefinition, fields
							.filter[it.key.first === field]
							.map[val newKey = it.key.clone // Cloning is crucial as fields can be reused in arrays
								newKey.removeFirst
								newKey -> value
							].toList,
							indexes
						)»
					«ENDFOR»
				)'''
		}
		if (type instanceof ArrayTypeDefinition) {
			val elementType = type.elementType.typeDefinition
			if (elementType.native) {
				return id.access(elementType, fields, indexes)
			}
			checkState(elementType.complex)
			val size = type.size.evaluateInteger
			return '''
				new «type.serialize» {
					«FOR i : 0 ..< size SEPARATOR ', '»
						«id.access(elementType, fields,	{
								val newIndexes = indexes.clone
								newIndexes.add(i)
								newIndexes
							}
						)»
					«ENDFOR»
				}'''
		}
	}
	
	private def String access(IndexHierarchy indexes) '''«FOR index : indexes.indexes»[«index»]«ENDFOR»'''
	
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
		if (type instanceof ArrayTypeDefinition) {
			return '''throw new UnsupportedOperationException()'''
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