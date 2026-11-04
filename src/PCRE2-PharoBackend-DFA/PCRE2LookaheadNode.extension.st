Extension { #name : 'PCRE2LookaheadNode' }

{ #category : '*PCRE2-PharoBackend-DFA' }
PCRE2LookaheadNode >> dfaError [

	^ atomic = false
		  ifTrue: [ -42 ]
		  ifFalse: [ 0 ]
]
