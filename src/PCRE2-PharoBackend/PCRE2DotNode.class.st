Class {
	#name : 'PCRE2DotNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'convention',
		'dotAll'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'DFA matching' }
PCRE2DotNode >> canAutoPossess [

	^ true
]

{ #category : 'matching' }
PCRE2DotNode >> convention: policy dotAll: boolean [

	convention := policy.
	dotAll := boolean
]

{ #category : 'matching' }
PCRE2DotNode >> executeIn: engine state: state [

	state position >= engine subject size ifTrue: [
			engine notePartial: state.
			^ nil ].
	(dotAll not and: [
			 (convention lengthAt: state position + 1 in: engine subject) > 0 or: [
				 convention mode = PCRE2 newlineCRLF and: [ (convention lengthEndingAt: state position + 1 in: engine subject) = 2 ] ] ])
		ifTrue: [ ^ nil ].
	engine noteInspectionAt: state position.
	state position: (engine subject nextOffsetFrom: state position).
	^ state
]

{ #category : 'matching' }
PCRE2DotNode >> maximumLength [

	^ 1
]

{ #category : 'matching' }
PCRE2DotNode >> minimumLength [

	^ 1
]
