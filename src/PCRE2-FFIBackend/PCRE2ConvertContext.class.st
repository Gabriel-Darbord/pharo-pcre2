"
Abstract superclass of the contexts that set the glob escape and separator for pattern conversion. The settings are kept in the image, to be reapplied after startup; subclasses bind the functions of each code-unit width.
"
Class {
	#name : 'PCRE2ConvertContext',
	#superclass : 'PCRE2Object',
	#instVars : [
		'globEscape',
		'globSeparator'
	],
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
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

	aCharacterOrCodePoint isCharacter ifTrue: [ ^ aCharacterOrCodePoint asInteger ].
	^ aCharacterOrCodePoint
]

{ #category : 'accessing' }
PCRE2ConvertContext >> globEscape [
	"Escape character code used by glob conversion, or nil when PCRE2 uses its default."

	^ globEscape
]

{ #category : 'accessing' }
PCRE2ConvertContext >> globEscape: aCharacterOrCodePoint [
	"Use 0 to disable escaping."

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
	"PCRE2 accepts slash, backslash, or dot."

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

	self subclassResponsibility
]

{ #category : 'persistence' }
PCRE2ConvertContext >> restoreAfterStartup [
	"Recreate my native convert context and reapply remembered conversion settings."

	self setHandle: self ffiLibraryName uniqueInstance createConvertContext.
	self isNull ifTrue: [ PCRE2Error signal: 'Failed to restore convert context' ].
	globEscape ifNotNil: [ self globEscape: globEscape ].
	globSeparator ifNotNil: [ self globSeparator: globSeparator ]
]

{ #category : 'private' }
PCRE2ConvertContext >> setGlobEscape: codePoint [

	self subclassResponsibility
]

{ #category : 'private' }
PCRE2ConvertContext >> setGlobSeparator: codePoint [

	self subclassResponsibility
]
