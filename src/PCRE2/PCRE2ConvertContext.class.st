"
Abstract superclass for PCRE2 convert contexts.

Concrete subclasses bind PCRE2's width-specific native setters and lifetime functions: PCRE2UTF8ConvertContext, PCRE2UTF16ConvertContext, and PCRE2UTF32ConvertContext. This class keeps the shared Pharo-side state and user-facing accessors for glob escape and separator settings.
"
Class {
	#name : 'PCRE2ConvertContext',
	#superclass : 'PCRE2Object',
	#instVars : [
		'globEscape',
		'globSeparator'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'testing' }
PCRE2ConvertContext class >> isAbstract [

	^ self == PCRE2ConvertContext
]

{ #category : 'private' }
PCRE2ConvertContext >> checkSettingResult: resultCode [
	"PCRE2 convert-context setters answer zero or an error code."

	resultCode = 0 ifFalse: [ self errorCode: resultCode ].
	^ resultCode
]

{ #category : 'private' }
PCRE2ConvertContext >> codePointFor: aCharacterOrCodePoint [
	"Answer a uint32 code point accepted by PCRE2 setters."

	aCharacterOrCodePoint isCharacter ifTrue: [ ^ aCharacterOrCodePoint asInteger ].
	^ aCharacterOrCodePoint
]

{ #category : 'external resource management' }
PCRE2ConvertContext >> free [

	^ self subclassResponsibility
]

{ #category : 'accessing' }
PCRE2ConvertContext >> globEscape [
	"Escape character code used by glob conversion, or nil when PCRE2 uses its default."

	^ globEscape
]

{ #category : 'accessing' }
PCRE2ConvertContext >> globEscape: aCharacterOrCodePoint [
	"Set the escape character used by glob conversion. Use 0 to disable escaping."

	| codePoint |
	codePoint := self codePointFor: aCharacterOrCodePoint.
	self checkSettingResult: (self setGlobEscape: codePoint).
	globEscape := codePoint
]

{ #category : 'accessing' }
PCRE2ConvertContext >> globSeparator [
	"Path separator character code used by glob conversion, or nil when PCRE2 uses its default."

	^ globSeparator
]

{ #category : 'accessing' }
PCRE2ConvertContext >> globSeparator: aCharacterOrCodePoint [
	"Set the path separator used by glob conversion. PCRE2 accepts slash, backslash, or dot."

	| codePoint |
	codePoint := self codePointFor: aCharacterOrCodePoint.
	self checkSettingResult: (self setGlobSeparator: codePoint).
	globSeparator := codePoint
]

{ #category : 'copying' }
PCRE2ConvertContext >> postCopy [

	handle := self privateCopy.
	handle isNull ifTrue: [ PCRE2Error signal: 'Failed to obtain memory to copy convert context' ].
	self autoRelease
]

{ #category : 'private' }
PCRE2ConvertContext >> privateCopy [

	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2ConvertContext >> setGlobEscape: codePoint [

	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2ConvertContext >> setGlobSeparator: codePoint [

	^ self subclassResponsibility
]
