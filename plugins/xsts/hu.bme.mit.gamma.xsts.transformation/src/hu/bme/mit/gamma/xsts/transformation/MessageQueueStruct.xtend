package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import org.eclipse.xtend.lib.annotations.Data

@Data
class MessageQueueStruct {
	
	VariableDeclaration arrayVariable // Integer array
	VariableDeclaration sizeVariable // Integer
	
}