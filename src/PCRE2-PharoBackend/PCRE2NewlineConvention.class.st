Class {
	#name : 'PCRE2NewlineConvention',
	#superclass : 'Object',
	#instVars : [
		'mode'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2NewlineConvention >> lengthAt: index in: text [

	| code |
	(index between: 1 and: text size) ifFalse: [ ^ 0 ].
	code := (text at: index) asInteger.
	mode = PCRE2 newlineLF ifTrue: [
			^ code = 10
				  ifTrue: [ 1 ]
				  ifFalse: [ 0 ] ].
	mode = PCRE2 newlineCR ifTrue: [
			^ code = 13
				  ifTrue: [ 1 ]
				  ifFalse: [ 0 ] ].
	mode = PCRE2 newlineNul ifTrue: [
			^ code = 0
				  ifTrue: [ 1 ]
				  ifFalse: [ 0 ] ].
	(code = 13 and: [ index < text size and: [ (text at: index + 1) asInteger = 10 ] ]) ifTrue: [ ^ 2 ].
	mode = PCRE2 newlineCRLF ifTrue: [ ^ 0 ].
	(#( 10 13 ) includes: code) ifTrue: [ ^ 1 ].
	^ (mode = PCRE2 newlineAny and: [ #( 11 12 133 8232 8233 ) includes: code ])
		  ifTrue: [ 1 ]
		  ifFalse: [ 0 ]
]

{ #category : 'matching' }
PCRE2NewlineConvention >> lengthEndingAt: index in: text [

	| length |
	(index between: 1 and: text size) ifFalse: [ ^ 0 ].
	(index > 1 and: [ (self lengthAt: index - 1 in: text) = 2 ]) ifTrue: [ ^ 2 ].
	length := self lengthAt: index in: text.
	^ length = 1
		  ifTrue: [ 1 ]
		  ifFalse: [ 0 ]
]

{ #category : 'matching' }
PCRE2NewlineConvention >> mode [

	^ mode
]

{ #category : 'matching' }
PCRE2NewlineConvention >> mode: value [

	mode := value
]
