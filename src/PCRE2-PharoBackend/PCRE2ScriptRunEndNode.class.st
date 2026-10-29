Class {
	#name : 'PCRE2ScriptRunEndNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'start'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2ScriptRunEndNode >> executeIn: engine state: state [

	| characters |
	characters := engine subject charactersFrom: start to: state position.
	^ (PCRE2UnicodeData isScriptRun: characters from: 1 to: characters size) ifTrue: [ state ]
]

{ #category : 'matching' }
PCRE2ScriptRunEndNode >> start: position [

	start := position
]
