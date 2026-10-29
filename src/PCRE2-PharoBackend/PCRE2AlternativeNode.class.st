Class {
	#name : 'PCRE2AlternativeNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'children'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'private' }
PCRE2AlternativeNode >> children [

	^ children
]

{ #category : 'private' }
PCRE2AlternativeNode >> children: aValue [

	children := aValue
]

{ #category : 'private' }
PCRE2AlternativeNode >> executeIn: anEngine state: aState [

	children size to: 2 by: -1 do: [ :index |
			| alternative |
			alternative := aState copy.
			alternative push: (children at: index).
			anEngine enqueue: alternative ].
	aState push: children first.
	^ aState
]

{ #category : 'matching' }
PCRE2AlternativeNode >> lookbehindBranches [

	^ children
]

{ #category : 'matching' }
PCRE2AlternativeNode >> maximumLength [

	| lengths |
	lengths := children collect: #maximumLength.
	(lengths includes: nil) ifTrue: [ ^ nil ].
	^ lengths max
]

{ #category : 'matching' }
PCRE2AlternativeNode >> minimumLength [

	^ (children collect: #minimumLength) min
]
