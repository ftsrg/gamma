package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory

class ActivityLiterals {

	// Singleton
	public static final ActivityLiterals INSTANCE = new ActivityLiterals();
	protected new() {}
	//
	
	// Model factories
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	
	public val idleNodeStateEnumLiteral = createEnumerationLiteralDefinition => [
		name = Namings.IDLE_NODE_STATE_ENUM_LITERAL
	]
	public val runningNodeStateEnumLiteral = createEnumerationLiteralDefinition => [
		name = Namings.RUNNING_NODE_STATE_ENUM_LITERAL
	]
	public val doneNodeStateEnumLiteral = createEnumerationLiteralDefinition => [
		name = Namings.DONE_NODE_STATE_ENUM_LITERAL
	]
	public val nodeStateEnumType = createEnumerationTypeDefinition => [
		literals += idleNodeStateEnumLiteral
		literals += runningNodeStateEnumLiteral
		literals += doneNodeStateEnumLiteral
	]
	public val nodeStateEnumTypeDeclaration = createTypeDeclaration => [
		type = nodeStateEnumType
		name = "ActivityNodeState"
	]
	
	public val emptyFlowStateEnumLiteral = createEnumerationLiteralDefinition => [
		name = Namings.EMPTY_FLOW_STATE_ENUM_LITERAL
	]
	public val fullFlowStateEnumLiteral = createEnumerationLiteralDefinition => [
		name = Namings.FULL_FLOW_STATE_ENUM_LITERAL
	]
	public val flowStateEnumType = createEnumerationTypeDefinition => [
		literals += emptyFlowStateEnumLiteral
		literals += fullFlowStateEnumLiteral
	]
	public val flowStateEnumTypeDeclaration = createTypeDeclaration => [
		type = flowStateEnumType
		name = "FlowState"
	]
	
}