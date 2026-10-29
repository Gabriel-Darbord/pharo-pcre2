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
PCRE2CharacterNode >> executeIn: engine state: state [

	state position >= engine subject size ifTrue: [
			engine notePartial: state.
			^ nil ].
	engine noteInspectionAt: state position.
	(predicate value: (engine subject at: state position + 1)) ifFalse: [ ^ nil ].
	state position: (engine subject nextOffsetFrom: state position).
	^ state
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
