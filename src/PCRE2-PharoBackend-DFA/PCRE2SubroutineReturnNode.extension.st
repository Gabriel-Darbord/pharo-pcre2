Extension { #name : 'PCRE2SubroutineReturnNode' }

{ #category : '*PCRE2-PharoBackend-DFA' }
PCRE2SubroutineReturnNode >> dfaKey [

	^ {
		  self class.
		  subroutines }
]
