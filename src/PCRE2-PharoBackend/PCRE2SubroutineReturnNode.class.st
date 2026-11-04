"
Runtime continuation that restores the captures, the alternation scope and the subroutine stack a subroutine call was made in, keeping the groups the call asked to retain.
"
Class {
	#name : 'PCRE2SubroutineReturnNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'captures',
		'subroutines',
		'lastCapture',
		'retainedGroups',
		'alternations'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2SubroutineReturnNode >> acceptIn: engine state: state [

	state subroutines ifNotNil: [ :frame | engine trimChoicesTo: frame third ].
	self executeIn: engine state: state.
	^ true
]

{ #category : 'accessing' }
PCRE2SubroutineReturnNode >> alternations: aFrame [

	alternations := aFrame
]

{ #category : 'accessing' }
PCRE2SubroutineReturnNode >> captures: anArray [

	captures := anArray
]

{ #category : 'matching' }
PCRE2SubroutineReturnNode >> executeIn: anEngine state: aState [

	| restored |
	restored := captures copy.
	restored at: 1 put: aState captures first.
	(retainedGroups ifNil: [ #(  ) ]) do: [ :index |
			restored at: index * 2 + 1 put: (aState captures at: index * 2 + 1).
			restored at: index * 2 + 2 put: (aState captures at: index * 2 + 2) ].
	aState
		captures: restored;
		alternations: alternations;
		lastCapture: (((retainedGroups ifNil: [ #(  ) ]) includes: aState lastCapture)
				 ifTrue: [ aState lastCapture ]
				 ifFalse: [ lastCapture ]);
		subroutines: subroutines.
	^ aState
]

{ #category : 'accessing' }
PCRE2SubroutineReturnNode >> lastCapture: number [

	lastCapture := number
]

{ #category : 'accessing' }
PCRE2SubroutineReturnNode >> retainedGroups: indexes [

	retainedGroups := indexes
]

{ #category : 'diagnostics' }
PCRE2SubroutineReturnNode >> runtimeStorageSize [

	^ self sizeInMemory + captures sizeInMemory
]

{ #category : 'accessing' }
PCRE2SubroutineReturnNode >> subroutines: frames [

	subroutines := frames
]
