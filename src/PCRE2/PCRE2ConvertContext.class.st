"
Holds settings used when PCRE2 converts foreign patterns into PCRE2 regular expressions.

Most conversions can use the library defaults. Create a convert context when glob conversion needs a different escape character or path separator.

    context := LibPCRE2UTF8 newConvertContext.
    context globEscape: $!.
    PCRE2 convertGlob: 'file!*.st' context: context.
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

{ #category : 'private' }
PCRE2ConvertContext >> checkSettingResult: resultCode [
	"PCRE2 convert-context setters answer zero or an error code."

	resultCode = 0 ifFalse: [ self errorCode: resultCode ].
	^ resultCode
]

{ #category : 'private' }
PCRE2ConvertContext >> codePointFor: aCharacterOrCodePoint [
	"Answer a uint32 code point accepted by PCRE2 setters."

	aCharacterOrCodePoint isCharacter ifTrue: [
		^ aCharacterOrCodePoint asInteger ].
	^ aCharacterOrCodePoint
]

{ #category : 'external resource management' }
PCRE2ConvertContext >> free [
	"Free the native convert context. PCRE2 ignores NULL."

	self ffiCall: #( void pcre2_convert_context_free_8
	   #( self ) )
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
	globEscape := codePoint.
	^ self
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
	globSeparator := codePoint.
	^ self
]

{ #category : 'copying' }
PCRE2ConvertContext >> postCopy [

	handle := self privateCopy.
	handle isNull ifTrue: [
		PCRE2Error signal: 'Failed to obtain memory to copy convert context' ].
	self autoRelease
]

{ #category : 'private' }
PCRE2ConvertContext >> privateCopy [
	"Create a native copy of this convert context.
	pcre2_convert_context *pcre2_convert_context_copy_8(pcre2_convert_context *cvcontext)"

	self ffiCall: #( void #* pcre2_convert_context_copy_8
	   #( self ) )
]

{ #category : 'private' }
PCRE2ConvertContext >> setGlobEscape: codePoint [
	"Set the native glob escape character.
	int pcre2_set_glob_escape_8(pcre2_convert_context *cvcontext, uint32_t escape_char)"

	self ffiCall:
		#( int pcre2_set_glob_escape_8 #( self #, uint32 codePoint ) )
]

{ #category : 'private' }
PCRE2ConvertContext >> setGlobSeparator: codePoint [
	"Set the native glob path separator.
	int pcre2_set_glob_separator_8(pcre2_convert_context *cvcontext, uint32_t separator_char)"

	self ffiCall:
		#( int pcre2_set_glob_separator_8 #( self #, uint32 codePoint ) )
]
