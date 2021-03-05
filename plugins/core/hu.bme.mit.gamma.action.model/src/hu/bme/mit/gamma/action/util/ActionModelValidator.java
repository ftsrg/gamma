package hu.bme.mit.gamma.action.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;

import hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures;
import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.ActionModelPackage;
import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.action.model.Block;
import hu.bme.mit.gamma.action.model.Branch;
import hu.bme.mit.gamma.action.model.BreakStatement;
import hu.bme.mit.gamma.action.model.ChoiceStatement;
import hu.bme.mit.gamma.action.model.ConstantDeclarationStatement;
import hu.bme.mit.gamma.action.model.ExpressionStatement;
import hu.bme.mit.gamma.action.model.ForStatement;
import hu.bme.mit.gamma.action.model.IfStatement;
import hu.bme.mit.gamma.action.model.ProcedureDeclaration;
import hu.bme.mit.gamma.action.model.ReturnStatement;
import hu.bme.mit.gamma.action.model.SwitchStatement;
import hu.bme.mit.gamma.action.model.TypeReferenceExpression;
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.SelectExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.ValueDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator;
import hu.bme.mit.gamma.expression.util.ExpressionType;

public class ActionModelValidator extends ExpressionModelValidator {
	// Singleton
	public static final ActionModelValidator INSTANCE = new ActionModelValidator();
	protected ActionModelValidator() {}
	//
	
	public Collection<ValidationResultMessage> checkUnsupportedActions(Action action) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (action instanceof Block ||
				action instanceof BreakStatement ||
				action instanceof ChoiceStatement ||
				action instanceof ConstantDeclarationStatement ||
				action instanceof ExpressionStatement ||
				action instanceof ForStatement ||
				action instanceof IfStatement ||
				action instanceof ReturnStatement ||
				action instanceof SwitchStatement ||
				action instanceof VariableDeclarationStatement) {
			EObject container = action.eContainer();
			EReference eContainmentFeature = action.eContainmentFeature();
			Object object = container.eGet(eContainmentFeature, true);
			if (object instanceof List) {
				@SuppressWarnings("unchecked")
				List<Action> actions = (List<Action>) object;
				int index = actions.indexOf(action);
				//validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "Not supported action.",
				// new ReferenceInfo(eContainmentFeature, index, container)));
			}
			else {
				//validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "Not supported action.",
				//new ReferenceInfo(eContainmentFeature, null, container)));
			}
		}
		return validationResultMessages;
	}
	
	public 	Collection<ValidationResultMessage> checkAssignmentActions(AssignmentStatement assignment) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		ReferenceExpression reference = (ReferenceExpression) assignment.getLhs();
		Set<Declaration> declarations = new HashSet<>();
		declarations.addAll(expressionUtil.getReferredVariables(reference));
		declarations.addAll(expressionUtil.getReferredParameters(reference));
		declarations.addAll(expressionUtil.getReferredConstants(reference));
		// Constant

		Iterator<Declaration> iterator = declarations.iterator();	
		Declaration declaration = iterator.next();
		
		if (!(declaration instanceof VariableDeclaration)) {
			//validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,"Values can be assigned only to variables.",
			//		new ReferenceInfo(ActionModelPackage.Literals.ASSIGNMENT_STATEMENT__LHS,null)));
		}
		
		// Other assignment type checking
		if (declaration instanceof VariableDeclaration) {
			VariableDeclaration variableDeclaration = (VariableDeclaration) declaration;
			try {
				Type variableDeclarationType = variableDeclaration.getType();
				validationResultMessages.addAll(checkTypeAndExpressionConformance(variableDeclarationType, 
						assignment.getRhs(), 
						ActionModelPackage.Literals.ASSIGNMENT_STATEMENT__RHS));
			} catch (Exception exception) {
				// There is a type error on a lower level, no need to display the error message on this level too
			}
		}
		
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkDuplicateVariableDeclarationStatements(VariableDeclarationStatement statement) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		EObject container = statement.eContainer();
		if (container instanceof Block) {
			Block block = (Block) container;
			String name = statement.getVariableDeclaration().getName();
			List<VariableDeclaration> precedingVariableDeclarations =
					ActionModelDerivedFeatures.getPrecedingVariableDeclarations(block, statement);
			for (VariableDeclaration precedingVariableDeclaration : precedingVariableDeclarations) {
				String newName = precedingVariableDeclaration.getName();
				if (name.equals(newName)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"This variable cannot be named " + newName + " as it would enshadow a previous local variable.", 
							new ReferenceInfo(ActionModelPackage.Literals.VARIABLE_DECLARATION_STATEMENT__VARIABLE_DECLARATION,null)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkSelectExpression(SelectExpression expression){
		// check if the referred object is a value declaration
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Declaration referredDeclaration = expressionUtil.getDeclaration(expression);
		if ((referredDeclaration != null) && (referredDeclaration instanceof ValueDeclaration)) {
			return validationResultMessages;
		}
		// or an IR literal expression
		if ((expression.getOperand() instanceof IntegerRangeLiteralExpression)) {
			return validationResultMessages;
		}
		// or a type reference expression
		if ((expression.getOperand() instanceof ReferenceExpression) && (expression.getOperand() instanceof TypeReferenceExpression)) {
			return validationResultMessages;
		}
		// otherwise throw error
		validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
				"The specified object is not selectable: " + expression.getOperand().getClass(),
				new ReferenceInfo(ExpressionModelPackage.Literals.ACCESS_EXPRESSION__OPERAND, null)));
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> CheckReturnStatementType(ReturnStatement rs) {
		ExpressionType returnStatementType = typeDeterminator.getType(rs.getExpression());
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		ProcedureDeclaration containingProcedure = getContainingProcedure(rs);
		Type containingProcedureType = null;
		if(containingProcedure != null) {
			containingProcedureType = containingProcedure.getType();
		}
		if(!typeDeterminator.equals(containingProcedureType, returnStatementType)) {
			
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The type of the return statement (" + returnStatementType.toString().toLowerCase()
					+ ") does not match the declared type of the procedure (" 
					+ typeDeterminator.transform(containingProcedureType).toString().toLowerCase() + ").",
					null));
		}
		return validationResultMessages;
	}
	
	//TODO extract into util-class
	public ProcedureDeclaration getContainingProcedure(Action action) {
		EObject container = action.eContainer();
		if (container instanceof ProcedureDeclaration) {
			return (ProcedureDeclaration)container;
		} else if (container instanceof Branch) {
			return getContainingProcedure((Branch)container);
		} else if (container instanceof Block) {
			return getContainingProcedure((Action)container);
		} else if (container instanceof ForStatement) {
			return getContainingProcedure((Action)container);
		} else {
			return null;	//Not in a procedure
		}
	}
	
	//TODO extract into util-class
	public ProcedureDeclaration getContainingProcedure(Branch branch) {
		EObject container = branch.eContainer();
		if (container instanceof Action) {
			return getContainingProcedure((Action)container);
		} 
		throw new IllegalArgumentException("Unknown container for Branch.");
	}
}
