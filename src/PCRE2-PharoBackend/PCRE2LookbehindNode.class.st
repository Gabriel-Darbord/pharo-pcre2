Class {
	#name : 'PCRE2LookbehindNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'branches',
		'positive'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2LookbehindNode >> branches: anArray [

	branches := anArray
]

{ #category : 'matching' }
PCRE2LookbehindNode >> executeIn: anEngine state: aState [

	| result target |
	target := aState position.
	branches do: [ :branch |
			| sequence |
			sequence := PCRE2SequenceNode new children: {
					            branch.
					            (PCRE2PositionAssertionNode new position: target) }.
			(target - branch maximumLength max: 0) to: target - branch minimumLength do: [ :start |
					| before |
					before := aState copy position: start.
					result := anEngine matchNode: sequence state: before.
					result ifNotNil: [
							positive ifFalse: [ ^ nil ].
							aState captures: result captures.
							^ aState ] ] ].
	^ positive ifFalse: [ aState ]
]

{ #category : 'matching' }
PCRE2LookbehindNode >> maximumLength [

	^ 0
]

{ #category : 'matching' }
PCRE2LookbehindNode >> positive: aBoolean [

	positive := aBoolean
]
