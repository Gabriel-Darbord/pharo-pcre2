Class {
	#name : 'PCRE2QuotedSequenceNode',
	#superclass : 'PCRE2SequenceNode',
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'parsing' }
PCRE2QuotedSequenceNode >> repeatMinimum: minimum maximum: maximum greedy: greedy [

	children isEmpty ifTrue: [ PCRE2CompileError signal: 'quantifier does not follow a repeatable item' ].
	children at: children size put: (children last repeatMinimum: minimum maximum: maximum greedy: greedy).
	^ self
]
