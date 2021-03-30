package hu.bme.mit.gamma.expression.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature;
import org.eclipse.emf.ecore.util.EcoreUtil;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.ArgumentedElement;
import hu.bme.mit.gamma.expression.model.ArithmeticExpression;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BinaryExpression;
import hu.bme.mit.gamma.expression.model.BooleanExpression;
import hu.bme.mit.gamma.expression.model.ComparisonExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.DivExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.EquivalenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.FunctionDeclaration;
import hu.bme.mit.gamma.expression.model.IfThenElseExpression;
import hu.bme.mit.gamma.expression.model.InitializableElement;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.ModExpression;
import hu.bme.mit.gamma.expression.model.MultiaryExpression;
import hu.bme.mit.gamma.expression.model.NamedElement;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.PredicateExpression;
import hu.bme.mit.gamma.expression.model.RecordAccessExpression;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.SelectExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.UnaryExpression;
import hu.bme.mit.gamma.expression.model.ValueDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;

public class ExpressionModelValidator {
	// Singleton
	public static final ExpressionModelValidator INSTANCE = new ExpressionModelValidator();
	protected ExpressionModelValidator() {}
	//
	
	public enum ValidationResult{
		// Enum literals that determine the type of the message: error, info, warning.
		ERROR, INFO, WARNING
	}
	
	static public class ValidationResultMessage{
		
		private ValidationResult result;
		private String resultText;
		private ReferenceInfo referenceInfo;
		
		public ValidationResultMessage(ValidationResult result, String resultText,
				ReferenceInfo referenceInfo){
			this.result = result;
			this.resultText = resultText;
			this.referenceInfo = referenceInfo;
		}
		
		public ValidationResult getResult() {
			return result;
		}
		
		public String getResultText() {
			return resultText;
		}
		
		public ReferenceInfo getReferenceInfo() {
			return referenceInfo;
		}
		
	}
	
	static public class ReferenceInfo{
		
		private EStructuralFeature reference;
		private EObject source;
		private Integer index;
		
		public ReferenceInfo(EStructuralFeature reference, Integer index){
			this.reference = reference;
			this.index = index;
		}
		
		public ReferenceInfo(EStructuralFeature reference, Integer index, EObject source) {
			this.reference = reference;
			this.index = index;
			this.source = source;
		}
		
		public boolean hasSource() {
			return source != null;
		}
		
		public boolean hasInteger() {
			return index != null;
		}
		
		public EObject getSource() {
			return source;
		}
		
		public int getIndex() {
			return index;
		}
		
		public EStructuralFeature getReference() {
			return reference;
		}
	}
	
	protected ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE; // Redefinable
	protected ExpressionTypeDeterminator typeDeterminator = ExpressionTypeDeterminator.INSTANCE; // Redefinable
	protected final ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final JavaUtil javaUtil = JavaUtil.INSTANCE;
	
