Class {
	#name : 'PCRE2BackreferenceNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'reference',
		'options'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'private' }
PCRE2BackreferenceNode >> executeIn: anEngine state: aState [

	| index start end text candidate |
	index := anEngine captureIndexFor: reference.
	index ifNil: [ ^ nil ].
	start := aState captures at: index * 2 + 1.
	end := aState captures at: index * 2 + 2.
	(start = PCRE2 unsetOffset or: [ end = PCRE2 unsetOffset ]) ifTrue: [
			^ (options bitAnd: PCRE2 matchUnsetBackref) = 0
				  ifTrue: [ nil ]
				  ifFalse: [ aState ] ].
	aState position + end - start > anEngine subject size ifTrue: [ ^ nil ].
	text := anEngine subject copyFrom: start + 1 to: end.
	candidate := anEngine subject copyFrom: aState position + 1 to: aState position + end - start.
	((options bitAnd: PCRE2 caseless) = 0
		 ifTrue: [ text = candidate ]
		 ifFalse: [ text sameAs: candidate ]) ifFalse: [ ^ nil ].
	aState position: aState position + end - start.
	^ aState
]

{ #category : 'private' }
PCRE2BackreferenceNode >> options [

	^ options
]

{ #category : 'private' }
PCRE2BackreferenceNode >> options: aValue [

	options := aValue
]

{ #category : 'private' }
PCRE2BackreferenceNode >> reference [

	^ reference
]

{ #category : 'private' }
PCRE2BackreferenceNode >> reference: aValue [

	reference := aValue
]
