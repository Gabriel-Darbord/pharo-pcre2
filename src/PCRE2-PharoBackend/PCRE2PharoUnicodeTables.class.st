"
The general categories, simple case folding and decimal digits of the image's own `Unicode` class, which `PCRE2UnicodeData` reads unless a package registers other tables.

Pharo 15 carries these tables at Unicode 18.0 since pharo-project/pharo#20168. Pharo 14 and older carry them at Unicode 9.0, so the baseline loads `PCRE2PackedUnicodeTables` there instead.

`Unicode` keeps its category numbers and its case folding in class variables with no accessor, so `categoryNames` and `caseFolding` read them by name.
"
Class {
	#name : 'PCRE2PharoUnicodeTables',
	#superclass : 'Object',
	#classInstVars : [
		'categoryNames',
		'equivalents'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'private' }
PCRE2PharoUnicodeTables class >> caseFolding [
	"Unicode's simple case folding, from code to code."

	^ Unicode readClassVariableNamed: #ToCasefold
]

{ #category : 'private' }
PCRE2PharoUnicodeTables class >> categoryNames [
	"The short name of each category number of Unicode, at that number plus one."

	^ categoryNames ifNil: [
			  | numbers |
			  numbers := #( #Cc #Cf #Cn #Co #Cs #Ll #Lm #Lo #Lt #Lu #Mc #Me #Mn #Nd #Nl #No #Pc #Pd #Pe #Pf #Pi #Po #Ps #Sc #Sk #Sm #So #Zl
			                #Zp #Zs ) collect: [ :category | category -> (Unicode readClassVariableNamed: category) ].
			  categoryNames := Array new: (numbers detectMax: [ :each | each value ]) value + 1.
			  numbers do: [ :each | categoryNames at: each value + 1 put: each key asLowercase asSymbol ].
			  categoryNames ]
]

{ #category : 'accessing' }
PCRE2PharoUnicodeTables class >> decimalValueOf: code [
	"Answer the value of code as a decimal digit, or nil when it is none."

	(self generalCategoryOf: code) == #nd ifFalse: [ ^ nil ].
	^ Unicode digitValueOf: (Character value: code)
]

{ #category : 'accessing' }
PCRE2PharoUnicodeTables class >> equivalents: code [
	"Answer the codes that fold as code does, in ascending order."

	equivalents ifNil: [ equivalents := PCRE2UnicodeData equivalentsUnder: self caseFolding ].
	^ PCRE2UnicodeData equivalentsOf: code in: equivalents
]

{ #category : 'accessing' }
PCRE2PharoUnicodeTables class >> fold: code [

	^ self caseFolding at: code ifAbsent: [ code ]
]

{ #category : 'accessing' }
PCRE2PharoUnicodeTables class >> generalCategoryOf: code [
	"Answer the short name of the general category of code, such as #lu."

	| table |
	table := Unicode generalCategory.
	code < table size ifFalse: [ ^ #cn ].
	^ self categoryNames at: (table at: code + 1) + 1
]

{ #category : 'class initialization' }
PCRE2PharoUnicodeTables class >> reset [

	categoryNames := nil.
	equivalents := nil
]
