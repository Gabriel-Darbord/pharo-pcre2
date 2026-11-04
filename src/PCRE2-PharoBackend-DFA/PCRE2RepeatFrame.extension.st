Extension { #name : 'PCRE2RepeatFrame' }

{ #category : '*PCRE2-PharoBackend-DFA' }
PCRE2RepeatFrame >> dfaKey [

	^ {
		  repeat.
		  (repeat maximum ifNil: [ count min: repeat minimum ] ifNotNil: [ count ]).
		  previousPosition }
]
