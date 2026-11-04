Extension { #name : 'PCRE2ConditionalNode' }

{ #category : '*PCRE2-PharoBackend-DFA' }
PCRE2ConditionalNode >> dfaError [

	^ dfaUnsupported value = true
		  ifTrue: [ -40 ]
		  ifFalse: [ 0 ]
]
