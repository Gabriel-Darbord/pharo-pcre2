Class {
	#name : 'PCRE2GraphemeNode',
	#superclass : 'PCRE2PatternNode',
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'DFA matching' }
PCRE2GraphemeNode >> canAutoPossess [

	^ true
]

{ #category : 'matching' }
PCRE2GraphemeNode >> executeIn: engine state: state [

	state position >= engine subject size ifTrue: [
			engine notePartial: state.
			^ nil ].
	state position: (PCRE2UnicodeData graphemeEndIn: engine subject from: state position).
	state position = engine subject size ifTrue: [ engine notePartial: state ].
	^ state
]

{ #category : 'matching' }
PCRE2GraphemeNode >> minimumLength [

	^ 1
]
