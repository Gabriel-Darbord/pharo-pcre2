"
Runtime continuation an alternation pushes behind each branch to restore the alternation scope that branch was entered in. Built while matching, never by the parser.
"
Class {
	#name : 'PCRE2AlternativeEndNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'previous'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2AlternativeEndNode >> executeIn: engine state: state [

	state alternations: previous.
	^ state
]

{ #category : 'accessing' }
PCRE2AlternativeEndNode >> maximumLength [

	^ 0
]

{ #category : 'accessing' }
PCRE2AlternativeEndNode >> previous: frames [

	previous := frames
]

{ #category : 'diagnostics' }
PCRE2AlternativeEndNode >> runtimeStorageSize [

	^ self sizeInMemory
]

{ #category : 'optimization' }
PCRE2AlternativeEndNode >> startPredicate [

	^ [ :character | false ]
]
