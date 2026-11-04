"
The literal characters of a \Q...\E sequence. A quantifier written after it applies to its last character only, as it does in PCRE2.
"
Class {
	#name : 'PCRE2QuotedSequenceNode',
	#superclass : 'PCRE2SequenceNode',
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'parsing' }
PCRE2QuotedSequenceNode >> repeatMinimum: minimum maximum: maximum greedy: greedy [
	"The quantifier repeats the last quoted character only; the parser keeps the sequence."

	children ifEmpty: [ PCRE2CompileError signal: 'quantifier does not follow a repeatable item' ].
	children at: children size put: (children last repeatMinimum: minimum maximum: maximum greedy: greedy)
]
