/********************************************************************************
 * Copyright (c) 2024 Contributors to the Gamma project
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
import java.util.Map

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.iml.transformation.util.Namings.*

class ModelSerializer {
	// Singleton
	public static ModelSerializer INSTANCE = new ModelSerializer
	protected new() {}
	//
	
	protected final Map<NonDeterministicAction, String> nonDeterministicActionVariables = newHashMap
	
	//
	protected final extension DeclarationSerializer declarationSerializer = DeclarationSerializer.INSTANCE
	protected final extension ActionSerializer actionSerializer = ActionSerializer.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension XstsOptimizer xStsOptimizer = XstsOptimizer.INSTANCE
	//
	
	def String serializeIml(XSTS xSts) {
		val globalVariables = xSts.variableDeclarations
		
		val localVariables = xSts.mergedAction
						.getSelfAndAllContentsOfType(VariableDeclarationAction)
						.map[it.variableDeclaration]
						
		val initLocalVariables = xSts.initializingAction
						.getSelfAndAllContentsOfType(VariableDeclarationAction)
						.map[it.variableDeclaration]
		
		val envLocalVariables = xSts.environmentalAction
						.getSelfAndAllContentsOfType(VariableDeclarationAction)
						.map[it.variableDeclaration]
		
		val inEventAction = xSts.inEventTransition.action // Must match the object of envHavocs in the record and the env func
		val outEventAction = xSts.outEventTransition.action
		
		val envHavocs = inEventAction
						.getSelfAndAllContentsOfType(HavocAction)
						
		val choices = xSts.getAllContentsOfType(NonDeterministicAction)
		
		val model = '''
			«FOR typeDeclaration : xSts.typeDeclarations»
				«typeDeclaration.serializeTypeDeclaration»
			«ENDFOR»
		
			type nonrec «GLOBAL_RECORD_TYPE_NAME» = {
				«FOR variableDeclaration : globalVariables»
					«variableDeclaration.serializeFieldDeclaration»
				«ENDFOR»
				«FOR choice : choices»
					«choice.customizeChoice» : int;
				«ENDFOR»
			}
			
			«IF !localVariables.empty»
			type nonrec «LOCAL_RECORD_TYPE_NAME» = {
				«FOR variableDeclaration : localVariables»
					«variableDeclaration.serializeFieldDeclaration»
				«ENDFOR»
			}
			«ENDIF»
			
			«IF !initLocalVariables.empty»
				type nonrec «INIT_LOCAL_RECORD_TYPE_NAME» = {
					«FOR variableDeclaration : initLocalVariables»
						«variableDeclaration.serializeFieldDeclaration»
					«ENDFOR»
				}
			«ENDIF»
			
			«IF !envLocalVariables.empty»
				type nonrec «ENV_LOCAL_RECORD_TYPE_NAME» = {
					«FOR variableDeclaration : envLocalVariables»
						«variableDeclaration.serializeFieldDeclaration»
					«ENDFOR»
				}
			«ENDIF»
			
			«IF !envHavocs.empty»
				type nonrec «ENV_HAVOC_RECORD_TYPE_NAME» = {
					«FOR envHavoc : envHavocs»
						«envHavoc.serializeEnvFieldDeclaration»
					«ENDFOR»
					«FOR choice : choices»
						«choice.customizeChoice» : int;
					«ENDFOR»
				}
			«ENDIF»
			
			let init =
				«globalVariables.initVariables(choices, globalVariableName)»
				«initLocalVariables.initVariablesIfNotEmpty(LOCAL_RECORD_IDENTIFIER)»
				«xSts.initializingAction.optimizeAction.serializeActionGlobally»
			
			let trans («globalVariableName» : «GLOBAL_RECORD_TYPE_NAME») =
				«localVariables.initVariablesIfNotEmpty(LOCAL_RECORD_IDENTIFIER)»
				«xSts.mergedAction.serializeActionGlobally»
				
			let env («globalVariableName» : «GLOBAL_RECORD_TYPE_NAME») («ENV_HAVOC_RECORD_IDENTIFIER» : «ENV_HAVOC_RECORD_TYPE_NAME») =
				«envLocalVariables.initVariablesIfNotEmpty(LOCAL_RECORD_IDENTIFIER)»
				«#[inEventAction, outEventAction].serializeActionsGlobally»
				
			let run_cycle («globalVariableName» : «GLOBAL_RECORD_TYPE_NAME») («ENV_HAVOC_RECORD_IDENTIFIER» : «ENV_HAVOC_RECORD_TYPE_NAME») =
				«IF !choices.empty»
					«globalVariableDeclaration»{ «globalVariableName» with «FOR choice : choices»«choice.customizeChoice» = «ENV_HAVOC_RECORD_IDENTIFIER».«choice.customizeChoice»; «ENDFOR»} in
				«ENDIF»
				«globalVariableDeclaration»env «globalVariableName» «ENV_HAVOC_RECORD_IDENTIFIER» in
				«globalVariableDeclaration»trans «globalVariableName» in
				«IF !choices.empty»
					«globalVariableDeclaration»{ «globalVariableName» with «FOR choice : choices»«choice.customizeChoice» = 0; «ENDFOR»} (* Optimization *) in
				«ENDIF»
				«globalVariableName»
				
			let rec run («globalVariableName» : «GLOBAL_RECORD_TYPE_NAME») («ENV_HAVOC_RECORD_IDENTIFIER» : «ENV_HAVOC_RECORD_TYPE_NAME» list) =
				match «ENV_HAVOC_RECORD_IDENTIFIER» with
					| [] -> «globalVariableName»
					| hd :: tl ->
						«globalVariableDeclaration»run_cycle «globalVariableName» hd in
						run «globalVariableName» tl
		'''
		
		return model
	}
	
	//
	
}