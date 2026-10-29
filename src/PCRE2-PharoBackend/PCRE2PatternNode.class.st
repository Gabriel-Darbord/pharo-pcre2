Class {
	#name : 'PCRE2PatternNode',
	#superclass : 'Object',
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2PatternNode >> acceptIn: engine state: state [

	^ false
]

{ #category : 'optimization' }
PCRE2PatternNode >> canAccept [

	^ false
]

{ #category : 'DFA matching' }
PCRE2PatternNode >> canAutoPossess [

	^ false
]

{ #category : 'parsing' }
PCRE2PatternNode >> canBeCondition [

	^ false
]

{ #category : 'parsing' }
PCRE2PatternNode >> canBeRepeated [

	^ true
]

{ #category : 'matching' }
PCRE2PatternNode >> conditionalIn: engine state: state [

	^ (self executeIn: engine state: state) isNotNil
]

{ #category : 'DFA matching' }
PCRE2PatternNode >> dfaError [

	^ 0
]

{ #category : 'DFA matching' }
PCRE2PatternNode >> dfaKey [

	^ self
]

{ #category : 'matching' }
PCRE2PatternNode >> executeIn: engine state: state [

	self subclassResponsibility
]

{ #category : 'matching' }
PCRE2PatternNode >> firstLiteral [

	^ nil
]

{ #category : 'optimization' }
PCRE2PatternNode >> firstLiteralPredicate [

	^ self firstLiteral ifNotNil: [ self startPredicate ]
]

{ #category : 'matching' }
PCRE2PatternNode >> lengthBoundsUsing: groups names: names visited: visited [

	^ {
		  self minimumLength.
		  self maximumLength }
]

{ #category : 'DFA matching' }
PCRE2PatternNode >> literalCharacter [

	^ nil
]

{ #category : 'matching' }
PCRE2PatternNode >> lookbehindBranches [

	^ { self }
]

{ #category : 'matching' }
PCRE2PatternNode >> maximumLength [

	^ nil
]

{ #category : 'matching' }
PCRE2PatternNode >> minimumLength [

	^ 0
]

{ #category : 'parsing' }
PCRE2PatternNode >> repeatMinimum: minimum maximum: maximum greedy: greedy [

	^ PCRE2RepeatNode new
		  child: self;
		  minimum: minimum;
		  maximum: maximum;
		  greedy: greedy
]

{ #category : 'optimization' }
PCRE2PatternNode >> requiredNode [

	^ nil
]

{ #category : 'diagnostics' }
PCRE2PatternNode >> runtimeStorageSize [

	^ 0
]

{ #category : 'matching' }
PCRE2PatternNode >> startPredicate [

	^ nil
]

{ #category : 'matching' }
PCRE2PatternNode >> terminatesWithAccept [

	^ false
]
