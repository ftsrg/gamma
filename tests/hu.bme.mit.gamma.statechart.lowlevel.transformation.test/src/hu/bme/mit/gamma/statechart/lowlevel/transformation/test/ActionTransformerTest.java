package hu.bme.mit.gamma.statechart.lowlevel.transformation.test;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import java.math.BigInteger;

import org.junit.Test;

import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.ActionModelFactory;
import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.action.model.Block;
import hu.bme.mit.gamma.action.model.Branch;
import hu.bme.mit.gamma.action.model.EmptyStatement;
import hu.bme.mit.gamma.action.model.ExpressionStatement;
import hu.bme.mit.gamma.action.model.IfStatement;
import hu.bme.mit.gamma.action.model.ProcedureDeclaration;
import hu.bme.mit.gamma.action.model.ReturnStatement;
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BooleanLiteralExpression;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.FalseExpression;
import hu.bme.mit.gamma.expression.model.FieldAssignment;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.FunctionDeclaration;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.RecordAccessExpression;
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.TrueExpression;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.lowlevel.transformation.GammaToLowlevelTransformer;
import hu.bme.mit.gamma.statechart.statechart.OnCycleTrigger;
import hu.bme.mit.gamma.statechart.statechart.Region;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory;
import hu.bme.mit.gamma.statechart.statechart.Transition;


public class ActionTransformerTest {
	private final StatechartModelFactory statechartFactory = StatechartModelFactory.eINSTANCE;
	private final InterfaceModelFactory interfaceFactory = InterfaceModelFactory.eINSTANCE;
	private final ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE;
	private final ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE;

	private final String simpleIntegerProcedureName = "simpleIntegerProcedure";
	private final TypeDefinition simpleIntegerProcedureReturnType = expressionFactory.createIntegerTypeDefinition();
	private final int simpleIntegerProcedureReturnValue = 2;
	
	//number of assertion variables in the statechart
	private final int assertionOffset = 1;
	
	@Test
	public void testBlockEmptyTransformation() {
		// Arrange
		Block target = actionFactory.createBlock();
		
		Package gammaPackage = createBasicStatechartPackageWithAction(target);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
		
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);
		
