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

	^ (PCRE2UnicodeData isScriptRun: engine subject from: start + 1 to: state position) ifTrue: [ state ]
]

{ #category : 'matching' }
PCRE2ScriptRunEndNode >> start: position [

	start := position
]
