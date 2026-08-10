"
I also format senders of `ffiCall:`.
"
Class {
	#name : 'PCRE2Formatter',
	#superclass : 'EFFormatter',
	#category : 'BaselineOfPCRE2',
	#package : 'BaselineOfPCRE2'
}

{ #category : 'formatting' }
PCRE2Formatter >> formatFFICall: aMessageNode [

	| argument contents index |
	argument := aMessageNode arguments first.
	contents := argument contents.

	"Format return type and function name"
	codeStream nextPutAll: 'ffiCall: #('.
	codeStream nextPutAll: contents first value.
	codeStream space.
	index := self formatPointerAt: 2 inContents: contents.
	codeStream nextPutAll: (contents at: index) value.
	codeStream nextPut: $(.

	"Format FFI call arguments"
	contents := (contents at: index + 1) contents.
	index := 1.
	[ index <= contents size ] whileTrue: [
			| each |
			each := contents at: index.
			(#( self nil ) includes: each value)
				ifTrue: [ codeStream nextPutAll: each sourceText ]
				ifFalse: [
						codeStream nextPutAll: each value.
						codeStream space.
						index := self formatPointerAt: index + 1 inContents: contents.
						codeStream nextPutAll: (contents at: index) value ].
			index < contents size ifTrue: [ codeStream nextPutAll: ', ' ].
			index := index + 2 ].

	codeStream nextPutAll: '))'
]

{ #category : 'accessing' }
PCRE2Formatter >> formatPointerAt: index inContents: contents [

	| nextIndex |
	nextIndex := index.
	[ (contents at: nextIndex) value == #* ] whileTrue: [
			codeStream nextPut: $*.
			nextIndex := nextIndex + 1 ].
	^ nextIndex
]

{ #category : 'private - formatting' }
PCRE2Formatter >> formatSelectorAndArguments: aMessageNode [

	#ffiCall: == aMessageNode selector ifTrue: [
			self space formatFFICall: aMessageNode.
			^ self ].

	super formatSelectorAndArguments: aMessageNode
]
