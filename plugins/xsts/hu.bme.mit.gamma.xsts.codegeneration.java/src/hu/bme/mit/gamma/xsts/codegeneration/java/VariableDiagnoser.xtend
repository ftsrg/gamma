package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.xsts.model.model.ComponentParameterGroup
import hu.bme.mit.gamma.xsts.model.model.InEventGroup
import hu.bme.mit.gamma.xsts.model.model.InEventParameterGroup
import hu.bme.mit.gamma.xsts.model.model.OutEventGroup
import hu.bme.mit.gamma.xsts.model.model.OutEventParameterGroup
import hu.bme.mit.gamma.xsts.model.model.PlainVariableGroup
import hu.bme.mit.gamma.xsts.model.model.RegionGroup
import hu.bme.mit.gamma.xsts.model.model.TimeoutGroup
import hu.bme.mit.gamma.xsts.model.model.XSTS
import hu.bme.mit.gamma.expression.model.EnumerableTypeDefinition
import hu.bme.mit.gamma.expression.model.TypeReference

class VariableDiagnoser {
	
	def retrieveInEvents(XSTS xSts) {
		return xSts.variableGroups
				.filter[it.annotation instanceof InEventGroup]
				.map[it.variables]
				.flatten
				.filter(VariableDeclaration)
	}
	
	def retrieveOutEvents(XSTS xSts) {
		return xSts.variableGroups
				.filter[it.annotation instanceof OutEventGroup]
				.map[it.variables]
				.flatten
				.filter(VariableDeclaration)
	}
	
	def retrieveInEventParameters(XSTS xSts) {
		return xSts.variableGroups
				.filter[it.annotation instanceof InEventParameterGroup]
				.map[it.variables]
				.flatten
				.filter(VariableDeclaration)
	}
	
	def retrieveOutEventParameters(XSTS xSts) {
		return xSts.variableGroups
				.filter[it.annotation instanceof OutEventParameterGroup]
				.map[it.variables]
				.flatten
				.filter(VariableDeclaration)
	}
	
	def retrieveTimeouts(XSTS xSts) {
		return xSts.variableGroups
				.filter[it.annotation instanceof TimeoutGroup]
				.map[it.variables]
				.flatten
	}
	
	def retrieveNotTimeoutVariables(XSTS xSts) {
		return xSts.variableGroups
				.filter[!(it.annotation instanceof TimeoutGroup)]
				.map[it.variables]
				.flatten
	}
	
	def retrieveRegionVariables(XSTS xSts) {
		return xSts.variableGroups
				.filter[it.annotation instanceof RegionGroup]
				.map[it.variables]
				.flatten
	}
	
	def retrieveComponentParameters(XSTS xSts) {
		return xSts.variableGroups
				.filter[it.annotation instanceof ComponentParameterGroup]
				.map[it.variables]
				.flatten
	}
	
	def retrievePlainVariables(XSTS xSts) {
		return xSts.variableGroups
				.filter[it.annotation instanceof PlainVariableGroup]
				.map[it.variables]
				.flatten
	}
	
	def retrieveEnumVariables(XSTS xSts) {
		return xSts.retrieveNotTimeoutVariables
				.filter[it.type instanceof EnumerableTypeDefinition || 
					type instanceof TypeReference &&
						(type as TypeReference).reference.type instanceof EnumerableTypeDefinition
				]
	}
	
}