		// Assert
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertNotNull(transformedStatechart.getTransitions().get(1));
		hu.bme.mit.gamma.statechart.lowlevel.model.Transition transition = transformedStatechart.getTransitions().get(1);
		assertNotNull(transition.getAction());
		assertTrue(transition.getAction() instanceof EmptyStatement);
	}
	
	@Test
	public void testVariableDeclarationStatementBasicTransformation() {
		// Arrange
		TypeDefinition testType = expressionFactory.createIntegerTypeDefinition();
		VariableDeclaration testVariable = expressionFactory.createVariableDeclaration();
		testVariable.setName("testVariable");
		testVariable.setType(testType);
		VariableDeclarationStatement target = actionFactory.createVariableDeclarationStatement();
		target.setVariableDeclaration(testVariable);
		
		Package gammaPackage = createBasicStatechartPackageWithAction(target);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
		
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);
		
		// Assert
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertNotNull(transformedStatechart.getTransitions().get(1));
		hu.bme.mit.gamma.statechart.lowlevel.model.Transition transition = transformedStatechart.getTransitions().get(1);
		assertNotNull(transition.getAction());
		assertTrue(transition.getAction() instanceof VariableDeclarationStatement);
		VariableDeclarationStatement transformedAction = (VariableDeclarationStatement)transition.getAction();
		assertNotNull(transformedAction.getVariableDeclaration());
		
		assertNotEquals(target, transformedAction);
		assertNotEquals(target.getVariableDeclaration(), transformedAction.getVariableDeclaration());
		assertEquals(target.getVariableDeclaration().getName(), transformedAction.getVariableDeclaration().getName());
		assertEquals(target.getVariableDeclaration().getType().getClass(), transformedAction.getVariableDeclaration().getType().getClass());
		assertNull(transformedAction.getVariableDeclaration().getExpression());
	}
	
	@Test
	public void testVariableDeclarationStatementInitialTransformation() {
		// Arrange
		int testValue = 5;
		IntegerLiteralExpression testExpression = expressionFactory.createIntegerLiteralExpression();
		testExpression.setValue(BigInteger.valueOf(testValue));
		TypeDefinition testType = expressionFactory.createIntegerTypeDefinition();
		VariableDeclaration testVariable = expressionFactory.createVariableDeclaration();
		testVariable.setName("testVariable");
		testVariable.setType(testType);
		testVariable.setExpression(testExpression);
		VariableDeclarationStatement target = actionFactory.createVariableDeclarationStatement();
		target.setVariableDeclaration(testVariable);
		
		Package gammaPackage = createBasicStatechartPackageWithAction(target);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
		
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);
		
		// Assert
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertNotNull(transformedStatechart.getTransitions().get(1));
		hu.bme.mit.gamma.statechart.lowlevel.model.Transition transition = transformedStatechart.getTransitions().get(1);
		assertNotNull(transition.getAction());
		assertTrue(transition.getAction() instanceof VariableDeclarationStatement);
		VariableDeclarationStatement transformedAction = (VariableDeclarationStatement)transition.getAction();
		assertNotNull(transformedAction.getVariableDeclaration());
		assertNotNull(transformedAction.getVariableDeclaration().getExpression());
		assertTrue(transformedAction.getVariableDeclaration().getExpression() instanceof IntegerLiteralExpression);
		IntegerLiteralExpression transformedInitialValue = (IntegerLiteralExpression)transformedAction.getVariableDeclaration().getExpression();
		
		assertNotEquals(target, transformedAction);
		assertNotEquals(target.getVariableDeclaration(), transformedAction.getVariableDeclaration());
		assertEquals(target.getVariableDeclaration().getName(), transformedAction.getVariableDeclaration().getName());
		assertEquals(target.getVariableDeclaration().getType().getClass(), transformedAction.getVariableDeclaration().getType().getClass());
		assertNotEquals(testExpression, transformedInitialValue);
		assertEquals(testExpression.getValue().intValue(), transformedInitialValue.getValue().intValue());
	}
	
	@Test
	public void testVariableDeclarationStatementWithPreconditionTransformation() {
		// Arrange
		ProcedureDeclaration simpleIntegerProcedure = createSimpleIntegerProcedure();

		DirectReferenceExpression functionReference = expressionFactory.createDirectReferenceExpression();
		functionReference.setDeclaration(simpleIntegerProcedure);
		FunctionAccessExpression functionAccess = expressionFactory.createFunctionAccessExpression();
		functionAccess.setOperand(functionReference);

		String testName = "testVariable";
		TypeDefinition testType = expressionFactory.createIntegerTypeDefinition();
		VariableDeclaration testVariable = expressionFactory.createVariableDeclaration();
		testVariable.setName(testName);
		testVariable.setType(testType);
		testVariable.setExpression(functionAccess);
		VariableDeclarationStatement target = actionFactory.createVariableDeclarationStatement();
		target.setVariableDeclaration(testVariable);
		
		Package gammaPackage = createStatechartPackageWithActionAndFunction(target, simpleIntegerProcedure);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
		
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);
		
		// Assert
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertNotNull(transformedStatechart.getTransitions().get(1));
		hu.bme.mit.gamma.statechart.lowlevel.model.Transition transition = transformedStatechart.getTransitions().get(1);
		assertNotNull(transition.getAction());
		assertTrue(transition.getAction() instanceof Block);
		Block transformedAction = (Block)transition.getAction();
		assertTrue(transformedAction.getActions().size() == 3);
		
		assertTrue(transformedAction.getActions().get(0) instanceof VariableDeclarationStatement);
		VariableDeclarationStatement returnVariable = (VariableDeclarationStatement)transformedAction.getActions().get(0);
		assertTrue(returnVariable.getVariableDeclaration().getName().contains(simpleIntegerProcedureName));
		assertTrue(returnVariable.getVariableDeclaration().getType() instanceof IntegerTypeDefinition);
		
		assertTrue(transformedAction.getActions().get(1) instanceof AssignmentStatement);
		AssignmentStatement returnAssignment = (AssignmentStatement)transformedAction.getActions().get(1);
		assertEquals(returnVariable.getVariableDeclaration(), ((DirectReferenceExpression)returnAssignment.getLhs()).getDeclaration());
		assertEquals(simpleIntegerProcedureReturnValue, ((IntegerLiteralExpression)returnAssignment.getRhs()).getValue().intValue());		
		
		assertTrue(transformedAction.getActions().get(2) instanceof VariableDeclarationStatement);
		VariableDeclarationStatement transformedVariable = (VariableDeclarationStatement)transformedAction.getActions().get(2);
		assertNotEquals(target, transformedAction);
		assertNotEquals(target.getVariableDeclaration(), transformedVariable.getVariableDeclaration());
		assertEquals(testName, transformedVariable.getVariableDeclaration().getName());
		assertEquals(testType.getClass(), transformedVariable.getVariableDeclaration().getType().getClass());
		assertNotNull(transformedVariable.getVariableDeclaration().getExpression());
		assertTrue(transformedVariable.getVariableDeclaration().getExpression() instanceof DirectReferenceExpression);
		DirectReferenceExpression transformedExpression = (DirectReferenceExpression)transformedVariable.getVariableDeclaration().getExpression();
		assertEquals(returnVariable.getVariableDeclaration(), transformedExpression.getDeclaration());
	}
	
	@Test
	public void testConstantDeclarationStatementTransformation() {
		//TODO implement basic with initial and prec
		fail("Not implemented!");
	}
	
	@Test
	public void testSideEffectFreeExpressionStatementTransformation() {
		// Arrange
		int testValue = 5;
		IntegerLiteralExpression testExpression = expressionFactory.createIntegerLiteralExpression();
		testExpression.setValue(BigInteger.valueOf(testValue));
		ExpressionStatement target = actionFactory.createExpressionStatement();
		target.setExpression(testExpression);
		
		Package gammaPackage = createBasicStatechartPackageWithAction(target);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
		
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);
		
		// Assert
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertNotNull(transformedStatechart.getTransitions().get(1));
		hu.bme.mit.gamma.statechart.lowlevel.model.Transition transition = transformedStatechart.getTransitions().get(1);
		assertNotNull(transition.getAction());
		Action transformedAction = transition.getAction();
		assertTrue(transformedAction instanceof EmptyStatement);
	}
	
	@Test
	public void testFunctionAccessExpressionStatementTransformation() {
		// Arrange
		ProcedureDeclaration simpleIntegerProcedure = createSimpleIntegerProcedure();
		// function access expression
		DirectReferenceExpression functionReference = expressionFactory.createDirectReferenceExpression();
		functionReference.setDeclaration(simpleIntegerProcedure);
		FunctionAccessExpression functionAccess = expressionFactory.createFunctionAccessExpression();
		functionAccess.setOperand(functionReference);
		ExpressionStatement target = actionFactory.createExpressionStatement();
		target.setExpression(functionAccess);
		// gamma package
		Package gammaPackage = createStatechartPackageWithActionAndFunction(target, simpleIntegerProcedure);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
		
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);
		
		// Assert
		// action (exists)
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertNotNull(transformedStatechart.getTransitions().get(1));
		hu.bme.mit.gamma.statechart.lowlevel.model.Transition transition = transformedStatechart.getTransitions().get(1);
		assertNotNull(transition.getAction());
		assertTrue(transition.getAction() instanceof Block);
		Block transformedAction = (Block)transition.getAction();
		assertTrue(transformedAction.getActions().size() == 3); // decl, assignment, empty
		// return variable declaration
		assertTrue(transformedAction.getActions().get(0) instanceof VariableDeclarationStatement);
		VariableDeclarationStatement returnVariable = (VariableDeclarationStatement)transformedAction.getActions().get(0);
		assertTrue(returnVariable.getVariableDeclaration().getName().contains(simpleIntegerProcedureName));
		assertEquals(simpleIntegerProcedureReturnType.getClass(), returnVariable.getVariableDeclaration().getType().getClass());
		// return variable assignment
		assertTrue(transformedAction.getActions().get(1) instanceof AssignmentStatement);
		AssignmentStatement returnAssignment = (AssignmentStatement)transformedAction.getActions().get(1);
		assertEquals(returnVariable.getVariableDeclaration(), ((DirectReferenceExpression)returnAssignment.getLhs()).getDeclaration());
		assertEquals(simpleIntegerProcedureReturnValue, ((IntegerLiteralExpression)returnAssignment.getRhs()).getValue().intValue());
		// empty statement
		assertTrue(transformedAction.getActions().get(2) instanceof EmptyStatement);
	}
	
	@Test
	public void testIfStatementBasicTransformation() {
		// Arrange
		// a global variable
		String globalVariableName = "a";
		VariableDeclaration globalVariable = expressionFactory.createVariableDeclaration();
		globalVariable.setName(globalVariableName);
		globalVariable.setType(expressionFactory.createIntegerTypeDefinition());
		// assignment before the if
		int beforeIfValue = 1;
		DirectReferenceExpression beforeIfLhs = expressionFactory.createDirectReferenceExpression();
		beforeIfLhs.setDeclaration(globalVariable);
		IntegerLiteralExpression beforeIfRhs = expressionFactory.createIntegerLiteralExpression();
		beforeIfRhs.setValue(BigInteger.valueOf(beforeIfValue));
		AssignmentStatement beforeIf = actionFactory.createAssignmentStatement();
		beforeIf.setLhs(beforeIfLhs);
		beforeIf.setRhs(beforeIfRhs);
		// assignment in the if
		int inIfValue = 2;
		DirectReferenceExpression inIfLhs = expressionFactory.createDirectReferenceExpression();
		inIfLhs.setDeclaration(globalVariable);
		IntegerLiteralExpression inIfRhs = expressionFactory.createIntegerLiteralExpression();
		inIfRhs.setValue(BigInteger.valueOf(inIfValue));
		AssignmentStatement inIf = actionFactory.createAssignmentStatement();
		inIf.setLhs(inIfLhs);
		inIf.setRhs(inIfRhs);
		// assignment after the if
		int afterIfValue = 2;
		DirectReferenceExpression afterIfLhs = expressionFactory.createDirectReferenceExpression();
		afterIfLhs.setDeclaration(globalVariable);
		IntegerLiteralExpression afterIfRhs = expressionFactory.createIntegerLiteralExpression();
		afterIfRhs.setValue(BigInteger.valueOf(afterIfValue));
		AssignmentStatement afterIf = actionFactory.createAssignmentStatement();
		afterIf.setLhs(afterIfLhs);
		afterIf.setRhs(afterIfRhs);
		// the if statement
		IfStatement target = actionFactory.createIfStatement();
		TrueExpression branch1Guard = expressionFactory.createTrueExpression();
		Branch branch1 = actionFactory.createBranch();
		branch1.setGuard(branch1Guard);
		branch1.setAction(inIf);
		target.getConditionals().add(branch1);
		// an enclosing block
		Block enclosingBlock = actionFactory.createBlock();
		enclosingBlock.getActions().add(beforeIf);
		enclosingBlock.getActions().add(target);
		enclosingBlock.getActions().add(afterIf);
		// gamma package
		Package gammaPackage = createStatechartPackageWithActionAndVariable(enclosingBlock, globalVariable);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
		
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);

		// Assert
		// the action (exists)
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertNotNull(transformedStatechart.getTransitions().get(1));
		hu.bme.mit.gamma.statechart.lowlevel.model.Transition transition = transformedStatechart.getTransitions().get(1);
		assertNotNull(transition.getAction());
		assertTrue(transition.getAction() instanceof Block);
		Block transformedAction = (Block)transition.getAction();
		assertEquals(2, transformedAction.getActions().size());
		// assignment 'before if'
		assertTrue(transformedAction.getActions().get(0) instanceof AssignmentStatement);
		AssignmentStatement transformedBeforeIf = (AssignmentStatement)transformedAction.getActions().get(0);
		assertTrue(transformedBeforeIf.getLhs() instanceof DirectReferenceExpression);
		assertEquals(globalVariableName,((DirectReferenceExpression)transformedBeforeIf.getLhs()).getDeclaration().getName());
		assertTrue(transformedBeforeIf.getRhs() instanceof IntegerLiteralExpression);
		assertEquals(beforeIfValue, ((IntegerLiteralExpression)transformedBeforeIf.getRhs()).getValue().intValue());
		// the transformed if statement is correct
		assertTrue(transformedAction.getActions().get(1) instanceof IfStatement);
		IfStatement transformedIf = (IfStatement)transformedAction.getActions().get(1);
		assertEquals(2, transformedIf.getConditionals().size());
		// assignment 'in if'
		assertTrue(transformedIf.getConditionals().get(0).getGuard() instanceof TrueExpression);
		assertTrue(transformedIf.getConditionals().get(0).getAction() instanceof Block);
		Block firstConditionalBlock = (Block)transformedIf.getConditionals().get(0).getAction();
		assertEquals(2, firstConditionalBlock.getActions().size());
		assertTrue(firstConditionalBlock.getActions().get(0) instanceof AssignmentStatement);
		assertTrue(firstConditionalBlock.getActions().get(1) instanceof AssignmentStatement);
		AssignmentStatement transformedInIf = (AssignmentStatement)firstConditionalBlock.getActions().get(0);
		assertTrue(transformedInIf.getLhs() instanceof DirectReferenceExpression);
		assertEquals(globalVariableName,((DirectReferenceExpression)transformedInIf.getLhs()).getDeclaration().getName());
		assertTrue(transformedInIf.getRhs() instanceof IntegerLiteralExpression);
		assertEquals(inIfValue, ((IntegerLiteralExpression)transformedInIf.getRhs()).getValue().intValue());
		AssignmentStatement transformedAfterIf1 = (AssignmentStatement)firstConditionalBlock.getActions().get(1);
		assertTrue(transformedAfterIf1.getLhs() instanceof DirectReferenceExpression);
		assertEquals(globalVariableName,((DirectReferenceExpression)transformedAfterIf1.getLhs()).getDeclaration().getName());
		assertTrue(transformedAfterIf1.getRhs() instanceof IntegerLiteralExpression);
		assertEquals(afterIfValue, ((IntegerLiteralExpression)transformedAfterIf1.getRhs()).getValue().intValue());
		// assignment 'after if'
		assertTrue(transformedIf.getConditionals().get(1).getGuard() instanceof ElseExpression);
		assertTrue(transformedIf.getConditionals().get(1).getAction() instanceof Block);
		Block secondConditionalBlock = (Block)transformedIf.getConditionals().get(1).getAction();
		assertEquals(1, secondConditionalBlock.getActions().size());
		assertTrue(secondConditionalBlock.getActions().get(0) instanceof AssignmentStatement);
		AssignmentStatement transformedAfterIf2 = (AssignmentStatement)secondConditionalBlock.getActions().get(0);
		assertTrue(transformedAfterIf2.getLhs() instanceof DirectReferenceExpression);
		assertEquals(globalVariableName,((DirectReferenceExpression)transformedAfterIf2.getLhs()).getDeclaration().getName());
		assertTrue(transformedAfterIf2.getRhs() instanceof IntegerLiteralExpression);
		assertEquals(afterIfValue, ((IntegerLiteralExpression)transformedAfterIf2.getRhs()).getValue().intValue());
	}
	
	@Test
	public void testIfStatementElsifTransformation() {
		//TODO implement basic, elseif, elseifelse and prec if/elseif
		fail("Not implemented!");
	}
	
	@Test
	public void testIfStatementElsifElseTransformation() {
		//TODO implement basic, elseif, elseifelse and prec if/elseif
		fail("Not implemented!");
	}
	
	@Test
	public void testIfStatementElsifElsePrecTransformation() {
		//TODO implement basic, elseif, elseifelse and prec if/elseif
		fail("Not implemented!");
	}
	
	@Test
	public void testSwitchStatementTransformation() {
		//TODO implement basic and prec
		fail("Not implemented!");
	}
	
	@Test
	public void testSwitchStatementPrecTransformation() {
		//TODO implement basic and prec
		fail("Not implemented!");
	}
	
	@Test
	public void testForStatementIntegerRangeLiteralWithoutBreakTransformation() {
		//TODO implement for-then: 3x literal and prec
		fail("Not implemented!");
	}
	
	@Test
	public void testForStatementArrayLiteralWithoutBreakTransformation() {
		//TODO implement for-then: 3x literal and prec
		fail("Not implemented!");
	}
	
	@Test
	public void testForStatementArrayReferenceWithoutBreakTransformation() {
		//TODO
		//ONLY OVER CONSTANTS!
		fail("Not implemented!");
	}

	
	@Test
	public void testForStatementEnumWithoutBreakTransformation() {
		//TODO implement for-then: 3x literal and prec
		fail("Not implemented!");
	}
	
	@Test
	public void testForStatementWithBreakTransformation() {
		//TODO implement for-then
		fail("Not implemented!");
	}
	
	@Test
	public void testChoiceStatementTransformation() {
		//TODO implement basic and prec
		fail("Not implemented!");
	}
	
	@Test
	public void testChoiceStatementPrecTransformation() {
		//TODO implement basic and prec
		fail("Not implemented!");
	}
	
	@Test
	public void testAssignmentStatementBasicRefTransformation() {
		// Arrange
		// variable to assign to
		String lhsName = "testLhs";
		IntegerTypeDefinition lhsType = expressionFactory.createIntegerTypeDefinition();
		
		VariableDeclaration lhsVariable = expressionFactory.createVariableDeclaration();
		lhsVariable.setName(lhsName);
		lhsVariable.setType(lhsType);
		// variable to assign 
		String rhsName = "testLhs";
		IntegerTypeDefinition rhsType = expressionFactory.createIntegerTypeDefinition();
		int rhsValue = 3;
		IntegerLiteralExpression rhsValueExp = expressionFactory.createIntegerLiteralExpression();
		rhsValueExp.setValue(BigInteger.valueOf(rhsValue));
		
		VariableDeclaration rhsVariable = expressionFactory.createVariableDeclaration();
		rhsVariable.setName(rhsName);
		rhsVariable.setType(rhsType);
		rhsVariable.setExpression(rhsValueExp);
		// assignment statement
		DirectReferenceExpression lhs = expressionFactory.createDirectReferenceExpression();
		lhs.setDeclaration(lhsVariable);
		DirectReferenceExpression rhs = expressionFactory.createDirectReferenceExpression();
		rhs.setDeclaration(rhsVariable);
		
		AssignmentStatement target = actionFactory.createAssignmentStatement();
		target.setLhs(lhs);
		target.setRhs(rhs);
		// gamma package
		Package gammaPackage = createStatechartPackageWithActionAndVariables(target, lhsVariable, rhsVariable);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
		
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);
		
		// Assert
		// action (exists)
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertNotNull(transformedStatechart.getTransitions().get(1));
		hu.bme.mit.gamma.statechart.lowlevel.model.Transition transition = transformedStatechart.getTransitions().get(1);
		assertNotNull(transition.getAction());
		assertTrue(transition.getAction() instanceof AssignmentStatement);
		AssignmentStatement transformedAction = (AssignmentStatement)transition.getAction();
		// lhs
		assertNotNull(transformedAction.getLhs());
		assertTrue(transformedAction.getLhs() instanceof DirectReferenceExpression);
		assertTrue(((DirectReferenceExpression)transformedAction.getLhs()).getDeclaration() instanceof VariableDeclaration);
		assertTrue(((DirectReferenceExpression)transformedAction.getLhs()).getDeclaration().getName().contains(lhsName));
		assertTrue(((DirectReferenceExpression)transformedAction.getLhs()).getDeclaration().getType() instanceof IntegerTypeDefinition);
		// rhs
		assertNotNull(transformedAction.getRhs());
		assertTrue(transformedAction.getRhs() instanceof DirectReferenceExpression);
		assertTrue(((DirectReferenceExpression)transformedAction.getRhs()).getDeclaration() instanceof VariableDeclaration);
		assertTrue(((DirectReferenceExpression)transformedAction.getRhs()).getDeclaration().getName().contains(rhsName));
		assertTrue(((DirectReferenceExpression)transformedAction.getRhs()).getDeclaration().getType() instanceof IntegerTypeDefinition);
		assertTrue(((VariableDeclaration)((DirectReferenceExpression)transformedAction.getRhs()).getDeclaration()).getExpression()instanceof IntegerLiteralExpression);
	
	}
	
	@Test
	public void testAssignmentStatementFromArrayLiteralTransformation() {
		// var lhsVariable : ...; lhsVariable = []{ 1, 2 };
		// Arrange
		// lhs
		int arraySize = 2;
		String lhsVariableName = "lhsVariable";
				
		IntegerLiteralExpression lhsSize = expressionFactory.createIntegerLiteralExpression();
		lhsSize.setValue(BigInteger.valueOf(arraySize));
		IntegerTypeDefinition lhsInnerType = expressionFactory.createIntegerTypeDefinition();
		
		ArrayTypeDefinition lhsType = expressionFactory.createArrayTypeDefinition();
		lhsType.setElementType(lhsInnerType);
		lhsType.setSize(lhsSize);
		
		VariableDeclaration lhsVariable = expressionFactory.createVariableDeclaration();
		lhsVariable.setType(lhsType);
		lhsVariable.setName(lhsVariableName);
		
		DirectReferenceExpression lhs = expressionFactory.createDirectReferenceExpression();
		lhs.setDeclaration(lhsVariable);
		// rhs
		int op1Value = 1;
		int op2Value = 2;
		
		IntegerLiteralExpression op1 = expressionFactory.createIntegerLiteralExpression();
		op1.setValue(BigInteger.valueOf(op1Value));
		IntegerLiteralExpression op2 = expressionFactory.createIntegerLiteralExpression();
		op2.setValue(BigInteger.valueOf(op2Value));
		
		ArrayLiteralExpression rhs = expressionFactory.createArrayLiteralExpression();
		rhs.getOperands().add(op1);
		rhs.getOperands().add(op2);
		// assignment
		AssignmentStatement target = actionFactory.createAssignmentStatement();
		target.setLhs(lhs);
		target.setRhs(rhs);
		// gamma package
		Package gammaPackage = createStatechartPackageWithActionAndVariable(target, lhsVariable);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();

		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);
		
		// Assert
		// action (exists)
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertNotNull(transformedStatechart.getTransitions().get(1));
		hu.bme.mit.gamma.statechart.lowlevel.model.Transition transition = transformedStatechart.getTransitions().get(1);
		assertNotNull(transition.getAction());
		assertTrue(transition.getAction() instanceof AssignmentStatement);
		AssignmentStatement transformedAction = (AssignmentStatement)transition.getAction();
		assertNotNull(transformedAction.getLhs());
		assertTrue(transformedAction.getLhs() instanceof DirectReferenceExpression);
		assertNotNull(((DirectReferenceExpression)transformedAction.getLhs()).getDeclaration());
		assertTrue(((DirectReferenceExpression)transformedAction.getLhs()).getDeclaration().getName().contains(lhsVariableName));
		assertTrue(((DirectReferenceExpression)transformedAction.getLhs()).getDeclaration().getType() instanceof ArrayTypeDefinition);

		assertNotNull(transformedAction.getRhs());
		assertTrue(transformedAction.getRhs() instanceof ArrayLiteralExpression);
		assertTrue(((ArrayLiteralExpression)transformedAction.getRhs()).getOperands().size() == 2);
		assertTrue(((ArrayLiteralExpression)transformedAction.getRhs()).getOperands().get(0) instanceof IntegerLiteralExpression);
		assertTrue(((IntegerLiteralExpression)((ArrayLiteralExpression)transformedAction.getRhs()).getOperands().get(0)).getValue().intValue() == op1Value);
		assertTrue(((ArrayLiteralExpression)transformedAction.getRhs()).getOperands().get(1) instanceof IntegerLiteralExpression);
		assertTrue(((IntegerLiteralExpression)((ArrayLiteralExpression)transformedAction.getRhs()).getOperands().get(1)).getValue().intValue() == op2Value);
	}
	
	@Test
	public void testAssignmentStatementFromSimpleArrayElement() {
		//var lhsVariable : boolean; var rhsVariable := []{false, true} := ...; lhsVariable := rhsVariable[1];  
		// Arrange
		// lhs
		String lhsName = "lhsVariable";
		BooleanTypeDefinition lhsType = expressionFactory.createBooleanTypeDefinition();
				
		VariableDeclaration lhsVariable = expressionFactory.createVariableDeclaration();
		lhsVariable.setName(lhsName);
		lhsVariable.setType(lhsType);
		
		DirectReferenceExpression lhs = expressionFactory.createDirectReferenceExpression();
		lhs.setDeclaration(lhsVariable);
		// rhs
		String rhsName = "rhsVariable";
		int rhsSizeValue = 2;
		
		IntegerLiteralExpression rhsSize = expressionFactory.createIntegerLiteralExpression();
		rhsSize.setValue(BigInteger.valueOf(rhsSizeValue));
		BooleanTypeDefinition rhsInnerType = expressionFactory.createBooleanTypeDefinition();
		ArrayTypeDefinition rhsType = expressionFactory.createArrayTypeDefinition();
		rhsType.setSize(rhsSize);
		rhsType.setElementType(rhsInnerType);
		
		BooleanLiteralExpression op1 = expressionFactory.createFalseExpression();
		BooleanLiteralExpression op2 = expressionFactory.createTrueExpression();
		ArrayLiteralExpression rhsInitial = expressionFactory.createArrayLiteralExpression();
		rhsInitial.getOperands().add(op1);
		rhsInitial.getOperands().add(op2);
		
		VariableDeclaration rhsVariable = expressionFactory.createVariableDeclaration();
		rhsVariable.setName(rhsName);
		rhsVariable.setType(rhsType);
		rhsVariable.setExpression(rhsInitial);
		
		DirectReferenceExpression rhsOperand = expressionFactory.createDirectReferenceExpression();
		rhsOperand.setDeclaration(rhsVariable);
		
		int rhsOpValue = 1;
		IntegerLiteralExpression rhsArgument = expressionFactory.createIntegerLiteralExpression();
		rhsArgument.setValue(BigInteger.valueOf(rhsOpValue));
		ArrayAccessExpression rhs = expressionFactory.createArrayAccessExpression();
		rhs.getArguments().add(rhsArgument);
		rhs.setOperand(rhsOperand);
		// assignment
		AssignmentStatement target = actionFactory.createAssignmentStatement();
		target.setLhs(lhs);
		target.setRhs(rhs);
		// gamma package
		Package gammaPackage = createStatechartPackageWithActionAndVariables(target, lhsVariable, rhsVariable);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();

		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);

		// Assert
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertNotNull(transformedStatechart.getTransitions().get(1));
		hu.bme.mit.gamma.statechart.lowlevel.model.Transition transition = transformedStatechart.getTransitions().get(1);
		assertNotNull(transition.getAction());
		assertTrue(transition.getAction() instanceof AssignmentStatement);
		AssignmentStatement lowLevelAssignment = (AssignmentStatement)transition.getAction();
	
		assertNotNull(lowLevelAssignment.getLhs());
		assertTrue(lowLevelAssignment.getLhs() instanceof DirectReferenceExpression);
		assertNotNull(((DirectReferenceExpression)lowLevelAssignment.getLhs()).getDeclaration());
		assertTrue(((DirectReferenceExpression)lowLevelAssignment.getLhs()).getDeclaration().getName().contains(lhsName));
		assertTrue(((DirectReferenceExpression)lowLevelAssignment.getLhs()).getDeclaration().getType() instanceof BooleanTypeDefinition);
		
		assertNotNull(lowLevelAssignment.getRhs());
		assertTrue(lowLevelAssignment.getRhs() instanceof ArrayAccessExpression);
		assertNotNull(((ArrayAccessExpression)lowLevelAssignment.getRhs()).getOperand());
		assertTrue(((ArrayAccessExpression)lowLevelAssignment.getRhs()).getOperand() instanceof DirectReferenceExpression);
		assertNotNull(((DirectReferenceExpression)((ArrayAccessExpression)lowLevelAssignment.getRhs()).getOperand()).getDeclaration());
		assertTrue(((DirectReferenceExpression)((ArrayAccessExpression)lowLevelAssignment.getRhs()).getOperand()).getDeclaration().getName().contains(rhsName));
		
		assertNotNull(((ArrayAccessExpression)lowLevelAssignment.getRhs()).getArguments().get(0));
	}

	@Test
	public void testAssignmentStatementToSimpleArrayElement() {
		// TODO
		fail("Not implemented!");
	}
	
	@Test
	public void testAssignmentStatementFromSimpleFunctionTransformation() {
		// Arrange
		// function access
		ProcedureDeclaration function = createSimpleIntegerProcedure();
		
		DirectReferenceExpression functionReference = expressionFactory.createDirectReferenceExpression();
		functionReference.setDeclaration(function);
		
		FunctionAccessExpression accessExpression = expressionFactory.createFunctionAccessExpression();
		accessExpression.setOperand(functionReference);
		// variable to assign to
		String lhsName = "testLhs";
		IntegerTypeDefinition lhsType = expressionFactory.createIntegerTypeDefinition();
		
		VariableDeclaration lhsVariable = expressionFactory.createVariableDeclaration();
		lhsVariable.setName(lhsName);
		lhsVariable.setType(lhsType);
		
		DirectReferenceExpression lhs = expressionFactory.createDirectReferenceExpression();
		lhs.setDeclaration(lhsVariable);
		// assignment statement
		AssignmentStatement target = actionFactory.createAssignmentStatement();
		target.setLhs(lhs);
		target.setRhs(accessExpression);
		// gamma package
		Package gammaPackage = createStatechartPackageWithActionVariableAndFunction(target, lhsVariable, function);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
		
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);
		
		// Assert
		// action (exists)
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertNotNull(transformedStatechart.getTransitions().get(1));
		hu.bme.mit.gamma.statechart.lowlevel.model.Transition transition = transformedStatechart.getTransitions().get(1);
		assertNotNull(transition.getAction());
		assertTrue(transition.getAction() instanceof Block);
		Block containingBlock = (Block)transition.getAction();
		assertTrue(containingBlock.getActions().size() == 3);
		// inlined function return variable declaration
		assertTrue(containingBlock.getActions().get(0) instanceof VariableDeclarationStatement);
		VariableDeclarationStatement returnVariable = (VariableDeclarationStatement)containingBlock.getActions().get(0);
		assertNotNull(returnVariable.getVariableDeclaration());
		assertTrue(returnVariable.getVariableDeclaration().getName().contains(function.getName()));
		assertTrue(returnVariable.getVariableDeclaration().getType() instanceof IntegerTypeDefinition);
		// inlined function return variable assignment
		assertTrue(containingBlock.getActions().get(1) instanceof AssignmentStatement);
		AssignmentStatement returnAssignment = (AssignmentStatement)containingBlock.getActions().get(1);
		assertNotNull(returnAssignment.getLhs());
		assertTrue(returnAssignment.getLhs() instanceof DirectReferenceExpression);
		assertTrue(((DirectReferenceExpression)returnAssignment.getLhs()).getDeclaration().equals(returnVariable.getVariableDeclaration()));
		assertNotNull(returnAssignment.getRhs());
		assertTrue(returnAssignment.getRhs() instanceof IntegerLiteralExpression);
		assertTrue(((IntegerLiteralExpression)returnAssignment.getRhs()).getValue().intValue() == simpleIntegerProcedureReturnValue);
		// transformed assignment statement	
		assertTrue(containingBlock.getActions().get(2) instanceof AssignmentStatement);
		AssignmentStatement transformedAssignment = (AssignmentStatement)containingBlock.getActions().get(2);
		assertNotNull(transformedAssignment.getLhs());
		assertTrue(transformedAssignment.getLhs() instanceof DirectReferenceExpression);
		assertTrue(((DirectReferenceExpression)transformedAssignment.getLhs()).getDeclaration() instanceof VariableDeclaration);
		assertTrue(((DirectReferenceExpression)transformedAssignment.getLhs()).getDeclaration().getName().contains(lhsName));
		assertTrue(((DirectReferenceExpression)transformedAssignment.getLhs()).getDeclaration().getType() instanceof IntegerTypeDefinition);
		assertNotNull(transformedAssignment.getRhs());
		assertTrue(transformedAssignment.getRhs() instanceof DirectReferenceExpression);
		assertTrue(((DirectReferenceExpression)transformedAssignment.getRhs()).getDeclaration().equals(returnVariable.getVariableDeclaration()));
	}
	
	@Test
	public void testAssignmentStatementFromRecordLiteralTransformation() {
		// var lhsVariable : ...; lhsVariable = (#p1 := 3, p2 := false#)
		// Arrange
		String p1Name = "p1";
		String p2Name = "p2";
		// Rhs
		int p1AssignmentValue = 3;
		IntegerLiteralExpression p1AssignmentExpression = expressionFactory.createIntegerLiteralExpression();
		p1AssignmentExpression.setValue(BigInteger.valueOf(p1AssignmentValue));
		FieldAssignment p1Assignment = expressionFactory.createFieldAssignment();
		p1Assignment.setReference(p1Name);
		p1Assignment.setValue(p1AssignmentExpression);
		//p2 assignment value = false
		FieldAssignment p2Assignment = expressionFactory.createFieldAssignment();
		p2Assignment.setReference(p2Name);
		p2Assignment.setValue(expressionFactory.createFalseExpression());
		
		RecordLiteralExpression rhs = expressionFactory.createRecordLiteralExpression();
		rhs.getFieldAssignments().add(p1Assignment);
		rhs.getFieldAssignments().add(p2Assignment);
		// Lhs
		IntegerTypeDefinition p1Type = expressionFactory.createIntegerTypeDefinition();
		FieldDeclaration p1 = expressionFactory.createFieldDeclaration();
		p1.setName(p1Name);
		p1.setType(p1Type);
		
		BooleanTypeDefinition p2Type = expressionFactory.createBooleanTypeDefinition();
		FieldDeclaration p2 = expressionFactory.createFieldDeclaration();
		p2.setName(p2Name);
		p2.setType(p2Type);
		
		String lhsName = "lhsVariable";
		RecordTypeDefinition lhsType = expressionFactory.createRecordTypeDefinition();
		lhsType.getFieldDeclarations().add(p1);
		lhsType.getFieldDeclarations().add(p2);
		
		VariableDeclaration lhsVariable = expressionFactory.createVariableDeclaration();
		lhsVariable.setName(lhsName);
		lhsVariable.setType(lhsType);
		
		DirectReferenceExpression lhs = expressionFactory.createDirectReferenceExpression();
		lhs.setDeclaration(lhsVariable);
		// assignment statement
		AssignmentStatement target = actionFactory.createAssignmentStatement();
		target.setLhs(lhs);
		target.setRhs(rhs);
		// gamma package
		Package gammaPackage = createStatechartPackageWithActionAndVariable(target, lhsVariable);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
		
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);
		
		// Assert
		// action (exists)
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertNotNull(transformedStatechart.getTransitions().get(1));
		hu.bme.mit.gamma.statechart.lowlevel.model.Transition transition = transformedStatechart.getTransitions().get(1);
		assertNotNull(transition.getAction());
		assertTrue(transition.getAction() instanceof Block);
		Block containingBlock = (Block)transition.getAction();
		System.out.println(containingBlock.getActions().size());
		assertTrue(containingBlock.getActions().size() == 2);
		// assignment 1
		assertTrue(containingBlock.getActions().get(0) instanceof AssignmentStatement);
		AssignmentStatement assignment1 = (AssignmentStatement)containingBlock.getActions().get(0);
		assertNotNull(assignment1.getLhs());
		assertTrue(assignment1.getLhs() instanceof DirectReferenceExpression);
		assertNotNull(((DirectReferenceExpression)assignment1.getLhs()).getDeclaration());
		assertTrue(((DirectReferenceExpression)assignment1.getLhs()).getDeclaration().getName().contains(lhsName));
		assertTrue(((DirectReferenceExpression)assignment1.getLhs()).getDeclaration().getName().contains(p1Name));
		assertTrue(((DirectReferenceExpression)assignment1.getLhs()).getDeclaration().getType() instanceof IntegerTypeDefinition);
		assertNotNull(assignment1.getRhs());
		assertTrue(assignment1.getRhs() instanceof IntegerLiteralExpression);
		assertTrue(((IntegerLiteralExpression)assignment1.getRhs()).getValue().intValue() == p1AssignmentValue);
		// assignment 2
		assertTrue(containingBlock.getActions().get(1) instanceof AssignmentStatement);
		AssignmentStatement assignment2 = (AssignmentStatement)containingBlock.getActions().get(1);
		assertNotNull(assignment2.getLhs());
		assertTrue(assignment2.getLhs() instanceof DirectReferenceExpression);
		assertNotNull(((DirectReferenceExpression)assignment2.getLhs()).getDeclaration());
		assertTrue(((DirectReferenceExpression)assignment2.getLhs()).getDeclaration().getName().contains(lhsName));
		assertTrue(((DirectReferenceExpression)assignment2.getLhs()).getDeclaration().getName().contains(p2Name));
		assertTrue(((DirectReferenceExpression)assignment2.getLhs()).getDeclaration().getType() instanceof BooleanTypeDefinition);
		assertNotNull(assignment2.getRhs());
		assertTrue(assignment2.getRhs() instanceof FalseExpression);
		
	}

	@Test
	public void testAssignmentStatementFromSimpleRecordFieldTransformation() {
		//var lhsVariable : boolean; var rhsVariable := record{p1: integer, p2 : boolean} := ...; lhsVariable := rhsVariable.p2;  
		// Arrange
		// lhs variable
		String lhsName = "lhsVariable";
		BooleanTypeDefinition lhsType = expressionFactory.createBooleanTypeDefinition();
				
		VariableDeclaration lhsVariable = expressionFactory.createVariableDeclaration();
		lhsVariable.setName(lhsName);
		lhsVariable.setType(lhsType);
		
		DirectReferenceExpression lhs = expressionFactory.createDirectReferenceExpression();
		lhs.setDeclaration(lhsVariable);
		// rhs variable
		String p1Name = "p1";
		String p2Name = "p2";
		
		IntegerTypeDefinition p1Type = expressionFactory.createIntegerTypeDefinition();
		FieldDeclaration p1 = expressionFactory.createFieldDeclaration();
		p1.setName(p1Name);
		p1.setType(p1Type);
		
		BooleanTypeDefinition p2Type = expressionFactory.createBooleanTypeDefinition();
		FieldDeclaration p2 = expressionFactory.createFieldDeclaration();
		p2.setName(p2Name);
		p2.setType(p2Type);
		
		String rhsName = "rhsVariable";
		RecordTypeDefinition rhsType = expressionFactory.createRecordTypeDefinition();
		rhsType.getFieldDeclarations().add(p1);
		rhsType.getFieldDeclarations().add(p2);
		//p1 assigned to 3
		int p1AssignmentValue = 3;
		IntegerLiteralExpression p1AssignmentExpression = expressionFactory.createIntegerLiteralExpression();
		p1AssignmentExpression.setValue(BigInteger.valueOf(p1AssignmentValue));
		FieldAssignment p1Assignment = expressionFactory.createFieldAssignment();
		p1Assignment.setReference(p1Name);
		p1Assignment.setValue(p1AssignmentExpression);
		//p2 assignment value = false
		FieldAssignment p2Assignment = expressionFactory.createFieldAssignment();
		p2Assignment.setReference(p2Name);
		p2Assignment.setValue(expressionFactory.createFalseExpression());
		
		RecordLiteralExpression rhsInitial = expressionFactory.createRecordLiteralExpression();
		rhsInitial.getFieldAssignments().add(p1Assignment);
		rhsInitial.getFieldAssignments().add(p2Assignment);
		
		VariableDeclaration rhsVariable = expressionFactory.createVariableDeclaration();
		rhsVariable.setName(rhsName);
		rhsVariable.setType(rhsType);
		rhsVariable.setExpression(rhsInitial);
		
		DirectReferenceExpression rhsRef = expressionFactory.createDirectReferenceExpression();
		rhsRef.setDeclaration(rhsVariable);
		RecordAccessExpression rhs = expressionFactory.createRecordAccessExpression();
		rhs.setOperand(rhsRef);
		rhs.setField(p2Name);
		// assignment
		AssignmentStatement target = actionFactory.createAssignmentStatement();
		target.setLhs(lhs);
		target.setRhs(rhs);
		// gamma package
		Package gammaPackage = createStatechartPackageWithActionAndVariables(target, lhsVariable, rhsVariable);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();

		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);
		
		// Assert
		// action (exists)
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertNotNull(transformedStatechart.getTransitions().get(1));
		hu.bme.mit.gamma.statechart.lowlevel.model.Transition transition = transformedStatechart.getTransitions().get(1);
		assertNotNull(transition.getAction());
		assertTrue(transition.getAction() instanceof AssignmentStatement);
		AssignmentStatement lowLevelAssignment = (AssignmentStatement)transition.getAction();

		assertNotNull(lowLevelAssignment.getLhs());
		assertTrue(lowLevelAssignment.getLhs() instanceof DirectReferenceExpression);
		assertNotNull(((DirectReferenceExpression)lowLevelAssignment.getLhs()).getDeclaration());
		assertTrue(((DirectReferenceExpression)lowLevelAssignment.getLhs()).getDeclaration().getName().contains(lhsName));
		assertTrue(((DirectReferenceExpression)lowLevelAssignment.getLhs()).getDeclaration().getType() instanceof BooleanTypeDefinition);
		assertNotNull(lowLevelAssignment.getRhs());
		assertTrue(lowLevelAssignment.getRhs() instanceof DirectReferenceExpression);
		assertNotNull(((DirectReferenceExpression)lowLevelAssignment.getRhs()).getDeclaration());
		assertTrue(((DirectReferenceExpression)lowLevelAssignment.getRhs()).getDeclaration().getName().contains(rhsName));
		assertTrue(((DirectReferenceExpression)lowLevelAssignment.getRhs()).getDeclaration().getName().contains(p2Name));
		assertTrue(((DirectReferenceExpression)lowLevelAssignment.getRhs()).getDeclaration().getType() instanceof BooleanTypeDefinition);
		assertTrue(((VariableDeclaration)((DirectReferenceExpression)lowLevelAssignment.getRhs()).getDeclaration()).getExpression() instanceof FalseExpression);
	}
	
	@Test
	public void testAssignmentStatementToSimpleRecordFieldTransformation() {
		//var lhsVariable : record{p1: integer, p2 : boolean}; lhsVariable.p2 := false; 
		// Arrange
		// lhs variable (name, type definition)
		String p1Name = "p1";
		String p2Name = "p2";
		
		IntegerTypeDefinition p1Type = expressionFactory.createIntegerTypeDefinition();
		FieldDeclaration p1 = expressionFactory.createFieldDeclaration();
		p1.setName(p1Name);
		p1.setType(p1Type);
		
		BooleanTypeDefinition p2Type = expressionFactory.createBooleanTypeDefinition();
		FieldDeclaration p2 = expressionFactory.createFieldDeclaration();
		p2.setName(p2Name);
		p2.setType(p2Type);
		
		String lhsName = "lhsVariable";
		RecordTypeDefinition lhsType = expressionFactory.createRecordTypeDefinition();
		lhsType.getFieldDeclarations().add(p1);
		lhsType.getFieldDeclarations().add(p2);
		
		VariableDeclaration lhsVariable = expressionFactory.createVariableDeclaration();
		lhsVariable.setName(lhsName);
		lhsVariable.setType(lhsType);
		
		DirectReferenceExpression lhsReference = expressionFactory.createDirectReferenceExpression();
		lhsReference.setDeclaration(lhsVariable);
		
		RecordAccessExpression lhs = expressionFactory.createRecordAccessExpression();
		lhs.setOperand(lhsReference);
		lhs.setField(p2Name);
		// rhs
		BooleanLiteralExpression rhs = expressionFactory.createFalseExpression();
		// assignment
		AssignmentStatement target = actionFactory.createAssignmentStatement();
		target.setLhs(lhs);
		target.setRhs(rhs);
		// gamma package
		Package gammaPackage = createStatechartPackageWithActionAndVariable(target, lhsVariable);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
		
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);

		// Assert
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertNotNull(transformedStatechart.getTransitions().get(1));
		hu.bme.mit.gamma.statechart.lowlevel.model.Transition transition = transformedStatechart.getTransitions().get(1);
		assertNotNull(transition.getAction());
		assertTrue(transition.getAction() instanceof AssignmentStatement);
		AssignmentStatement lowLevelAssignment = (AssignmentStatement)transition.getAction();
		
		assertNotNull(lowLevelAssignment.getLhs());
		assertTrue(lowLevelAssignment.getLhs() instanceof DirectReferenceExpression);
		assertNotNull(((DirectReferenceExpression)lowLevelAssignment.getLhs()).getDeclaration());
		assertTrue(((DirectReferenceExpression)lowLevelAssignment.getLhs()).getDeclaration().getName().contains(lhsName));
		assertTrue(((DirectReferenceExpression)lowLevelAssignment.getLhs()).getDeclaration().getName().contains(p2Name));
		assertTrue(((DirectReferenceExpression)lowLevelAssignment.getLhs()).getDeclaration().getType() instanceof BooleanTypeDefinition);
		
		assertNotNull(lowLevelAssignment.getRhs());
		assertTrue(lowLevelAssignment.getRhs() instanceof FalseExpression);
	}
	
	@Test
	public void testAssertionStatementTransformation() {
		// Arrange
		
		// Act
		
		// Assert
		
	}
	
	@Test
	public void testProcedureVoidBasicTransformation() {
		//TODO implement basic void, basic non-void, branching non-void (with inlining)
		//without inlining?
		fail("Not implemented!");
	}
	
	@Test
	public void testProcedureNonVoidBasicTransformation() {
		//TODO implement basic void, basic non-void, branching non-void (with inlining)
		//without inlining?
		fail("Not implemented!");
	}
	
	@Test
	public void testProcedureNonVoidBranchingTransformation() {
		//TODO implement basic void, basic non-void, branching non-void (with inlining)
		//without inlining?
		fail("Not implemented!");
	}
	
	// Expression / Type / etc. transformation tests:
	
	@Test
	public void testRecordTransformation() {
		// var testRecord : record{r1 : integer, r2 : boolean} := (#r1 := 1, r2 := false#)
		// Arrange
		// target variable parameters
		String targetName = "testRecord";
		String targetElem1Name = "r1";
		IntegerTypeDefinition targetElem1Type = expressionFactory.createIntegerTypeDefinition();
		FieldDeclaration targetElem1 = expressionFactory.createFieldDeclaration();
		targetElem1.setName(targetElem1Name);
		targetElem1.setType(targetElem1Type);
		String targetElem2Name = "r2";
		BooleanTypeDefinition targetElem2Type = expressionFactory.createBooleanTypeDefinition();
		FieldDeclaration targetElem2 = expressionFactory.createFieldDeclaration();
		targetElem2.setName(targetElem2Name);
		targetElem2.setType(targetElem2Type);
		RecordTypeDefinition targetType = expressionFactory.createRecordTypeDefinition();
		targetType.getFieldDeclarations().add(targetElem1);
		targetType.getFieldDeclarations().add(targetElem2);
		// target initial expression
		RecordLiteralExpression targetInitialExpression = expressionFactory.createRecordLiteralExpression();
		int targetElem1InitialValue = 1;
		IntegerLiteralExpression targetElem1InitialValueExpression = expressionFactory.createIntegerLiteralExpression();
		targetElem1InitialValueExpression.setValue(BigInteger.valueOf(targetElem1InitialValue));
		FieldAssignment targetElem1InitialAssignment = expressionFactory.createFieldAssignment();
		targetElem1InitialAssignment.setReference(targetElem1Name);
		targetElem1InitialAssignment.setValue(targetElem1InitialValueExpression);
		FalseExpression targetElem2InitialValueExpression = expressionFactory.createFalseExpression();
		FieldAssignment targetElem2InitialAssignment = expressionFactory.createFieldAssignment();
		targetElem2InitialAssignment.setReference(targetElem2Name);
		targetElem2InitialAssignment.setValue(targetElem2InitialValueExpression);
		targetInitialExpression.getFieldAssignments().add(targetElem1InitialAssignment);
		targetInitialExpression.getFieldAssignments().add(targetElem2InitialAssignment);
		// target variable
		VariableDeclaration target = expressionFactory.createVariableDeclaration();
		target.setName(targetName);
		target.setType(targetType);
		target.setExpression(targetInitialExpression);
		// gamma package
		Package gammaPackage = createStatechartPackageWithActionAndVariable(actionFactory.createEmptyStatement(), target);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
		
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);
		
		// Assert
		// variables (exist)
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertTrue(transformedStatechart.getVariableDeclarations().size() == (2 + assertionOffset));
		// var 1
		VariableDeclaration transformedVariable1 = transformedStatechart.getVariableDeclarations().get(0 + assertionOffset);
		assertTrue(transformedVariable1.getName().contains(targetName));
		assertTrue(transformedVariable1.getName().contains(targetElem1Name));
		assertTrue(transformedVariable1.getType() instanceof IntegerTypeDefinition);
		assertNotNull(transformedVariable1.getExpression());
		assertTrue(transformedVariable1.getExpression() instanceof IntegerLiteralExpression);
		assertTrue(((IntegerLiteralExpression)transformedVariable1.getExpression()).getValue().intValue() == targetElem1InitialValue);
		// var 2
		VariableDeclaration transformedVariable2 = transformedStatechart.getVariableDeclarations().get(1 + assertionOffset);
		assertTrue(transformedVariable2.getName().contains(targetName));
		assertTrue(transformedVariable2.getName().contains(targetElem2Name));
		assertTrue(transformedVariable2.getType() instanceof BooleanTypeDefinition);
		assertNotNull(transformedVariable2.getExpression());
		assertTrue(transformedVariable2.getExpression() instanceof FalseExpression);
	}
	
	@Test
	public void testJaggedRecordTransformation() {
		// var testRecord : record{r1 : record{r11 : integer, r12 : boolean}, r2 : boolean} := (#r1 := (# r11 := 1, r12 := true#), r2 := false#)
		// Arrange
		// target name
		String targetName = "testRecord";
		// target type
		String r11Name = "r11";
		IntegerTypeDefinition r11Type = expressionFactory.createIntegerTypeDefinition();
		FieldDeclaration r11 = expressionFactory.createFieldDeclaration();
		r11.setName(r11Name);
		r11.setType(r11Type);
		
		String r12Name = "r12";
		BooleanTypeDefinition r12Type = expressionFactory.createBooleanTypeDefinition();
		FieldDeclaration r12 = expressionFactory.createFieldDeclaration();
		r12.setName(r12Name);
		r12.setType(r12Type);
		
		String r1Name = "r1";
		FieldDeclaration r1 = expressionFactory.createFieldDeclaration();
		RecordTypeDefinition r1Type = expressionFactory.createRecordTypeDefinition();
		r1Type.getFieldDeclarations().add(r11);
		r1Type.getFieldDeclarations().add(r12);
		r1.setName(r1Name);
		r1.setType(r1Type);
		
		String r2Name = "r2";
		BooleanTypeDefinition r2Type = expressionFactory.createBooleanTypeDefinition();
		FieldDeclaration r2 = expressionFactory.createFieldDeclaration();
		r2.setName(r2Name);
		r2.setType(r2Type);
		
		RecordTypeDefinition targetType = expressionFactory.createRecordTypeDefinition();
		targetType.getFieldDeclarations().add(r1);
		targetType.getFieldDeclarations().add(r2);
		//target initial expression
		int targetInitialR11Value = 1;
		IntegerLiteralExpression targetInitialR11Expression = expressionFactory.createIntegerLiteralExpression();
		targetInitialR11Expression.setValue(BigInteger.valueOf(targetInitialR11Value));
		FieldAssignment targetInitialR11Assgnment = expressionFactory.createFieldAssignment();
		targetInitialR11Assgnment.setReference(r11Name);
		targetInitialR11Assgnment.setValue(targetInitialR11Expression);
		
		FieldAssignment targetInitialR12Assignment = expressionFactory.createFieldAssignment();
		targetInitialR12Assignment.setReference(r12Name);
		targetInitialR12Assignment.setValue(expressionFactory.createFalseExpression());
		
		RecordLiteralExpression targetInitialR1 = expressionFactory.createRecordLiteralExpression();
		targetInitialR1.getFieldAssignments().add(targetInitialR11Assgnment);
		targetInitialR1.getFieldAssignments().add(targetInitialR12Assignment);
		FieldAssignment targetInitialR1Assignment = expressionFactory.createFieldAssignment();
		targetInitialR1Assignment.setReference(r1Name);
		targetInitialR1Assignment.setValue(targetInitialR1);
		
		TrueExpression targetInitialR2 = expressionFactory.createTrueExpression();
		FieldAssignment targetInitialR2Assignment = expressionFactory.createFieldAssignment();
		targetInitialR2Assignment.setReference(r2Name);
		targetInitialR2Assignment.setValue(targetInitialR2);
		
		RecordLiteralExpression targetInitialExpression = expressionFactory.createRecordLiteralExpression();
		targetInitialExpression.getFieldAssignments().add(targetInitialR1Assignment);
		targetInitialExpression.getFieldAssignments().add(targetInitialR2Assignment);
		// target variable construction
		VariableDeclaration target = expressionFactory.createVariableDeclaration();
		target.setName(targetName);
		target.setType(targetType);
		target.setExpression(targetInitialExpression);
		// gamma package
		Package gammaPackage = createStatechartPackageWithActionAndVariable(actionFactory.createEmptyStatement(), target);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
		
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);

		// Assert
		// variables (exist)
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertTrue(transformedStatechart.getVariableDeclarations().size() == (3 + assertionOffset));
		// var 1
		VariableDeclaration transformedVariable1 = transformedStatechart.getVariableDeclarations().get(0 + assertionOffset);
		assertTrue(transformedVariable1.getName().contains(targetName));
		assertTrue(transformedVariable1.getName().contains(r1Name));
		assertTrue(transformedVariable1.getName().contains(r11Name));
		assertTrue(transformedVariable1.getType() instanceof IntegerTypeDefinition);
		assertNotNull(transformedVariable1.getExpression());
		assertTrue(transformedVariable1.getExpression() instanceof IntegerLiteralExpression);
		assertTrue(((IntegerLiteralExpression)transformedVariable1.getExpression()).getValue().intValue() == targetInitialR11Value);
		// var 2
		VariableDeclaration transformedVariable2 = transformedStatechart.getVariableDeclarations().get(1 + assertionOffset);
		assertTrue(transformedVariable2.getName().contains(targetName));
		assertTrue(transformedVariable2.getName().contains(r1Name));
		assertTrue(transformedVariable2.getName().contains(r12Name));
		assertTrue(transformedVariable2.getType() instanceof BooleanTypeDefinition);
		assertNotNull(transformedVariable2.getExpression());
		assertTrue(transformedVariable2.getExpression() instanceof FalseExpression);
		// var 3
		VariableDeclaration transformedVariable3 = transformedStatechart.getVariableDeclarations().get(2 + assertionOffset);
		assertTrue(transformedVariable3.getName().contains(targetName));
		assertTrue(transformedVariable3.getName().contains(r2Name));
		assertTrue(transformedVariable3.getType() instanceof BooleanTypeDefinition);
		assertNotNull(transformedVariable3.getExpression());
		assertTrue(transformedVariable3.getExpression() instanceof TrueExpression);
	}
	
	@Test
	public void testArrayTransformation() {
		// var testArray : array integer[2] := []{1, 2}
		// Arrange 
		// target variable parameters
		String targetName = "testArray";
		int targetSize = 2;
		IntegerLiteralExpression targetSizeExpression = expressionFactory.createIntegerLiteralExpression();
		targetSizeExpression.setValue(BigInteger.valueOf(targetSize));
		IntegerTypeDefinition targetElementType = expressionFactory.createIntegerTypeDefinition();
		ArrayTypeDefinition targetType = expressionFactory.createArrayTypeDefinition();
		targetType.setSize(targetSizeExpression);
		targetType.setElementType(targetElementType);
		// target variable initial expression
		int targetInitialOp1Val = 1;
		IntegerLiteralExpression targetInitialOp1 = expressionFactory.createIntegerLiteralExpression();
		targetInitialOp1.setValue(BigInteger.valueOf(targetInitialOp1Val));
		int targetInitialOp2Val = 2;
		IntegerLiteralExpression targetInitialOp2 = expressionFactory.createIntegerLiteralExpression();
		targetInitialOp2.setValue(BigInteger.valueOf(targetInitialOp2Val));
		ArrayLiteralExpression targetInitialExpression = expressionFactory.createArrayLiteralExpression();
		targetInitialExpression.getOperands().add(targetInitialOp1);
		targetInitialExpression.getOperands().add(targetInitialOp2);
		// target variable
		VariableDeclaration target = expressionFactory.createVariableDeclaration();
		target.setType(targetType);
		target.setName(targetName);
		target.setExpression(targetInitialExpression);
		// gamma package
		Package gammaPackage = createStatechartPackageWithActionAndVariable(actionFactory.createEmptyStatement(), target);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
		
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);

		// Assert
		// variable (exists)
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertTrue(transformedStatechart.getVariableDeclarations().size() == (1 + assertionOffset));
		assertNotNull(transformedStatechart.getVariableDeclarations().get(0 + assertionOffset));
		VariableDeclaration transformedVariable = transformedStatechart.getVariableDeclarations().get(0 + assertionOffset);
		// name
		assertTrue(transformedVariable.getName().contains(targetName));
		// type
		assertTrue(transformedVariable.getType()instanceof ArrayTypeDefinition);
		assertTrue(((ArrayTypeDefinition)transformedVariable.getType()).getSize().getValue().intValue() == targetSize);
		assertTrue(((ArrayTypeDefinition)transformedVariable.getType()).getElementType() instanceof IntegerTypeDefinition);
		// initial expression
		assertNotNull(transformedVariable.getExpression());
		assertTrue(transformedVariable.getExpression() instanceof ArrayLiteralExpression);
		assertTrue(((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().size() == 2);
		assertTrue(((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().get(0) instanceof IntegerLiteralExpression);
		assertTrue(((IntegerLiteralExpression)((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().get(0)).getValue().intValue() == targetInitialOp1Val);
		assertTrue(((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().get(1) instanceof IntegerLiteralExpression);
		assertTrue(((IntegerLiteralExpression)((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().get(1)).getValue().intValue() == targetInitialOp2Val);
	}
	
	@Test
	public void testJaggedArrayTransformation() {
		// var testArray : array array integer[2] [2] := []{[]{1, 2}, []{1, 2}}
		// Arrange
		// target variable parameters
		String targetName = "testArray";
		int targetSize = 2;
		int targetInnerSize = 2;
		IntegerLiteralExpression targetInnerSizeExpression = expressionFactory.createIntegerLiteralExpression();
		targetInnerSizeExpression.setValue(BigInteger.valueOf(targetInnerSize));
		IntegerLiteralExpression targetSizeExpression = expressionFactory.createIntegerLiteralExpression();
		targetSizeExpression.setValue(BigInteger.valueOf(targetSize));
		ArrayTypeDefinition targetElementType = expressionFactory.createArrayTypeDefinition();
		IntegerTypeDefinition targetInnerElementType = expressionFactory.createIntegerTypeDefinition();
		targetElementType.setSize(targetInnerSizeExpression);
		targetElementType.setElementType(targetInnerElementType);
		ArrayTypeDefinition targetType = expressionFactory.createArrayTypeDefinition();
		targetType.setSize(targetSizeExpression);
		targetType.setElementType(targetElementType);
		// target initial expression op1
		int targetInitialOp1Val = 1;
		int targetInitialOp2Val = 2;
		IntegerLiteralExpression targetInitialOp11 = expressionFactory.createIntegerLiteralExpression();
		targetInitialOp11.setValue(BigInteger.valueOf(targetInitialOp1Val));
		IntegerLiteralExpression targetInitialOp12 = expressionFactory.createIntegerLiteralExpression();
		targetInitialOp12.setValue(BigInteger.valueOf(targetInitialOp2Val));
		ArrayLiteralExpression targetInitialOp1 = expressionFactory.createArrayLiteralExpression();
		targetInitialOp1.getOperands().add(targetInitialOp11);
		targetInitialOp1.getOperands().add(targetInitialOp12);
		// target initial expression op2
		IntegerLiteralExpression targetInitialOp21 = expressionFactory.createIntegerLiteralExpression();
		targetInitialOp21.setValue(BigInteger.valueOf(targetInitialOp1Val));
		IntegerLiteralExpression targetInitialOp22 = expressionFactory.createIntegerLiteralExpression();
		targetInitialOp22.setValue(BigInteger.valueOf(targetInitialOp2Val));
		ArrayLiteralExpression targetInitialExpression = expressionFactory.createArrayLiteralExpression();
		ArrayLiteralExpression targetInitialOp2 = expressionFactory.createArrayLiteralExpression();
		targetInitialOp2.getOperands().add(targetInitialOp21);
		targetInitialOp2.getOperands().add(targetInitialOp22);
		// target initial expression
		targetInitialExpression.getOperands().add(targetInitialOp1);
		targetInitialExpression.getOperands().add(targetInitialOp2);
		// target variable
		VariableDeclaration target = expressionFactory.createVariableDeclaration();
		target.setType(targetType);
		target.setName(targetName);
		target.setExpression(targetInitialExpression);
		// gamma package
		Package gammaPackage = createStatechartPackageWithActionAndVariable(actionFactory.createEmptyStatement(), target);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
		
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);

		// Assert
		// variable (exists)
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertTrue(transformedStatechart.getVariableDeclarations().size() == (1 + assertionOffset));
		assertNotNull(transformedStatechart.getVariableDeclarations().get(0 + assertionOffset));
		VariableDeclaration transformedVariable = transformedStatechart.getVariableDeclarations().get(0 + assertionOffset);
		// name
		assertTrue(transformedVariable.getName().contains(targetName));
		// type
		assertTrue(transformedVariable.getType()instanceof ArrayTypeDefinition);
		assertTrue(((ArrayTypeDefinition)transformedVariable.getType()).getSize().getValue().intValue() == targetSize);
		assertTrue(((ArrayTypeDefinition)transformedVariable.getType()).getElementType() instanceof ArrayTypeDefinition);
		assertTrue(((ArrayTypeDefinition)(((ArrayTypeDefinition)transformedVariable.getType()).getElementType())).getSize().getValue().intValue() == targetInnerSize);
		assertTrue(((ArrayTypeDefinition)(((ArrayTypeDefinition)transformedVariable.getType()).getElementType())).getElementType() instanceof IntegerTypeDefinition);
		// initial expression 'outer'
		assertNotNull(transformedVariable.getExpression());
		assertTrue(transformedVariable.getExpression() instanceof ArrayLiteralExpression);
		assertTrue(((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().size() == 2);
		assertTrue(((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().get(0) instanceof ArrayLiteralExpression);
		// initial expression 'inner' 1
		assertTrue(((ArrayLiteralExpression)((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().get(0)).getOperands().size() == 2);	
		assertTrue(((ArrayLiteralExpression)((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().get(0)).getOperands().get(0) instanceof IntegerLiteralExpression);
		assertTrue(((IntegerLiteralExpression)((ArrayLiteralExpression)((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().get(1)).getOperands().get(0)).getValue().intValue() == targetInitialOp1Val);
		assertTrue(((ArrayLiteralExpression)((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().get(0)).getOperands().get(1) instanceof IntegerLiteralExpression);
		assertTrue(((IntegerLiteralExpression)((ArrayLiteralExpression)((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().get(1)).getOperands().get(1)).getValue().intValue() == targetInitialOp2Val);
		// initial expression 'inner' 2
		assertTrue(((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().get(1) instanceof ArrayLiteralExpression);
		assertTrue(((ArrayLiteralExpression)((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().get(1)).getOperands().size() == 2);	
		assertTrue(((ArrayLiteralExpression)((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().get(1)).getOperands().get(0) instanceof IntegerLiteralExpression);
		assertTrue(((IntegerLiteralExpression)((ArrayLiteralExpression)((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().get(1)).getOperands().get(0)).getValue().intValue() == targetInitialOp1Val);
		assertTrue(((ArrayLiteralExpression)((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().get(1)).getOperands().get(1) instanceof IntegerLiteralExpression);
		assertTrue(((IntegerLiteralExpression)((ArrayLiteralExpression)((ArrayLiteralExpression)transformedVariable.getExpression()).getOperands().get(1)).getOperands().get(1)).getValue().intValue() == targetInitialOp2Val);
	
	}
	
	@Test
	public void testJaggedRecordInArrayTransformation() {
		// var testArray : array record{p1 : integer, p2 : boolean}[2] := []{(#p1 := 1, p2 := false#), (#p1 := 2, p2 := true#)}
		// Arrange
		// target name
		String targetName = "testArray";
		// target type
		int targetTypeSize = 2;
		IntegerLiteralExpression targetTypeSizeExpression = expressionFactory.createIntegerLiteralExpression();
		targetTypeSizeExpression.setValue(BigInteger.valueOf(targetTypeSize));
		
		String p1Name = "p1";
		IntegerTypeDefinition p1Type = expressionFactory.createIntegerTypeDefinition();
		FieldDeclaration p1 = expressionFactory.createFieldDeclaration();
		p1.setName(p1Name);
		p1.setType(p1Type);
		
		String p2Name = "p2";
		BooleanTypeDefinition p2Type = expressionFactory.createBooleanTypeDefinition();
		FieldDeclaration p2 = expressionFactory.createFieldDeclaration();
		p2.setName(p2Name);
		p2.setType(p2Type);
		
		RecordTypeDefinition targetInnerType = expressionFactory.createRecordTypeDefinition();
		targetInnerType.getFieldDeclarations().add(p1);
		targetInnerType.getFieldDeclarations().add(p2);
		
		ArrayTypeDefinition targetType = expressionFactory.createArrayTypeDefinition();
		targetType.setSize(targetTypeSizeExpression);
		targetType.setElementType(targetInnerType);
		// target initial expression
		int op11val = 1;
		IntegerLiteralExpression op11 = expressionFactory.createIntegerLiteralExpression();
		op11.setValue(BigInteger.valueOf(op11val));
		FieldAssignment op11Assignment = expressionFactory.createFieldAssignment();
		op11Assignment.setReference(p1Name);
		op11Assignment.setValue(op11);
		
		FalseExpression op12 = expressionFactory.createFalseExpression();
		FieldAssignment op12Assignment = expressionFactory.createFieldAssignment();
		op12Assignment.setReference(p2Name);
		op12Assignment.setValue(op12);
		
		int op21val = 2;
		IntegerLiteralExpression op21 = expressionFactory.createIntegerLiteralExpression();
		op21.setValue(BigInteger.valueOf(op21val));
		FieldAssignment op21Assignment = expressionFactory.createFieldAssignment();
		op21Assignment.setReference(p1Name);
		op21Assignment.setValue(op21);
		
		TrueExpression op22 = expressionFactory.createTrueExpression();
		FieldAssignment op22Assignment = expressionFactory.createFieldAssignment();
		op22Assignment.setReference(p2Name);
		op22Assignment.setValue(op22);
		
		RecordLiteralExpression targetInitialOp1 = expressionFactory.createRecordLiteralExpression();
		targetInitialOp1.getFieldAssignments().add(op11Assignment);
		targetInitialOp1.getFieldAssignments().add(op12Assignment);
		
		RecordLiteralExpression targetInitialOp2 = expressionFactory.createRecordLiteralExpression();
		targetInitialOp2.getFieldAssignments().add(op21Assignment);
		targetInitialOp2.getFieldAssignments().add(op22Assignment);
		
		ArrayLiteralExpression targetInitialExpression = expressionFactory.createArrayLiteralExpression();
		targetInitialExpression.getOperands().add(targetInitialOp1);
		targetInitialExpression.getOperands().add(targetInitialOp2);
		// target variable
		VariableDeclaration target = expressionFactory.createVariableDeclaration();
		target.setName(targetName);
		target.setType(targetType);
		target.setExpression(targetInitialExpression);
		// gamma package
		Package gammaPackage = createStatechartPackageWithActionAndVariable(actionFactory.createEmptyStatement(), target);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
	
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);

		// Assert
		// variables (exist)
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertTrue(transformedStatechart.getVariableDeclarations().size() == (2 + assertionOffset));
		// var 1
		VariableDeclaration transformedVariable1 = transformedStatechart.getVariableDeclarations().get(0 + assertionOffset);
		assertTrue(transformedVariable1.getName().contains(targetName));
		assertTrue(transformedVariable1.getName().contains(p1Name));
		assertTrue(transformedVariable1.getType() instanceof ArrayTypeDefinition);
		assertTrue(((ArrayTypeDefinition)transformedVariable1.getType()).getSize().getValue().intValue() == targetTypeSize);
		assertTrue(((ArrayTypeDefinition)transformedVariable1.getType()).getElementType() instanceof IntegerTypeDefinition);
		assertNotNull(transformedVariable1.getExpression());
		assertTrue(transformedVariable1.getExpression() instanceof ArrayLiteralExpression);
		assertTrue(((ArrayLiteralExpression)transformedVariable1.getExpression()).getOperands().size() == 2);
		assertTrue(((ArrayLiteralExpression)transformedVariable1.getExpression()).getOperands().get(0) instanceof IntegerLiteralExpression);
		assertTrue(((IntegerLiteralExpression)((ArrayLiteralExpression)transformedVariable1.getExpression()).getOperands().get(0)).getValue().intValue() == op11val);
		assertTrue(((ArrayLiteralExpression)transformedVariable1.getExpression()).getOperands().get(1) instanceof IntegerLiteralExpression);
		assertTrue(((IntegerLiteralExpression)((ArrayLiteralExpression)transformedVariable1.getExpression()).getOperands().get(1)).getValue().intValue() == op21val);
		// var 1
		VariableDeclaration transformedVariable2 = transformedStatechart.getVariableDeclarations().get(1 + assertionOffset);
		assertTrue(transformedVariable2.getName().contains(targetName));
		assertTrue(transformedVariable2.getName().contains(p2Name));		
		assertTrue(transformedVariable2.getType() instanceof ArrayTypeDefinition);		
		assertTrue(((ArrayTypeDefinition)transformedVariable2.getType()).getSize().getValue().intValue() == targetTypeSize);
		assertTrue(((ArrayTypeDefinition)transformedVariable2.getType()).getElementType() instanceof BooleanTypeDefinition);
		assertNotNull(transformedVariable2.getExpression());
		assertTrue(transformedVariable2.getExpression() instanceof ArrayLiteralExpression);
		assertTrue(((ArrayLiteralExpression)transformedVariable2.getExpression()).getOperands().size() == 2);
		assertTrue(((ArrayLiteralExpression)transformedVariable2.getExpression()).getOperands().get(0) instanceof FalseExpression);
		assertTrue(((ArrayLiteralExpression)transformedVariable2.getExpression()).getOperands().get(1) instanceof TrueExpression);
	}
	
	@Test
	public void testJaggedArrayInRecordTransformation() {
		//var testRecord : record{p1 : array integer[2], p2 : array boolean[3]} := (# []{1, 2}, []{true, false, false}#)
		// Arrange
		// target name
		String targetName = "testRecord";
		// target type
		String p1Name = "p1";
		int p1Size = 2;
		IntegerTypeDefinition p1InnerType = expressionFactory.createIntegerTypeDefinition();
		IntegerLiteralExpression p1SizeExp = expressionFactory.createIntegerLiteralExpression();
		p1SizeExp.setValue(BigInteger.valueOf(p1Size));
		ArrayTypeDefinition p1Type = expressionFactory.createArrayTypeDefinition();
		p1Type.setSize(p1SizeExp);
		p1Type.setElementType(p1InnerType);
		
		FieldDeclaration p1 = expressionFactory.createFieldDeclaration();
		p1.setName(p1Name);
		p1.setType(p1Type);
		
		String p2Name = "p2";
		int p2Size = 3;
		BooleanTypeDefinition p2InnerType = expressionFactory.createBooleanTypeDefinition();
		IntegerLiteralExpression p2SizeExp = expressionFactory.createIntegerLiteralExpression();
		p2SizeExp.setValue(BigInteger.valueOf(p2Size));
		ArrayTypeDefinition p2Type = expressionFactory.createArrayTypeDefinition();
		p2Type.setSize(p2SizeExp);;
		p2Type.setElementType(p2InnerType);
		
		FieldDeclaration p2 = expressionFactory.createFieldDeclaration();
		p2.setName(p2Name);
		p2.setType(p2Type);
		
		RecordTypeDefinition targetType = expressionFactory.createRecordTypeDefinition();
		targetType.getFieldDeclarations().add(p1);
		targetType.getFieldDeclarations().add(p2);
		// target initial expression
		int p11 = 1;
		IntegerLiteralExpression p11Exp = expressionFactory.createIntegerLiteralExpression();
		p11Exp.setValue(BigInteger.valueOf(p11));
		int p12 = 2;
		IntegerLiteralExpression p12Exp = expressionFactory.createIntegerLiteralExpression();
		p12Exp.setValue(BigInteger.valueOf(p12));
		ArrayLiteralExpression p1InitialValue = expressionFactory.createArrayLiteralExpression();
		p1InitialValue.getOperands().add(p11Exp);
		p1InitialValue.getOperands().add(p12Exp);
		
		ArrayLiteralExpression p2InitialValue = expressionFactory.createArrayLiteralExpression();
		p2InitialValue.getOperands().add(expressionFactory.createTrueExpression());
		p2InitialValue.getOperands().add(expressionFactory.createFalseExpression());
		p2InitialValue.getOperands().add(expressionFactory.createFalseExpression());
		
		FieldAssignment p1Initial = expressionFactory.createFieldAssignment();
		p1Initial.setReference(p1Name);
		p1Initial.setValue(p1InitialValue);
		
		FieldAssignment p2Initial = expressionFactory.createFieldAssignment();
		p2Initial.setReference(p2Name);
		p2Initial.setValue(p2InitialValue);
		
		RecordLiteralExpression targetInitialExpression = expressionFactory.createRecordLiteralExpression();
		targetInitialExpression.getFieldAssignments().add(p1Initial);
		targetInitialExpression.getFieldAssignments().add(p2Initial);
		
		// target variable
		VariableDeclaration target = expressionFactory.createVariableDeclaration();
		target.setName(targetName);
		target.setType(targetType);
		target.setExpression(targetInitialExpression);
		// gamma package
		Package gammaPackage = createStatechartPackageWithActionAndVariable(actionFactory.createEmptyStatement(), target);
		GammaToLowlevelTransformer transformer = new GammaToLowlevelTransformer();
	
		// Act
		hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage = transformer.execute(gammaPackage);

		// Assert
		// variables (exist)
		assertNotNull(lowlevelPackage.getComponents().get(0));
		hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition transformedStatechart = (hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition) lowlevelPackage.getComponents().get(0);
		assertTrue(transformedStatechart.getVariableDeclarations().size() == (2 + assertionOffset));
		// var 1
		VariableDeclaration transformedVariable1 = transformedStatechart.getVariableDeclarations().get(0 + assertionOffset);
		assertTrue(transformedVariable1.getName().contains(targetName));
		assertTrue(transformedVariable1.getName().contains(p1Name));
		assertTrue(transformedVariable1.getType() instanceof ArrayTypeDefinition);
		assertTrue(((ArrayTypeDefinition)transformedVariable1.getType()).getSize().getValue().intValue() == p1Size);
		assertTrue(((ArrayTypeDefinition)transformedVariable1.getType()).getElementType() instanceof IntegerTypeDefinition);
		assertNotNull(transformedVariable1.getExpression());
		assertTrue(transformedVariable1.getExpression() instanceof ArrayLiteralExpression);
		assertTrue(((ArrayLiteralExpression)transformedVariable1.getExpression()).getOperands().size() == 2);
		assertTrue(((ArrayLiteralExpression)transformedVariable1.getExpression()).getOperands().get(0) instanceof IntegerLiteralExpression);
		assertTrue(((IntegerLiteralExpression)((ArrayLiteralExpression)transformedVariable1.getExpression()).getOperands().get(0)).getValue().intValue() == 1);
		assertTrue(((ArrayLiteralExpression)transformedVariable1.getExpression()).getOperands().get(1) instanceof IntegerLiteralExpression);
		assertTrue(((IntegerLiteralExpression)((ArrayLiteralExpression)transformedVariable1.getExpression()).getOperands().get(1)).getValue().intValue() == 2);
		// var 2
		VariableDeclaration transformedVariable2 = transformedStatechart.getVariableDeclarations().get(1 + assertionOffset);
		assertTrue(transformedVariable2.getName().contains(targetName));
		assertTrue(transformedVariable2.getName().contains(p2Name));
		assertTrue(transformedVariable2.getType() instanceof ArrayTypeDefinition);
		assertTrue(((ArrayTypeDefinition)transformedVariable2.getType()).getSize().getValue().intValue() == p2Size);
		assertTrue(((ArrayTypeDefinition)transformedVariable2.getType()).getElementType() instanceof BooleanTypeDefinition);
		assertNotNull(transformedVariable2.getExpression());
		assertTrue(transformedVariable2.getExpression() instanceof ArrayLiteralExpression);
		assertTrue(((ArrayLiteralExpression)transformedVariable2.getExpression()).getOperands().size() == 3);
		assertTrue(((ArrayLiteralExpression)transformedVariable2.getExpression()).getOperands().get(0) instanceof TrueExpression);
		assertTrue(((ArrayLiteralExpression)transformedVariable2.getExpression()).getOperands().get(1) instanceof FalseExpression);
		assertTrue(((ArrayLiteralExpression)transformedVariable2.getExpression()).getOperands().get(2) instanceof FalseExpression);
	}
	
	
	private Package createBasicStatechartPackageWithAction(Action action) {
		// Create statechart definition
		State initialState = statechartFactory.createState();
		initialState.setName("initial");
		State s1 = statechartFactory.createState();
		initialState.setName("s1");
		State s2 = statechartFactory.createState();
		initialState.setName("s2");
		
		OnCycleTrigger oct = statechartFactory.createOnCycleTrigger();
		
		Transition t1 = statechartFactory.createTransition();
		t1.setSourceState(initialState);
		t1.setTargetState(s1);
		Transition t2 = statechartFactory.createTransition();
		t2.setSourceState(s1);
		t2.setTargetState(s2);
		t2.setTrigger(oct);
		
		// Add the parameter to the model
		t2.getEffects().add(action);
		
		Region region = statechartFactory.createRegion();
		region.setName("testRegion");
		region.getStateNodes().add(initialState);
		region.getStateNodes().add(s1);	
		region.getStateNodes().add(s2);
		
		StatechartDefinition statechartDefinition = statechartFactory.createStatechartDefinition();
		statechartDefinition.setName("TestStatechart");
		statechartDefinition.getRegions().add(region);
		statechartDefinition.getTransitions().add(t1);
		statechartDefinition.getTransitions().add(t2);
		
		// Create the package
		Package gammaPackage = interfaceFactory.createPackage();
		gammaPackage.setName("testPackage");
		gammaPackage.getComponents().add(statechartDefinition);
		
		return gammaPackage;
	}
	
	private Package createStatechartPackageWithActionAndVariable(Action action, VariableDeclaration variable) {
		// Create statechart definition
		State initialState = statechartFactory.createState();
		initialState.setName("initial");
		State s1 = statechartFactory.createState();
		initialState.setName("s1");
		State s2 = statechartFactory.createState();
		initialState.setName("s2");
		
		OnCycleTrigger oct = statechartFactory.createOnCycleTrigger();
		
		Transition t1 = statechartFactory.createTransition();
		t1.setSourceState(initialState);
		t1.setTargetState(s1);
		Transition t2 = statechartFactory.createTransition();
		t2.setSourceState(s1);
		t2.setTargetState(s2);
		t2.setTrigger(oct);
		
		// Add the parameter to the model
		t2.getEffects().add(action);
		
		Region region = statechartFactory.createRegion();
		region.setName("testRegion");
		region.getStateNodes().add(initialState);
		region.getStateNodes().add(s1);	
		region.getStateNodes().add(s2);
		
		StatechartDefinition statechartDefinition = statechartFactory.createStatechartDefinition();
		statechartDefinition.setName("TestStatechart");
		statechartDefinition.getRegions().add(region);
		statechartDefinition.getTransitions().add(t1);
		statechartDefinition.getTransitions().add(t2);
		statechartDefinition.getVariableDeclarations().add(variable);
		
		// Create the package
		Package gammaPackage = interfaceFactory.createPackage();
		gammaPackage.setName("testPackage");
		gammaPackage.getComponents().add(statechartDefinition);
		
		return gammaPackage;
	}
	
	private Package createStatechartPackageWithActionAndVariables(Action action, VariableDeclaration variable1, VariableDeclaration variable2) {
		// Create statechart definition
		State initialState = statechartFactory.createState();
		initialState.setName("initial");
		State s1 = statechartFactory.createState();
		initialState.setName("s1");
		State s2 = statechartFactory.createState();
		initialState.setName("s2");
		
		OnCycleTrigger oct = statechartFactory.createOnCycleTrigger();
		
		Transition t1 = statechartFactory.createTransition();
		t1.setSourceState(initialState);
		t1.setTargetState(s1);
		Transition t2 = statechartFactory.createTransition();
		t2.setSourceState(s1);
		t2.setTargetState(s2);
		t2.setTrigger(oct);
		
		// Add the parameter to the model
		t2.getEffects().add(action);
		
		Region region = statechartFactory.createRegion();
		region.setName("testRegion");
		region.getStateNodes().add(initialState);
		region.getStateNodes().add(s1);	
		region.getStateNodes().add(s2);
		
		StatechartDefinition statechartDefinition = statechartFactory.createStatechartDefinition();
		statechartDefinition.setName("TestStatechart");
		statechartDefinition.getRegions().add(region);
		statechartDefinition.getTransitions().add(t1);
		statechartDefinition.getTransitions().add(t2);
		statechartDefinition.getVariableDeclarations().add(variable1);
		statechartDefinition.getVariableDeclarations().add(variable2);
		
		// Create the package
		Package gammaPackage = interfaceFactory.createPackage();
		gammaPackage.setName("testPackage");
		gammaPackage.getComponents().add(statechartDefinition);
		
		return gammaPackage;
	}
	
	private Package createStatechartPackageWithActionAndFunction(Action action, FunctionDeclaration functionDeclaration) {
		// Create statechart definition
		State initialState = statechartFactory.createState();
		initialState.setName("initial");
		State s1 = statechartFactory.createState();
		initialState.setName("s1");
		State s2 = statechartFactory.createState();
		initialState.setName("s2");
		
		OnCycleTrigger oct = statechartFactory.createOnCycleTrigger();
		
		Transition t1 = statechartFactory.createTransition();
		t1.setSourceState(initialState);
		t1.setTargetState(s1);
		Transition t2 = statechartFactory.createTransition();
		t2.setSourceState(s1);
		t2.setTargetState(s2);
		t2.setTrigger(oct);
		
		// Add the parameter to the model
		t2.getEffects().add(action);
		
		Region region = statechartFactory.createRegion();
		region.setName("testRegion");
		region.getStateNodes().add(initialState);
		region.getStateNodes().add(s1);	
		region.getStateNodes().add(s2);
		
		StatechartDefinition statechartDefinition = statechartFactory.createStatechartDefinition();
		statechartDefinition.setName("TestStatechart");
		statechartDefinition.getRegions().add(region);
		statechartDefinition.getTransitions().add(t1);
		statechartDefinition.getTransitions().add(t2);
		
		// Create the package
		Package gammaPackage = interfaceFactory.createPackage();
		gammaPackage.setName("testPackage");
		gammaPackage.getComponents().add(statechartDefinition);
		gammaPackage.getFunctionDeclarations().add(functionDeclaration);
		
		return gammaPackage;
	}
	
	private Package createStatechartPackageWithActionVariableAndFunction(Action action, VariableDeclaration variable, FunctionDeclaration functionDeclaration) {
		// Create statechart definition
		State initialState = statechartFactory.createState();
		initialState.setName("initial");
		State s1 = statechartFactory.createState();
		initialState.setName("s1");
		State s2 = statechartFactory.createState();
		initialState.setName("s2");
		
		OnCycleTrigger oct = statechartFactory.createOnCycleTrigger();
		
		Transition t1 = statechartFactory.createTransition();
		t1.setSourceState(initialState);
		t1.setTargetState(s1);
		Transition t2 = statechartFactory.createTransition();
		t2.setSourceState(s1);
		t2.setTargetState(s2);
		t2.setTrigger(oct);
		
		// Add the parameter to the model
		t2.getEffects().add(action);
		
		Region region = statechartFactory.createRegion();
		region.setName("testRegion");
		region.getStateNodes().add(initialState);
		region.getStateNodes().add(s1);	
		region.getStateNodes().add(s2);
		
		StatechartDefinition statechartDefinition = statechartFactory.createStatechartDefinition();
		statechartDefinition.setName("TestStatechart");
		statechartDefinition.getRegions().add(region);
		statechartDefinition.getTransitions().add(t1);
		statechartDefinition.getTransitions().add(t2);
		statechartDefinition.getVariableDeclarations().add(variable);
		
		// Create the package
		Package gammaPackage = interfaceFactory.createPackage();
		gammaPackage.setName("testPackage");
		gammaPackage.getComponents().add(statechartDefinition);
		gammaPackage.getFunctionDeclarations().add(functionDeclaration);
		
		return gammaPackage;
	}
	
	private ProcedureDeclaration createSimpleIntegerProcedure() {
		// procedure simpleIntegerProcedure() : integer { return 2; }
		IntegerLiteralExpression simpleIntegerProcedureReturnExpression = expressionFactory.createIntegerLiteralExpression();
		simpleIntegerProcedureReturnExpression.setValue(BigInteger.valueOf(simpleIntegerProcedureReturnValue));
		ReturnStatement simpleIntegerProcedureReturn = actionFactory.createReturnStatement();
		simpleIntegerProcedureReturn.setExpression(simpleIntegerProcedureReturnExpression);
		Block simpleIntegerProcedureBody = actionFactory.createBlock();
		simpleIntegerProcedureBody.getActions().add(simpleIntegerProcedureReturn);
		
		ProcedureDeclaration simpleIntegerProcedure = actionFactory.createProcedureDeclaration();
		simpleIntegerProcedure.setName(simpleIntegerProcedureName);
		simpleIntegerProcedure.setType(simpleIntegerProcedureReturnType);
		simpleIntegerProcedure.setBody(simpleIntegerProcedureBody);
		
		return simpleIntegerProcedure;
	}

}
