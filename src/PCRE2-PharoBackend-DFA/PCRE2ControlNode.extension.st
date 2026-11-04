Extension { #name : 'PCRE2ControlNode' }

{ #category : '*PCRE2-PharoBackend-DFA' }
PCRE2ControlNode >> dfaError [

	^ kind = #fail
		  ifTrue: [ 0 ]
		  ifFalse: [ -42 ]
]
