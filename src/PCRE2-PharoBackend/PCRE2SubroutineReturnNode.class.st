Class {
	#name : 'PCRE2SubroutineReturnNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'captures',
		'subroutines',
		'lastCapture'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2SubroutineReturnNode >> acceptIn: engine state: state [

	self executeIn: engine state: state.
	^ true
]

{ #category : 'matching' }
PCRE2SubroutineReturnNode >> captures: anArray [

	captures := anArray
]

{ #category : 'DFA matching' }
PCRE2SubroutineReturnNode >> dfaKey [

	^ {
		  self class.
		  subroutines }
]

{ #category : 'matching' }
PCRE2SubroutineReturnNode >> executeIn: anEngine state: aState [

	| restored |
	restored := captures copy.
	restored at: 1 put: aState captures first.
	aState
		captures: restored;
		lastCapture: lastCapture;
		subroutines: subroutines.
	^ aState
]

{ #category : 'matching' }
PCRE2SubroutineReturnNode >> lastCapture: number [

	lastCapture := number
]

{ #category : 'diagnostics' }
PCRE2SubroutineReturnNode >> runtimeStorageSize [

	^ self sizeInMemory + captures sizeInMemory
]

{ #category : 'matching' }
PCRE2SubroutineReturnNode >> subroutines: frames [

	subroutines := frames
]
