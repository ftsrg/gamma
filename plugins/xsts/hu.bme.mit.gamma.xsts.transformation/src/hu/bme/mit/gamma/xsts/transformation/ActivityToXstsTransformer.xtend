/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.activity.model.NamedActivityDeclaration
import hu.bme.mit.gamma.lowlevel.xsts.transformation.LowlevelActivityToXstsTransformer
import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.ActionOptimizer
import hu.bme.mit.gamma.statechart.lowlevel.model.Package
import hu.bme.mit.gamma.statechart.lowlevel.transformation.GammaToLowlevelTransformer
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collections
import java.util.logging.Level
import java.util.logging.Logger

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class ActivityToXstsTransformer {
	protected final GammaToLowlevelTransformer gammaToLowlevelTransformer = new GammaToLowlevelTransformer
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ActionOptimizer actionSimplifier = ActionOptimizer.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected boolean optimize
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	new(boolean optimize) {
		this.optimize = optimize
	}
		
	def execute(hu.bme.mit.gamma.statechart.interface_.Package _package) {
		logger.log(Level.INFO, "Starting main execution of Activity-XSTS transformation")
		val activity = _package.activities.head as NamedActivityDeclaration
		val lowlevelPackage = gammaToLowlevelTransformer.transform(_package) 
		val xSts = activity.transform(lowlevelPackage) 
		xSts.removeDuplicatedTypes
		xSts.optimize
		return xSts
	}
		
	protected def XSTS transform(NamedActivityDeclaration activity, Package lowlevelPackage) {
		logger.log(Level.INFO, "Transforming activity " + activity.name)
		val lowlevelActivity = gammaToLowlevelTransformer.transform(activity)
		lowlevelPackage.activities += lowlevelActivity
		val lowlevelToXSTSTransformer = new LowlevelActivityToXstsTransformer(lowlevelPackage, optimize)
 		val xStsEntry = lowlevelToXSTSTransformer.execute
		lowlevelPackage.activities -= lowlevelActivity
		val xSts = xStsEntry.key
		for (variable : xSts.variableDeclarations) {
			val type = variable.type
			variable.expression = type.defaultExpression
		}
		return xSts
	}
	
	protected def removeDuplicatedTypes(XSTS xSts) {
		val types = xSts.typeDeclarations
		for (var i = 0; i < types.size - 1; i++) {
			val lhs = types.get(i)
			for (var j = i + 1; j < types.size; j++) {
				val rhs = types.get(j)
				if (lhs.helperEquals(rhs)) {
					lhs.changeAllAndDelete(rhs, xSts)
					j--
				}
			}
		}
		val typeDeclarationNames = types.map[it.name]
		val duplications = typeDeclarationNames.filter[Collections.frequency(typeDeclarationNames, it) > 1].toList
		logger.log(Level.INFO, "The XSTS contains multiple type declarations with the same name:" + duplications)
		var id = 0
		for (type : types) {
			val typeName = type.name
			if (duplications.contains(typeName)) {
				type.name = typeName + id++
			}
		}
	}
	
	protected def optimize(XSTS xSts) {
		logger.log(Level.INFO, "Optimizing reset, environment and merged actions in " + xSts.name)
		xSts.variableInitializingTransition = xSts.variableInitializingTransition.optimize
		xSts.configurationInitializingTransition = xSts.configurationInitializingTransition.optimize
		xSts.entryEventTransition = xSts.entryEventTransition.optimize
		xSts.inEventTransition = xSts.inEventTransition.optimize
		xSts.outEventTransition = xSts.outEventTransition.optimize
		xSts.changeTransitions(xSts.transitions.optimize)
	}
	
}
