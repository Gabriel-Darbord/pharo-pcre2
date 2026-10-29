Class {
	#name : 'PCRE2SequenceNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'children'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'private' }
PCRE2SequenceNode >> children [

	^ children
]

{ #category : 'private' }
PCRE2SequenceNode >> children: aValue [

	children := aValue
]

{ #category : 'private' }
PCRE2SequenceNode >> executeIn: anEngine state: aState [

	children reverseDo: [ :node | aState push: node ].
	^ aState
]

{ #category : 'matching' }
PCRE2SequenceNode >> maximumLength [

	| sum |
	sum := 0.
	children do: [ :node | node maximumLength ifNil: [ ^ nil ] ifNotNil: [ :length | sum := sum + length ] ].
	^ sum
]

{ #category : 'matching' }
PCRE2SequenceNode >> minimumLength [

	^ children inject: 0 into: [ :sum :node | sum + node minimumLength ]
]
