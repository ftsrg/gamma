package hu.bme.mit.gamma.xsts.transformation.util

import hu.bme.mit.gamma.activity.derivedfeatures.ActivityModelDerivedFeatures
import hu.bme.mit.gamma.activity.model.ControlFlow
import hu.bme.mit.gamma.activity.model.DataFlow
import hu.bme.mit.gamma.activity.model.Pin
import hu.bme.mit.gamma.activity.model.DataNode

class XstsNamings {
	
	static def String getTypeName(String lowlevelName) '''«lowlevelName»'''
	static def String getVariableName(String lowlevelName) '''«lowlevelName»'''
	static def String getEventName(String lowlevelName) '''«lowlevelName»'''
	
	static def String getStateEnumLiteralName(String lowlevelName) '''«lowlevelName»'''
	static def String getRegionTypeName(String lowlevelName) '''«lowlevelName.toFirstUpper»'''
	static def String getRegionVariableName(String lowlevelName) '''«lowlevelName.toFirstLower»'''
	
	static def String getActivityNodeVariableName(String name) '''activity_«name»_node_state'''	
	static def String getPinVariableName(Pin pin) '''activity_data_token_«pin.name»'''
	static dispatch def String getFlowVariableName(ControlFlow flow) '''activity_control_flow_from_«flow.sourceNode.name»_to_«flow.targetNode.name»_state'''
	static dispatch def String getFlowVariableName(DataFlow flow) '''activity_data_flow_from_«ActivityModelDerivedFeatures.getSourceNode(flow).name»_to_«ActivityModelDerivedFeatures.getTargetNode(flow).name»_state'''
	static def String getFlowDataTokenVariableName(DataFlow flow) '''«flow.flowVariableName»_data_token'''
	static def String nodeDataTokenVariableName(DataNode node) '''«node.name.activityNodeVariableName»_data'''
	
}
