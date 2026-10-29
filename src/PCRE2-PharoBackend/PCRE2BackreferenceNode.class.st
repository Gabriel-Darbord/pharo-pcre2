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

{ #category : 'DFA matching' }
PCRE2BackreferenceNode >> dfaError [

	^ -42
]

{ #category : 'matching' }
PCRE2BackreferenceNode >> executeIn: engine state: state [

	| index start end text candidate available |
	index := engine captureIndexFor: reference state: state.
	index ifNil: [ ^ nil ].
	start := state captures at: index * 2 + 1.
	end := state captures at: index * 2 + 2.
	(start = PCRE2 unsetOffset or: [ end = PCRE2 unsetOffset ]) ifTrue: [
			^ (options bitAnd: PCRE2 matchUnsetBackref) = 0
				  ifTrue: [ nil ]
				  ifFalse: [ state ] ].
	text := engine subject copyFrom: start + 1 to: end.
	available := engine subject size - state position min: text size.
	candidate := engine subject copyFrom: state position + 1 to: state position + available.
	(self sameText: (text first: available) as: candidate) ifFalse: [ ^ nil ].
	available < text size ifTrue: [
			engine notePartial: (state copy position: engine subject size).
			^ nil ].
	state position: state position + text size.
	^ state
]

{ #category : 'matching' }
PCRE2BackreferenceNode >> lengthBoundsUsing: groups names: names visited: visited [

	| index target |
	index := reference isInteger
		         ifTrue: [ reference ]
		         ifFalse: [ names keyAtValue: reference ifAbsent: [ nil ] ].
	target := groups at: index ifAbsent: [ ^ { 0. nil } ].
	^ target lengthBoundsUsing: groups names: names visited: visited
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

{ #category : 'matching' }
PCRE2BackreferenceNode >> sameText: first as: second [

	^ (options bitAnd: PCRE2 caseless) = 0
		  ifTrue: [ first = second ]
		  ifFalse: [
				  first size = second size and: [
						  (1 to: first size) allSatisfy: [ :index |
							  PCRE2UnicodeData same: (first at: index) as: (second at: index) unicode: (options bitAnd: PCRE2 utf | PCRE2 ucp) ~= 0 ] ] ]
]