	public Collection<ValidationResultMessage> checkNameUniqueness(NamedElement element) {
		String name = element.getName();
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Class<? extends NamedElement> clazz = null;
		if (element instanceof Declaration) {
			clazz = Declaration.class;
		}
		else {
			clazz = element.getClass();
		}
		EObject root = EcoreUtil.getRootContainer(element);
		validationResultMessages.addAll(checkNames(root, Collections.singleton(clazz), name));
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkNames(EObject root,
			Collection<Class<? extends NamedElement>> classes, String name) {
		int nameCount = 0;
		Collection<NamedElement> namedElements = new ArrayList<NamedElement>();
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		for (Class<? extends NamedElement> clazz : classes) {
			List<? extends NamedElement> elements = ecoreUtil.getAllContentsOfType(root, clazz);
			namedElements.addAll(elements);
		}
		for (NamedElement otherElement : namedElements) {
			if (name.equals(otherElement.getName())) {
				++nameCount;
			}
			if (nameCount > 1) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"In a Gamma model, these identifiers must be unique.",
						new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME, null)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTypeDeclaration(TypeDeclaration typeDeclaration) {
		Type type = typeDeclaration.getType();
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (type instanceof TypeReference) {
			TypeReference typeReference = (TypeReference) type;
			TypeDeclaration referencedTypeDeclaration = typeReference.getReference();
			if (typeDeclaration == referencedTypeDeclaration) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"A type declaration cannot reference itself as a type definition."
						, new ReferenceInfo(ExpressionModelPackage.Literals.DECLARATION__TYPE, null)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkArgumentTypes(ArgumentedElement element, List<ParameterDeclaration> parameterDeclarations) {
		List<Expression> arguments = element.getArguments();
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (arguments.size() != parameterDeclarations.size()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The number of arguments must match the number of parameters.", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS, null)));
			return validationResultMessages;
		}
		if (!arguments.isEmpty() && !parameterDeclarations.isEmpty()) {
			for (int i = 0; i < arguments.size() && i < parameterDeclarations.size(); ++i) {
				ParameterDeclaration parameter = parameterDeclarations.get(i);
				Expression argument = arguments.get(i);
				validationResultMessages.addAll(checkTypeAndExpressionConformance(parameter.getType(), argument, 
						ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS));
			
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkIfThenElseExpression(IfThenElseExpression expression) {
		ExpressionType expressionType = typeDeterminator.getType(expression.getCondition());
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (expressionType != ExpressionType.BOOLEAN) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The condition of the if-then-else expression must be of type boolean, currently it is: " + expressionType.toString().toLowerCase(), 
					new ReferenceInfo(ExpressionModelPackage.Literals.IF_THEN_ELSE_EXPRESSION__CONDITION, null)));
		}
		if (typeDeterminator.getType(expression.getThen()) != typeDeterminator.getType(expression.getElse())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The return type of the else-branch does not match the type of the then-branch!", 
					new ReferenceInfo(ExpressionModelPackage.Literals.IF_THEN_ELSE_EXPRESSION__ELSE, null)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkArrayLiteralExpression(ArrayLiteralExpression expression) {
		ExpressionType referenceType = null;
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		for(Expression e : expression.getOperands()) {
			ExpressionType examinedType = typeDeterminator.getType(e);
			if (examinedType != referenceType) {
				if(referenceType == null) {
					referenceType = examinedType;
				}
				else {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The operands of the ArrayLiteralExpression are not of the same type!", null));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkRecordAccessExpression(
			RecordAccessExpression recordAccessExpression) {
		Declaration accessedDeclaration = 
				expressionUtil.getAccessedDeclaration(recordAccessExpression);
		RecordTypeDefinition recordType = (RecordTypeDefinition) 
				ExpressionModelDerivedFeatures.getTypeDefinition(accessedDeclaration);
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();;
		if (!(accessedDeclaration instanceof ValueDeclaration)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The referred declaration is not accessible as a record!", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ACCESS_EXPRESSION__OPERAND, null)));
			return validationResultMessages;
		}
		// Check if the referred field exists
		List<FieldDeclaration> fieldDeclarations = recordType.getFieldDeclarations();
		Declaration referredField = recordAccessExpression.getFieldReference().getFieldDeclaration();
		if (!fieldDeclarations.contains(referredField)){
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The record type does not contain any fields with the given name.", 
					new ReferenceInfo(ExpressionModelPackage.Literals.RECORD_ACCESS_EXPRESSION__FIELD_REFERENCE, null)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkFunctionAccessExpression(FunctionAccessExpression functionAccessExpression) {
		List<Expression> arguments = functionAccessExpression.getArguments();
		Expression operand = functionAccessExpression.getOperand();
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		// check if the referred object is a function
		if (!(operand instanceof DirectReferenceExpression)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The referenced object is not a valid function declaration!", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ACCESS_EXPRESSION__OPERAND, null)));
			return validationResultMessages;
		}
		DirectReferenceExpression operandAsReference = (DirectReferenceExpression) operand;
		if (!(operandAsReference.getDeclaration() instanceof FunctionDeclaration)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The referenced object is not a valid function declaration!", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ACCESS_EXPRESSION__OPERAND, null)));
			return validationResultMessages;
		}
		// check if the number of arguments equals the number of parameters
		final FunctionDeclaration functionDeclaration = (FunctionDeclaration) operandAsReference.getDeclaration();
		List<ParameterDeclaration> parameters = functionDeclaration.getParameterDeclarations();
		if (arguments.size() != parameters.size()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The number of arguments does not match the number of declared parameters for the function!", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS, null)));
			return validationResultMessages;
		}
		// check if the types of the arguments are the types of the parameters
		int i = 0;
		for (Expression arg : arguments) {
			ExpressionType argumentType = typeDeterminator.getType(arg);
			if (!typeDeterminator.equals(parameters.get(i).getType(), argumentType)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The types of the arguments and the types of the declared function parameters do not match!", 
						new ReferenceInfo(ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS, null)));
				return validationResultMessages;
				
			}
			++i;
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkArrayAccessExpression(ArrayAccessExpression expression) {
		// check if the referred declaration is accessible
		Declaration referredDeclaration = expressionUtil.getDeclaration(expression);
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!(referredDeclaration instanceof ValueDeclaration)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The referred declaration is not accessible as an array!", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ACCESS_EXPRESSION__OPERAND, null)));
			return validationResultMessages;
			
		}
		// check if the argument expression can be evaluated as integer
		if (!typeDeterminator.isInteger(expression.getArguments().get(0))) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The index of the accessed element must be of type integer!", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ARGUMENTED_ELEMENT__ARGUMENTS, null)));
			return validationResultMessages;
		}
		
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkSelectExpression(SelectExpression expression){
		// check if the referred object
		Declaration referredDeclaration = expressionUtil.getDeclaration(expression);
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if ((referredDeclaration != null) && !(referredDeclaration instanceof ValueDeclaration)) {
			// TODO check if array type
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The specified object is not selectable!", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ACCESS_EXPRESSION__OPERAND, null)));
			return validationResultMessages;
			
		}
		if (!(expression.getOperand() instanceof IntegerLiteralExpression || expression.getOperand() instanceof ReferenceExpression)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The specified object is not selectable!", 
					new ReferenceInfo(ExpressionModelPackage.Literals.ACCESS_EXPRESSION__OPERAND, null)));
			return validationResultMessages;
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkElseExpression(ElseExpression expression) {
		EObject container = expression.eContainer();
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (container instanceof Expression) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"Else expressions must not be contained by composite expressions.", 
					new ReferenceInfo(expression.eContainingFeature(), null)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkBooleanExpression(BooleanExpression expression) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (expression instanceof UnaryExpression) {
			// not
			UnaryExpression unaryExpression = (UnaryExpression) expression;
			if (!typeDeterminator.isBoolean(unaryExpression.getOperand())) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The operand of this unary boolean operation is evaluated as a non-boolean value.", 
						new ReferenceInfo(ExpressionModelPackage.Literals.UNARY_EXPRESSION__OPERAND, null)));
			}
		}
		else if (expression instanceof BinaryExpression) {
			// equal and imply
			BinaryExpression binaryExpression = (BinaryExpression) expression;
			if (!typeDeterminator.isBoolean(binaryExpression.getLeftOperand())) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The left operand of this binary boolean operation is evaluated as a non-boolean value.", 
						new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__LEFT_OPERAND, null)));
			}
			if (!typeDeterminator.isBoolean(binaryExpression.getRightOperand())) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The right operand of this binary boolean operation is evaluated as a non-boolean value.", 
						new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND, null)));
			}
		}
		else if (expression instanceof MultiaryExpression) {
			// and or or or xor
			MultiaryExpression multiaryExpression = (MultiaryExpression) expression;
			for (int i = 0; i < multiaryExpression.getOperands().size(); ++i) {
				Expression operand = multiaryExpression.getOperands().get(i);
				if (!typeDeterminator.isBoolean(operand)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"This operand of this multiary boolean operation is evaluated as a non-boolean value.", 
							new ReferenceInfo(ExpressionModelPackage.Literals.MULTIARY_EXPRESSION__OPERANDS, i)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkPredicateExpression(PredicateExpression expression) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (expression instanceof UnaryExpression) {
			// in expression, semantics not known
		}
		else if (expression instanceof BinaryExpression) {
			// Equivalence
			if (expression instanceof EquivalenceExpression) {
				EquivalenceExpression equivalenceExpression = (EquivalenceExpression) expression;
				Expression lhs = equivalenceExpression.getLeftOperand();
				Expression rhs = equivalenceExpression.getRightOperand();
				ExpressionType leftHandSideExpressionType = typeDeterminator.getType(lhs);
				ExpressionType rightHandSideExpressionType = typeDeterminator.getType(rhs);
				if (!leftHandSideExpressionType.equals(rightHandSideExpressionType)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The left and right hand sides are not compatible: " + leftHandSideExpressionType + " and " + rightHandSideExpressionType, 
							new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND, null)));
				}
				// Additional checks for enums
				else if (leftHandSideExpressionType == ExpressionType.ENUMERATION) {

					validationResultMessages.addAll(checkEnumerationConformance(lhs, rhs, 
							ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND));
				}
			}
			// Comparison
			if (expression instanceof ComparisonExpression) {
				ComparisonExpression binaryExpression = (ComparisonExpression) expression;
				if (!typeDeterminator.isNumber(binaryExpression.getLeftOperand())) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The left operand of this binary predicate expression is evaluated as a non-comparable value.", 
							new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__LEFT_OPERAND, null)));
				}
				if (!typeDeterminator.isNumber(binaryExpression.getRightOperand())) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The right operand of this binary predicate expression is evaluated as a non-comparable value.", 
							new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND, null)));
					
				}
			}
		}	
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTypeAndTypeConformance(Type lhs, Type rhs, EStructuralFeature feature) {
		ExpressionType leftHandSideExpressionType = typeDeterminator.transform(lhs);
		ExpressionType rightHandSideExpressionType = typeDeterminator.transform(rhs);
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!leftHandSideExpressionType.equals(rightHandSideExpressionType)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The types of the left hand side and the right hand side are not the same: " +
									leftHandSideExpressionType.toString().toLowerCase() + " and " +
									rightHandSideExpressionType.toString().toLowerCase() + ".", 
					new ReferenceInfo(feature, null)));
			return validationResultMessages;
			
		}
		validationResultMessages.addAll(checkEnumerationConformance(lhs, rhs, feature));
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkTypeAndExpressionConformance(Type type, Expression rhs, EStructuralFeature feature) {
		ExpressionType lhsExpressionType = typeDeterminator.transform(type);
		ExpressionType rhsExpressionType = typeDeterminator.getType(rhs);
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!lhsExpressionType.equals(rhsExpressionType)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The types of the declaration and the assigned expression are not the same: " +
									lhsExpressionType.toString().toLowerCase() + " and " +
									rhsExpressionType.toString().toLowerCase() + ".", 
					new ReferenceInfo(feature, null)));
			return validationResultMessages;
		}

		validationResultMessages.addAll(checkEnumerationConformance(type, rhs, feature));
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkEnumerationConformance(Type lhs, Type rhs, EStructuralFeature feature) {
		//addAll is used to add possible errors to the list
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		EnumerationTypeDefinition enumType = typeDeterminator.getEnumerationType(lhs);
		if (enumType != null) {
			final EnumerationTypeDefinition rhsType = typeDeterminator.getEnumerationType(rhs);
			validationResultMessages.addAll(checkEnumerationConformance(enumType, rhsType, feature));
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkEnumerationConformance(Type type, Expression rhs, EStructuralFeature feature) {
		//addAll is used to add possible errors to the list
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		EnumerationTypeDefinition enumType = typeDeterminator.getEnumerationType(type);
		if (enumType != null) {
			final EnumerationTypeDefinition rhsType = typeDeterminator.getEnumerationType(rhs);
			validationResultMessages.addAll(checkEnumerationConformance(enumType, rhsType, feature));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkEnumerationConformance(Expression lhs, Expression rhs, EStructuralFeature feature) {
		//addAll is used to add possible errors to the list
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		EnumerationTypeDefinition lhsType = typeDeterminator.getEnumerationType(lhs);
		EnumerationTypeDefinition rhsType = typeDeterminator.getEnumerationType(rhs);
		validationResultMessages.addAll(checkEnumerationConformance(lhsType, rhsType, feature));
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkEnumerationConformance(EnumerationTypeDefinition lhs, EnumerationTypeDefinition rhs,
			EStructuralFeature feature) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (lhs != rhs) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The right hand side is not the same type of enumeration as the left hand side.", 
					new ReferenceInfo(feature, null)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkArithmeticExpression(ArithmeticExpression expression) {
		
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		if (expression instanceof UnaryExpression) {
			// + or -
			UnaryExpression unaryExpression = (UnaryExpression) expression;
			if (!typeDeterminator.isNumber(unaryExpression.getOperand())) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The operand of this unary arithemtic operation is evaluated as a non-number value.", 
						new ReferenceInfo(ExpressionModelPackage.Literals.UNARY_EXPRESSION__OPERAND, null)));
			}
		}
		else if (expression instanceof BinaryExpression) {
			// - or / or mod or div
			BinaryExpression binaryExpression = (BinaryExpression) expression;
			if (expression instanceof ModExpression || expression instanceof DivExpression) {
				// Only integers can be operands
				if (!typeDeterminator.isInteger(binaryExpression.getLeftOperand())) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The left operand of this binary arithemtic operation is evaluated as a non-integer value.", 
							new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__LEFT_OPERAND, null)));
				}
				if (!typeDeterminator.isInteger(binaryExpression.getRightOperand())) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The right operand of this binary arithemtic operation is evaluated as a non-integer value.", 
							new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND, null)));
				}
			}
			else {
				if (!typeDeterminator.isNumber(binaryExpression.getLeftOperand())) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The left operand of this binary arithemtic operation is evaluated as a non-number value.", 
							new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__LEFT_OPERAND, null)));
				}
				if (!typeDeterminator.isNumber(binaryExpression.getRightOperand())) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The right operand of this binary arithemtic operation is evaluated as a non-number value.", 
							new ReferenceInfo(ExpressionModelPackage.Literals.BINARY_EXPRESSION__RIGHT_OPERAND, null)));
				}
			}
		}
		else if (expression instanceof MultiaryExpression) {
			// + or *
			MultiaryExpression multiaryExpression = (MultiaryExpression) expression;
			for (int i = 0; i < multiaryExpression.getOperands().size(); ++i) {
				Expression operand = multiaryExpression.getOperands().get(i);
				if (!typeDeterminator.isNumber(operand)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"This operand of this multiary arithemtic operation is evaluated as a non-number value.", 
							new ReferenceInfo(ExpressionModelPackage.Literals.MULTIARY_EXPRESSION__OPERANDS, i)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkInitializableElement(InitializableElement elem) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		try {
			Expression initialExpression = elem.getExpression();
			if (initialExpression == null) {
				return validationResultMessages;
			}
			// The declaration has an initial value
			EObject container = elem.eContainer();
			if (elem instanceof Declaration) {
				Declaration declaration = (Declaration) elem;
				for (VariableDeclaration variableDeclaration : expressionUtil.getReferredVariables(initialExpression)) {
					if (container == variableDeclaration.eContainer()) {
						final EList<EObject> eContents = container.eContents();
						int elemIndex = eContents.indexOf(elem);
						int variableIndex = eContents.indexOf(variableDeclaration);
						if (variableIndex >= elemIndex) {
							
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
									"The declarations referenced in the initial value must be declared before the variable declaration.", 
									new ReferenceInfo(ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION, null)));
							
							return validationResultMessages;
						}
					}
				}
				// Initial value is correct
				Type variableDeclarationType = declaration.getType();
				ExpressionType initialExpressionType = typeDeterminator.getType(elem.getExpression());
				if (!typeDeterminator.equals(variableDeclarationType, initialExpressionType)) {
					
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The types of the declaration and the right hand side expression are not the same: " +
											typeDeterminator.transform(variableDeclarationType).toString().toLowerCase() + " and " +
											initialExpressionType.toString().toLowerCase() + ".", 
							new ReferenceInfo(ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION, null)));
				} 
				// Additional checks for enumerations
				checkEnumerationConformance(variableDeclarationType, initialExpression, ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION);
				// Additional checks for arrays
				ArrayTypeDefinition arrayType = null;
				if (variableDeclarationType instanceof ArrayTypeDefinition) {
					arrayType = (ArrayTypeDefinition) variableDeclarationType;
				}
				else if (variableDeclarationType instanceof TypeReference &&
						((TypeReference) variableDeclarationType).getReference().getType() instanceof ArrayTypeDefinition) {
					arrayType = (ArrayTypeDefinition) ((TypeReference) variableDeclarationType).getReference().getType();
				}
				if (arrayType != null) {
					if (initialExpression instanceof ArrayLiteralExpression) {
						ArrayLiteralExpression rhs = (ArrayLiteralExpression) initialExpression;
						for(Expression e : rhs.getOperands()) {
							if(!typeDeterminator.equals(arrayType.getElementType(), typeDeterminator.getType(e))) {
								validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
										"The elements on the right hand side must be of the declared type of the array.", 
										new ReferenceInfo(ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION, null)));
							}
						}
					}
					else {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
								"The right hand side must be of type array literal.", 
								new ReferenceInfo(ExpressionModelPackage.Literals.INITIALIZABLE_ELEMENT__EXPRESSION, null)));
					}
				}
			}
		} catch (Exception exception) {
			// There is a type error on a lower level, no need to display the error message on this level too
		}
		return validationResultMessages;
	}
	
}