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
package hu.bme.mit.gamma.codegeneration.java.util

import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition

import hu.bme.mit.gamma.expression.model.RecordTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeDeclaration

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class TypeDeclarationSerializer {
	// Singleton
	public static final TypeDeclarationSerializer INSTANCE = new TypeDeclarationSerializer
	protected new() {}
	//
	
	protected final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	
	def String serialize(TypeDeclaration type) {
		val declaredType = type.typeDefinition // So transitive references are solved
		return declaredType.serialize(type.name)
	}
	
	def dispatch String serialize(Type type, String name) {
		throw new IllegalArgumentException("Not supported type: " + type)
	}
	
	def dispatch String serialize(EnumerationTypeDefinition type, String name) '''
		enum «name» {«FOR literal : type.literals SEPARATOR ', '»«literal.name»«ENDFOR»}
	'''
	
	def dispatch String serialize(RecordTypeDefinition type, String name) '''
		class «name» {
			«FOR field : type.fieldDeclarations»
				protected «field.type.serialize» «field.name»;
				
				public «field.type.serialize» get«field.name.toFirstUpper»() {
					return this.«field.name»;
				}
				
				public void set«field.name.toFirstUpper»(«field.type.serialize» «field.name») {
					this.«field.name» = «field.name»;
				}
				
			«ENDFOR»
			public «name»(«FOR field : type.fieldDeclarations SEPARATOR ', '»«field.type.serialize» «field.name»«ENDFOR») {
				«FOR field : type.fieldDeclarations»
					this.«field.name» = «field.name»;
				«ENDFOR»
			}
			
			@Override
			public boolean equals(Object object) {
				if (this == object) {
					return true;
				}
				if (object == null) {
					return false;
				}
				if (this.getClass() != object.getClass()) {
					return false;
				}
				«name» record = («name») object;
				«FOR field : type.fieldDeclarations»
					if («IF field.type.isPrimitive»this.«field.name» != record.«field.name»«ELSE»!this.«field.name».equals(record.«field.name»)«ENDIF») {
						return false;
					}
				«ENDFOR»
				return true;
			}
			
		}
	'''
	
}