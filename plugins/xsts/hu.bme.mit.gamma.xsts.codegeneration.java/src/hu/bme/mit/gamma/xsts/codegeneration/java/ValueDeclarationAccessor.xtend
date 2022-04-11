package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.codegeneration.java.util.TypeSerializer
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition
import hu.bme.mit.gamma.expression.model.TypeDefinition
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.ExpressionTypeDeterminator2
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
	protected final extension ExpressionTypeDeterminator2 expressionTypeDeterminator = ExpressionTypeDeterminator2.INSTANCE
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
		val fieldPairs = type.formFieldPairs(fieldNames)
		return objectId.access(type, fieldPairs, new IndexHierarchy)
	}
	
	protected def String access(String id, TypeDefinition type,
			List<Pair<FieldHierarchy, String>> fields, IndexHierarchy indexes) {
		if (type.native) {
			checkState(fields.size == 1)
			val field = fields.head
			val name = field.value
			return '''«id».get«name.toFirstUpper»()«indexes.access»'''
		}
		else if (type instanceof RecordTypeDefinition) {
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
		else if (type instanceof ArrayTypeDefinition) {
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
	
	private def formFieldPairs(TypeDefinition type, List<String> fieldNames) {
		val fieldHierachies = type.fieldHierarchies
		checkState(fieldHierachies.size == fieldNames.size)
		val fieldPairs = newArrayList
		for (var i = 0; i < fieldHierachies.size; i++) {
			fieldPairs += fieldHierachies.get(i) -> fieldNames.get(i)
		}
		return fieldPairs
	}
	
	private def String access(IndexHierarchy indexes) '''«FOR index : indexes.indexes»[«index»]«ENDFOR»'''
	
	// Write

	def writeIn(String id, Port port, ParameterDeclaration declaration, String valueId) {
		val type = declaration.typeDefinition
		val names = declaration.customizeInNames(port)
		val accesses = type.accessIn(valueId)
		checkState(names.size == accesses.size)
		return '''
			«FOR i : 0 ..< names.size»
				«id».set«names.get(i).toFirstUpper»(«accesses.get(i)»);
			«ENDFOR»
		'''
	}	
	
	def List<String> accessIn(TypeDefinition type, String valueId) {
		if (type.native) {
			return #['''«valueId»''']
		}
		else if (type instanceof RecordTypeDefinition) {
			val fields = type.fieldDeclarations
			val results = newArrayList
			for (field : fields) {
				val fieldType = field.typeDefinition
				results += fieldType.accessIn('''«valueId».get«field.name.toFirstUpper»()''')
			}
			return results
		}
		else if (type instanceof ArrayTypeDefinition) {
			val elementType = type.elementType.typeDefinition
			val result = <String>newArrayList
			val size = type.size.evaluateInteger
			val temporaryAccesses = <List<String>>newArrayList
			for (var j = 0; j < size; j++) {
				temporaryAccesses += elementType.accessIn('''«valueId»[«j»]''' )
			}
			val sizeOfAccesses = temporaryAccesses.head.size
			// If sizeOfTransformedExpressions == 1: primitive type or array type, no record, one literal is returned
			// Else there is a wrapped record: array of records is transformed into record of arrays
			// Transforming { [1, 2],  [3, 4], [5, 6] } into { [1, 3, 5],  [2, 4, 6] }
			val nativeTypes = type.nativeTypes
			for (var i = 0; i < sizeOfAccesses; i++) {
				result += 
					''' new «nativeTypes.get(i).serialize» {
						«FOR temporaryAccess : temporaryAccesses SEPARATOR ', '»
							«temporaryAccess.get(i)»
						«ENDFOR»
					}'''
			}
			return result
		}
	}
	
}