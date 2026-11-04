Extension { #name : 'PCRE2LookbehindNode' }

{ #category : '*PCRE2-PharoBackend-DFA' }
PCRE2LookbehindNode >> dfaError [

	^ atomic = false
		  ifTrue: [ -42 ]
		  ifFalse: [ 0 ]
]
