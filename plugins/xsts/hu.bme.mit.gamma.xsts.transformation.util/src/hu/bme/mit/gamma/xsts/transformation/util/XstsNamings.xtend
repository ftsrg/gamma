package hu.bme.mit.gamma.xsts.transformation.util

import hu.bme.mit.gamma.statechart.lowlevel.model.ActivityNode
import hu.bme.mit.gamma.statechart.lowlevel.model.Succession

class XstsNamings {
	
	static def String getTypeName(String lowlevelName) '''«lowlevelName»'''
	static def String getVariableName(String lowlevelName) '''«lowlevelName»'''
	static def String getEventName(String lowlevelName) '''«lowlevelName»'''
	
	static def String getStateEnumLiteralName(String lowlevelName) '''«lowlevelName»'''
	static def String getRegionTypeName(String lowlevelName) '''«lowlevelName.toFirstUpper»'''
	static def String getRegionVariableName(String lowlevelName) '''«lowlevelName.toFirstLower»'''
	
	static def String getActivityNodeVariableName(ActivityNode node) '''«node.name»'''	
	static def String getSuccessionVariableName(Succession succession) '''«succession.sourceNode.name»_to_«succession.targetNode.name»'''
	
}
