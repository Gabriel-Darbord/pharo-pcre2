"
Consumes exactly one code unit, including within UTF sequences. Its flag identifies UTF8/16 modes where PCRE2 forbids this node in lookbehind and DFA matching.
"
Class {
	#name : 'PCRE2CodeUnitNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'unicodeWideUnit'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'optimization' }
PCRE2CodeUnitNode >> canAutoPossess [

	^ true
]

{ #category : 'DFA matching' }
PCRE2CodeUnitNode >> dfaError [

	^ unicodeWideUnit
		  ifTrue: [ -42 ]
		  ifFalse: [ 0 ]
]

{ #category : 'matching' }
PCRE2CodeUnitNode >> executeIn: engine state: state [

	state position >= engine subject size ifTrue: [
			engine notePartial: state.
			^ nil ].
	engine noteInspectionAt: state position.
	state position: state position + 1.
	^ state
]

{ #category : 'accessing' }
PCRE2CodeUnitNode >> maximumLength [

	^ unicodeWideUnit ifFalse: [ 1 ]
]

{ #category : 'accessing' }
PCRE2CodeUnitNode >> minimumLength [

	^ 1
]

{ #category : 'accessing' }
PCRE2CodeUnitNode >> unicodeWideUnit: boolean [

	unicodeWideUnit := boolean
]
