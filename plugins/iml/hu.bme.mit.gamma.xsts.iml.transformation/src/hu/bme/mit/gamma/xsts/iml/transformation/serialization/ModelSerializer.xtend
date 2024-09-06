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
import hu.bme.mit.gamma.xsts.iml.transformation.util.Namings
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Map

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

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
						
		val model = '''
			«FOR typeDeclaration : xSts.typeDeclarations»
				«typeDeclaration.serializeTypeDeclaration»
			«ENDFOR»
		
			type nonrec «Namings.GLOBAL_RECORD_TYPE_NAME» = {
				«FOR variableDeclaration : globalVariables»
					«variableDeclaration.serializeFieldDeclaration»
				«ENDFOR»
			}
			
			«IF !localVariables.empty»
			type nonrec «Namings.LOCAL_RECORD_TYPE_NAME» = {
				«FOR variableDeclaration : localVariables»
					«variableDeclaration.serializeFieldDeclaration»
				«ENDFOR»
			}
			«ENDIF»
			
			«IF !initLocalVariables.empty»
				type nonrec «Namings.INIT_LOCAL_RECORD_TYPE_NAME» = {
					«FOR variableDeclaration : initLocalVariables»
						«variableDeclaration.serializeFieldDeclaration»
					«ENDFOR»
				}
			«ENDIF»
			
			«IF !envLocalVariables.empty»
				type nonrec «Namings.ENV_LOCAL_RECORD_TYPE_NAME» = {
					«FOR variableDeclaration : envLocalVariables»
						«variableDeclaration.serializeFieldDeclaration»
					«ENDFOR»
				}
			«ENDIF»
			
			«IF !envHavocs.empty»
				type nonrec «Namings.ENV_HAVOC_RECORD_TYPE_NAME» = {
					«FOR envHavoc : envHavocs»
						«envHavoc.serializeEnvFieldDeclaration»
					«ENDFOR»
				}
			«ENDIF»
			
			let init =
				«globalVariables.initVariables(globalVariableName)»
				«initLocalVariables.initVariablesIfNotEmpty(Namings.LOCAL_RECORD_IDENTIFIER)»
				«xSts.initializingAction.optimizeAction.serializeActionGlobally»
			
			let trans («globalVariableName» : «Namings.GLOBAL_RECORD_TYPE_NAME») =
				«localVariables.initVariablesIfNotEmpty(Namings.LOCAL_RECORD_IDENTIFIER)»
				«xSts.mergedAction.serializeActionGlobally»
				
			let env («globalVariableName» : «Namings.GLOBAL_RECORD_TYPE_NAME») («Namings.ENV_HAVOC_RECORD_IDENTIFIER» : «Namings.ENV_HAVOC_RECORD_TYPE_NAME») =
				«envLocalVariables.initVariablesIfNotEmpty(Namings.LOCAL_RECORD_IDENTIFIER)»
				«#[inEventAction, outEventAction].serializeActionsGlobally»
				
			let run_cycle («globalVariableName» : «Namings.GLOBAL_RECORD_TYPE_NAME») («Namings.ENV_HAVOC_RECORD_IDENTIFIER» : «Namings.ENV_HAVOC_RECORD_TYPE_NAME») =
				«globalVariableDeclaration»env «globalVariableName» «Namings.ENV_HAVOC_RECORD_IDENTIFIER» in
				trans «globalVariableName»
				
			let rec run («globalVariableName» : «Namings.GLOBAL_RECORD_TYPE_NAME») («Namings.ENV_HAVOC_RECORD_IDENTIFIER» : «Namings.ENV_HAVOC_RECORD_TYPE_NAME» list) =
				match «Namings.ENV_HAVOC_RECORD_IDENTIFIER» with
					| [] -> «globalVariableName»
					| hd :: tl ->
						«globalVariableDeclaration»run_cycle «globalVariableName» hd in
						run «globalVariableName» tl
		'''
		
		return model
	}
	
	//
	
}