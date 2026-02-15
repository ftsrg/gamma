/********************************************************************************
 * Copyright (c) 2023-2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scxml.transformation

import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.util.ExpressionTypeDeterminator2
import hu.bme.mit.gamma.scxml.transformation.parse.ScxmlGammaExpressionLanguageLinker
import hu.bme.mit.gamma.scxml.transformation.parse.ScxmlGammaExpressionLanguageParser
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.phase.PhaseModelFactory
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.logging.Logger

abstract class AbstractTransformer {

	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
//	protected final extension ActionUtil actionUtil = ActionUtil.INSTANCE
//	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE

	protected final extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	protected final extension CompositeModelFactory compositeModelFactory = CompositeModelFactory.eINSTANCE
	protected final extension StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	protected final extension PhaseModelFactory phaseModelFactory = PhaseModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionModelFactory = ActionModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE

	protected final ScxmlGammaExpressionLanguageParser expressionLanguageParser = new ScxmlGammaExpressionLanguageParser()
	protected final ScxmlGammaExpressionLanguageLinker expressionLanguageLinker = new ScxmlGammaExpressionLanguageLinker()
	protected final ExpressionTypeDeterminator2 expressionTypeDeterminator = ExpressionTypeDeterminator2.INSTANCE

	protected final Logger logger = Logger.getLogger("GammaLogger")

}
