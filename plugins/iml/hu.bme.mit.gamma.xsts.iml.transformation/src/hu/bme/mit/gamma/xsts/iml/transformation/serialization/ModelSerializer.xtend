/********************************************************************************
 * Copyright (c) 2024-2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.iml.transformation.serialization

import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.XstsOptimizer
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XstsActionUtil

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.iml.transformation.util.Namings.*

class ModelSerializer {
	// Singleton
	public static ModelSerializer INSTANCE = new ModelSerializer
	protected new() {}
	//
	
	protected final extension ActionSerializer actionSerializer = new ActionSerializer // For code hoisting
	
	protected final extension XstsValidator validator = XstsValidator.INSTANCE
	//
	protected final extension DeclarationSerializer declarationSerializer = DeclarationSerializer.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension XstsOptimizer xStsOptimizer = XstsOptimizer.INSTANCE
	//
	
	def String serializeIml(XSTS xSts) {
		return xSts.serializeIml(false)
	}
	
	def String serializeIml(XSTS xSts, boolean optimizeNonDet) {
		actionSerializer.clearActions
		actionSerializer.setOptimizeNonDet = optimizeNonDet
		
		xSts.validate
		
		// Initialization (and potentially other in the future) optimization here - removing local variables later would mess up the 'unique naming'
		xSts.optimizeInitalizationTransition // Probably not necessary
		
		val globalVariables = xSts.variableDeclarations
		
		val localVariables = xSts.mergedAction
						.getSelfAndAllContentsOfType(VariableDeclarationAction)
						.map[it.variableDeclaration]
						
		val initLocalVariables = xSts.initializingAction
						.getSelfAndAllContentsOfType(VariableDeclarationAction)
						.map[it.variableDeclaration]
		
		val inEventAction = xSts.inEventTransition.action // Must match the object of envHavocs in the record and the env func
		val outEventAction = xSts.outEventTransition.action
		
		val envLocalVariables = #[inEventAction, outEventAction].map[
						it.getSelfAndAllContentsOfType(VariableDeclarationAction)
						.map[it.variableDeclaration]]
						.flatten
		
		val envHavocs = inEventAction
						.getSelfAndAllContentsOfType(HavocAction)
		val transHavocs = xSts.mergedAction
						.getSelfAndAllContentsOfType(HavocAction) // Optimization: could be a set if there are no havocs in the same blocks
		val havocs = envHavocs + transHavocs
		actionSerializer.setHasTransHavoc = !transHavocs.empty
						
		val choices = xSts.getAllContentsOfType(NonDeterministicAction)
		val needNonDet = !optimizeNonDet && !choices.empty // Map non-det choices in a sound way
		//
		
		val types = '''
			«FOR typeDeclaration : xSts.typeDeclarations AFTER System.lineSeparator»
				«typeDeclaration.serializeTypeDeclaration»
			«ENDFOR»
			«TYPE» «GLOBAL_RECORD_TYPE_NAME» = {
				«FOR variableDeclaration : globalVariables»
					«variableDeclaration.serializeFieldDeclaration»
				«ENDFOR»
				«FOR choice : choices»
					«choice.customizeChoice» : int;
				«ENDFOR»
			}
			
			«IF !localVariables.empty»
				«TYPE» «LOCAL_RECORD_TYPE_NAME» = {
					«FOR variableDeclaration : localVariables»
						«variableDeclaration.serializeFieldDeclaration»
					«ENDFOR»
				}
				
			«ENDIF»
			«IF !initLocalVariables.empty»
				«TYPE» «INIT_LOCAL_RECORD_TYPE_NAME» = {
					«FOR variableDeclaration : initLocalVariables»
						«variableDeclaration.serializeFieldDeclaration»
					«ENDFOR»
				}
				
			«ENDIF»
			«IF !envLocalVariables.empty»
				«TYPE» «ENV_LOCAL_RECORD_TYPE_NAME» = {
					«FOR variableDeclaration : envLocalVariables»
						«variableDeclaration.serializeFieldDeclaration»
					«ENDFOR»
				}
				
			«ENDIF»
			«TYPE» «ENV_HAVOC_RECORD_TYPE_NAME» = {
				«FOR envHavoc : havocs»
					«envHavoc.serializeEnvFieldDeclaration»
				«ENDFOR»
				«IF havocs.empty» _ph : bool; (* Placeholder *) «ENDIF»
				«FOR choice : choices»
					«choice.customizeChoice» : int;
				«ENDFOR»
			}
			
			«IF needNonDet»
				«TYPE» «NONDET_BRANCH_TYPE_NAME» = «FOR i : 0 ..< choices.map[it.actions.size].max SEPARATOR ' | '»«i.branchLiteralName»«ENDFOR»
			«ENDIF»
		'''
		
		val init = '''
			let «INIT_FUNCTION_IDENTIFIER» =
				«globalVariables.initVariables(choices, globalVariableName)»
				«initLocalVariables.initVariablesIfNotEmpty(LOCAL_RECORD_IDENTIFIER)»
				«xSts.initializingAction.serializeActionGlobally»
		'''
		
		actionSerializer.hoistBranches = true // Hoisting 'trans'
		val trans = '''
			let trans («globalVariableName» : «GLOBAL_RECORD_TYPE_NAME») «IF actionSerializer.getHasTransHavoc»(«ENV_HAVOC_RECORD_IDENTIFIER» : «ENV_HAVOC_RECORD_TYPE_NAME») «ENDIF»=
				«localVariables.initVariablesIfNotEmpty(LOCAL_RECORD_IDENTIFIER)»
				«xSts.mergedAction.serializeActionIntermediate»
				«IF !choices.empty /* Here, instead of run_cycle to support semantic diff? */»
					«globalVariableDeclaration»{ «globalVariableName» with «FOR choice : choices»«choice.customizeChoice» = 0; «ENDFOR»} (* Optimization *) in
				«ENDIF»
				«globalVariableName»
		'''
		val hoistedFunctions = actionSerializer.hoistedFunctions
		actionSerializer.hoistBranches = false // We do not want to hoist 'env'
		
		val env = '''
			let env («globalVariableName» : «GLOBAL_RECORD_TYPE_NAME») («ENV_HAVOC_RECORD_IDENTIFIER» : «ENV_HAVOC_RECORD_TYPE_NAME») =
				«envLocalVariables.initVariablesIfNotEmpty(LOCAL_RECORD_IDENTIFIER)»
				«#[inEventAction, outEventAction].serializeActionsGlobally»
		'''
		
		val run = '''
			let «SINGLE_RUN_FUNCTION_IDENTIFIER» («globalVariableName» : «GLOBAL_RECORD_TYPE_NAME») («ENV_HAVOC_RECORD_IDENTIFIER» : «ENV_HAVOC_RECORD_TYPE_NAME») =
				«IF !choices.empty»
					«globalVariableDeclaration»{ «globalVariableName» with «FOR choice : choices»«choice.customizeChoice» = «ENV_HAVOC_RECORD_IDENTIFIER».«choice.customizeChoice»; «ENDFOR»} in
				«ENDIF»
				«globalVariableDeclaration»env «globalVariableName» «ENV_HAVOC_RECORD_IDENTIFIER» in
				«globalVariableDeclaration»trans «globalVariableName» «IF actionSerializer.getHasTransHavoc»«ENV_HAVOC_RECORD_IDENTIFIER» «ENDIF»in
				«globalVariableName»
				
			let rec «RUN_FUNCTION_IDENTIFIER» («globalVariableName» : «GLOBAL_RECORD_TYPE_NAME») («ENV_HAVOC_RECORD_IDENTIFIER» : «ENV_HAVOC_RECORD_TYPE_NAME» list) =
				match «ENV_HAVOC_RECORD_IDENTIFIER» with
					| [] -> «globalVariableName»
					| hd :: tl ->
						«globalVariableDeclaration»«SINGLE_RUN_FUNCTION_IDENTIFIER» «globalVariableName» hd in
						«RUN_FUNCTION_IDENTIFIER» «globalVariableName» tl
			
			let log_«SINGLE_RUN_FUNCTION_IDENTIFIER» («globalVariableName» : «GLOBAL_RECORD_TYPE_NAME») («ENV_HAVOC_RECORD_IDENTIFIER» : «ENV_HAVOC_RECORD_TYPE_NAME») =
							«IF !choices.empty»
								«globalVariableDeclaration»{ «globalVariableName» with «FOR choice : choices»«choice.customizeChoice» = «ENV_HAVOC_RECORD_IDENTIFIER».«choice.customizeChoice»; «ENDFOR»} in
							«ENDIF»
							«globalVariableDeclaration»env «globalVariableName» «ENV_HAVOC_RECORD_IDENTIFIER» in
							let pre_trans_r = «globalVariableName» in
							«globalVariableDeclaration»trans «globalVariableName» «IF actionSerializer.getHasTransHavoc»«ENV_HAVOC_RECORD_IDENTIFIER» «ENDIF»in
							«IF !choices.empty»
								«globalVariableDeclaration»{ «globalVariableName» with «FOR choice : choices»«choice.customizeChoice» = 0; «ENDFOR»} (* Optimization *) in
							«ENDIF»
							pre_trans_r, «globalVariableName»
			
			let rec log_«RUN_FUNCTION_IDENTIFIER» («globalVariableName» : «GLOBAL_RECORD_TYPE_NAME») («ENV_HAVOC_RECORD_IDENTIFIER» : «ENV_HAVOC_RECORD_TYPE_NAME» list) =
				match «ENV_HAVOC_RECORD_IDENTIFIER» with
					| [] -> []
					| hd :: tl ->
						let pre_trans_r, «globalVariableName» = log_«SINGLE_RUN_FUNCTION_IDENTIFIER» «globalVariableName» hd in
						pre_trans_r :: «globalVariableName» :: (log_«RUN_FUNCTION_IDENTIFIER» «globalVariableName» tl)
		'''
		
		val aux = '''
			«IF needNonDet»
				let «PICK_BRANCH_FUNCTION_NAME» («globalVariableName» : «GLOBAL_RECORD_TYPE_NAME») guard (bs : «NONDET_BRANCH_TYPE_NAME» list) (sel : int) : «NONDET_BRANCH_TYPE_NAME» option =
					let rec aux branches candidate n =
						match branches with
						| [] -> candidate
						| b::bs ->
							if guard «globalVariableName» b then (
								if sel = 0 then Some b
								else aux bs (Some b) (n - 1))
							else (
								aux bs candidate (n - 1))
					in
					aux bs None sel
			«ENDIF»
		'''
		
		val functions = '''
			«FOR function : xSts.functionDeclarations»
				«function.serializeFunctionDeclaration»
				
			«ENDFOR»
		'''
		
		return '''
			«types»
			
			«aux»
			
			«functions»
			
			«init»
			
			«hoistedFunctions»
			
			«trans»
			
			«env»
			
			«run»
		'''
	}
	
}