"
Script run, (*script_run:...) and its atomic form. The child matches first and the end continuation then rejects the match unless everything it consumed belongs to one script.
"
Class {
	#name : 'PCRE2ScriptRunNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'child'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'testing' }
PCRE2ScriptRunNode >> canAccept [

	^ child canAccept
]

{ #category : 'accessing' }
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

{ #category : 'optimization' }
PCRE2ScriptRunNode >> isAnchoredIn: analysis [
	"PCRE2 looks inside a script run for an anchor, but not for a line start."

	^ child isAnchoredIn: analysis
]

{ #category : 'accessing' }
PCRE2ScriptRunNode >> lengthBoundsUsing: groups names: names visited: visited [

	^ child lengthBoundsUsing: groups names: names visited: visited
]

{ #category : 'accessing' }
PCRE2ScriptRunNode >> maximumLength [

	^ child maximumLength
]

{ #category : 'accessing' }
PCRE2ScriptRunNode >> minimumLength [

	^ child minimumLength
]

{ #category : 'optimization' }
PCRE2ScriptRunNode >> requiredNode [

	^ child requiredNode
]
