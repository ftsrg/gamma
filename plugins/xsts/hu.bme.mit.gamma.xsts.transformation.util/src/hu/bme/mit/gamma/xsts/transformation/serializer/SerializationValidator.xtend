package hu.bme.mit.gamma.xsts.transformation.serializer

import hu.bme.mit.gamma.expression.model.NamedElement

import static com.google.common.base.Preconditions.checkArgument

class SerializationValidator {
	// Singleton
	public static final SerializationValidator INSTANCE = new SerializationValidator
	protected new() {}
	//
	
	public static val KEYWORDS = #[ 'type', 'ctrl', 'var', 'integer', 'boolean', 'true', 'false', 'if', 'else',
		'par', 'and', 'for', 'from', 'to', 'do', 'choice', 'or', 'local', 'assume', 'havoc',
		'trans', 'init', 'env', 'then', 'default' ]
	
	def validateIdentifier(NamedElement element) {
		val name = element.name
		checkArgument(!KEYWORDS.contains(name), "The identifier of an element must not be an XSTS keyword: " + name)
	}
	
}