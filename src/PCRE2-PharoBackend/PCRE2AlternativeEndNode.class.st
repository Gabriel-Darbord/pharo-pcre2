Class {
	#name : 'PCRE2AlternativeEndNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'previous'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'DFA matching' }
PCRE2AlternativeEndNode >> dfaKey [

	^ #alternativeEnd
]

{ #category : 'matching' }
PCRE2AlternativeEndNode >> executeIn: engine state: state [

	state alternations: previous.
	^ state
]

{ #category : 'DFA matching' }
PCRE2AlternativeEndNode >> maximumLength [

	^ 0
]

{ #category : 'matching' }
PCRE2AlternativeEndNode >> previous: frames [

	previous := frames
]

{ #category : 'diagnostics' }
PCRE2AlternativeEndNode >> runtimeStorageSize [

	^ self sizeInMemory
]

{ #category : 'DFA matching' }
PCRE2AlternativeEndNode >> startPredicate [

	^ [ :character | false ]
]
