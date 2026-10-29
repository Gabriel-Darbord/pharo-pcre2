Class {
	#name : 'PCRE2ScriptRunNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'child'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'optimization' }
PCRE2ScriptRunNode >> canAccept [

	^ child canAccept
]

{ #category : 'matching' }
PCRE2ScriptRunNode >> child: node [

	child := node
]

{ #category : 'DFA matching' }
PCRE2ScriptRunNode >> dfaError [

	^ -42
]

{ #category : 'matching' }
PCRE2ScriptRunNode >> executeIn: engine state: state [

	state
		push: (PCRE2ScriptRunEndNode new start: state position);
		push: child.
	^ state
]

{ #category : 'matching' }
PCRE2ScriptRunNode >> lengthBoundsUsing: groups names: names visited: visited [

	^ child lengthBoundsUsing: groups names: names visited: visited
]

{ #category : 'matching' }
PCRE2ScriptRunNode >> maximumLength [

	^ child maximumLength
]

{ #category : 'matching' }
PCRE2ScriptRunNode >> minimumLength [

	^ child minimumLength
]

{ #category : 'optimization' }
PCRE2ScriptRunNode >> requiredNode [

	^ child requiredNode
]
