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
	codeStream space nextPutAll: 'ffiCall: #('.
	codeStream nextPutAll: contents first value.
	codeStream space.
	index := self formatPointerAt: 2 inContents: contents.
	codeStream nextPutAll: (contents at: index) value.

	"Format parameters"
	codeStream nextPut: $(.
	self formatFFIParameters: (contents at: index + 1) contents.
	codeStream nextPutAll: '))'
]

{ #category : 'formatting' }
PCRE2Formatter >> formatFFICallback: aMessageNode [

	self indent: self indentsForKeywords around: [
			| contents index |
			self newLine.
			codeStream nextPutAll: 'signature: #('.
			contents := aMessageNode arguments first contents.
			codeStream nextPutAll: contents first value.
			index := self formatPointerAt: 2 inContents: contents.
			codeStream nextPutAll: ' ('.
			self formatFFIParameters: (contents at: index) contents.
			codeStream nextPutAll: '))'.

			self newLine.
			self indent: 0 around: [
					codeStream nextPutAll: 'block:'.
					self handleLineForArgument: aMessageNode arguments second ] ]
]

{ #category : 'formatting' }
PCRE2Formatter >> formatFFIParameters: contents [

	| index |
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
			index := index + 2 ]
]

{ #category : 'accessing' }
PCRE2Formatter >> formatPointerAt: index inContents: contents [

	| nextIndex symbol |
	nextIndex := index.
	[ (symbol := (contents at: nextIndex) value) first == $* ] whileTrue: [
			codeStream nextPutAll: symbol.
			nextIndex := nextIndex + 1 ].
	^ nextIndex
]

{ #category : 'private - formatting' }
PCRE2Formatter >> formatSelectorAndArguments: aMessageNode [

	aMessageNode selector == #ffiCall: ifTrue: [ ^ self formatFFICall: aMessageNode ].

	(aMessageNode receiver isVariable and: [
		 aMessageNode receiver name == #FFICallback and: [ aMessageNode selector == #signature:block: ] ]) ifTrue: [
		^ self formatFFICallback: aMessageNode ].

	super formatSelectorAndArguments: aMessageNode
]
