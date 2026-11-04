"
Backreference to a capture by number or by name. It compares the subject under the referenced group, honouring the caseless, Unicode and match-unset-backreference options the pattern was compiled with.
"
Class {
	#name : 'PCRE2BackreferenceNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'reference',
		'options',
		'extraOptions'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'generating' }
PCRE2BackreferenceNode >> byteReference [
	"The group number this compares against, or nil when a written matcher cannot decide it: a reference by name, a caseless one, or one under match-unset-backreference."

	^ (reference isInteger and: [ (options bitAnd: PCRE2 caseless | PCRE2 matchUnsetBackref) = 0 ]) ifTrue: [ reference ]
]

{ #category : 'matching' }
PCRE2BackreferenceNode >> executeIn: engine state: state [

	| index start end source target code sourceStep targetStep count available |
	index := engine captureIndexFor: reference state: state.
	index ifNil: [ ^ nil ].
	start := state captures at: index * 2 + 1.
	end := state captures at: index * 2 + 2.
	(start = PCRE2 unsetOffset or: [ end = PCRE2 unsetOffset ]) ifTrue: [
			^ (options bitAnd: PCRE2 matchUnsetBackref) = 0
				  ifTrue: [ nil ]
				  ifFalse: [ state ] ].
	target := state position.
	(options bitAnd: PCRE2 caseless) = 0 ifTrue: [
			count := end - start.
			available := count min: engine subject size - target.
			0 to: available - 1 do: [ :offset |
				(engine subject codeUnitAtOffset: start + offset) = (engine subject codeUnitAtOffset: target + offset) ifFalse: [ ^ nil ] ].
			available < count ifTrue: [
					engine notePartial: (state copy position: engine subject size).
					^ nil ].
			state position: target + count.
			^ state ].
	source := start.
	[ source < end ] whileTrue: [
			target >= engine subject size ifTrue: [
					engine notePartial: (state copy position: engine subject size).
					^ nil ].
			code := engine subject at: source + 1.
			(PCRE2UnicodeData
				 same: code
				 as: (engine subject at: target + 1)
				 unicode: (options bitAnd: PCRE2 utf | PCRE2 ucp) ~= 0
				 extraOptions: (extraOptions ifNil: [ 0 ])) ifFalse: [ ^ nil ].
			sourceStep := engine subject pointWidthAtOffset: source.
			targetStep := engine subject pointWidthAtOffset: target.
			source := source + sourceStep.
			target := target + targetStep ].
	state position: target.
	^ state
]

{ #category : 'accessing' }
PCRE2BackreferenceNode >> extraOptions: flags [

	extraOptions := flags
]

{ #category : 'accessing' }
PCRE2BackreferenceNode >> lengthBoundsUsing: groups names: names visited: visited [

	| index target |
	(options bitAnd: PCRE2 matchUnsetBackref) ~= 0 ifTrue: [ ^ { 0. nil } ].
	(reference isString and: [ (names values count: [ :name | name = reference ]) > 1 ]) ifTrue: [ ^ { 0. nil } ].
	index := reference isInteger
		         ifTrue: [ reference ]
		         ifFalse: [ names keyAtValue: reference ifAbsent: [ nil ] ].
	target := groups at: index ifAbsent: [ ^ { 0. nil } ].
	^ target lengthBoundsUsing: groups names: names visited: visited
]

{ #category : 'accessing' }
PCRE2BackreferenceNode >> options [

	^ options
]

{ #category : 'accessing' }
PCRE2BackreferenceNode >> options: anInteger [

	options := anInteger
]

{ #category : 'accessing' }
PCRE2BackreferenceNode >> reference [

	^ reference
]

{ #category : 'accessing' }
PCRE2BackreferenceNode >> reference: aReference [

	reference := aReference
]

{ #category : 'generating' }
PCRE2BackreferenceNode >> writeInto: aGenerator at: position then: aBlock [

	^ aGenerator writeBackreference: self byteReference at: position then: aBlock
]
