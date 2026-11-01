"
\R. Matches a line terminator under the convention the pattern or the compile context selected.
"
Class {
	#name : 'PCRE2NewlineNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'convention'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'accessing' }
PCRE2NewlineNode >> convention: policy [

	convention := policy
]

{ #category : 'matching' }
PCRE2NewlineNode >> executeIn: engine state: state [

	| length |
	length := convention lengthAt: state position + 1 in: engine subject.
	length = 0 ifTrue: [
			state position = engine subject size ifTrue: [ engine notePartial: state ].
			^ nil ].
	state position: state position + length.
	^ state
]

{ #category : 'accessing' }
PCRE2NewlineNode >> maximumLength [

	^ 2
]

{ #category : 'accessing' }
PCRE2NewlineNode >> minimumLength [

	^ 1
]
