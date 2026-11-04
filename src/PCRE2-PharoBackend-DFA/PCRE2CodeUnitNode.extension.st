Extension { #name : 'PCRE2CodeUnitNode' }

{ #category : '*PCRE2-PharoBackend-DFA' }
PCRE2CodeUnitNode >> dfaError [

	^ unicodeWideUnit
		  ifTrue: [ -42 ]
		  ifFalse: [ 0 ]
]
