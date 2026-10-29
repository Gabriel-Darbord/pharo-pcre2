Class {
	#name : 'PCRE2CharacterNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'predicate',
		'character'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'DFA matching' }
PCRE2CharacterNode >> canAutoPossess [

	^ true
]

{ #category : 'accessing' }
PCRE2CharacterNode >> character [

	^ character
]

{ #category : 'accessing' }
PCRE2CharacterNode >> character: aCharacter [

	character := aCharacter
]

{ #category : 'matching' }
PCRE2CharacterNode >> executeIn: anEngine state: aState [

	aState position >= anEngine subject size ifTrue: [
			anEngine notePartial: aState.
			^ nil ].
	anEngine noteInspectionAt: aState position.
	(aState position < anEngine subject size and: [ predicate value: (anEngine subject at: aState position + 1) ]) ifFalse: [ ^ nil ].
	aState position: aState position + 1.
	^ aState
]

{ #category : 'matching' }
PCRE2CharacterNode >> firstLiteral [

	^ character
]

{ #category : 'DFA matching' }
PCRE2CharacterNode >> literalCharacter [

	^ character
]

{ #category : 'matching' }
PCRE2CharacterNode >> maximumLength [

	^ 1
]

{ #category : 'matching' }
PCRE2CharacterNode >> minimumLength [

	^ 1
]

{ #category : 'private' }
PCRE2CharacterNode >> predicate [

	^ predicate
]

{ #category : 'private' }
PCRE2CharacterNode >> predicate: aValue [

	predicate := aValue
]

{ #category : 'optimization' }
PCRE2CharacterNode >> requiredNode [

	^ character ifNotNil: [ self ]
]

{ #category : 'matching' }
PCRE2CharacterNode >> startPredicate [

	^ predicate
]
