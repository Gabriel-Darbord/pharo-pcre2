"
Abstract superclass for PCRE2 compile contexts.

Concrete subclasses bind PCRE2's width-specific native setters and lifetime functions: PCRE2UTF8CompileContext, PCRE2UTF16CompileContext, and PCRE2UTF32CompileContext. This class keeps the shared Pharo-side state and user-facing accessors for newline handling, \R semantics, pattern-size limits, variable-lookbehind limits, locale character tables, extra compile options, and compiler optimization directives.
"
Class {
	#name : 'PCRE2CompileContext',
	#superclass : 'PCRE2Object',
	#instVars : [
		'bsr',
		'options',
		'newline',
		'maxPatternLength',
		'maxPatternCompiledLength',
		'maxVarLookbehind',
		'parensNestLimit',
		'optimizationDirectives',
		'characterTables'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'testing' }
PCRE2CompileContext class >> isAbstract [

	^ self == PCRE2CompileContext
]

{ #category : 'accessing' }
PCRE2CompileContext >> addOptions: anInteger [

	^ self options: (self options bitOr: anInteger)
]

{ #category : 'accessing' }
PCRE2CompileContext >> bsr [

	^ bsr
]

{ #category : 'accessing' }
PCRE2CompileContext >> bsr: anInteger [
	"Set what \R matches. Prefer `useBSRAnyCRLF` and `useBSRUnicode` for named values."

	self checkSettingResult: (self setBSR: anInteger).
	bsr := anInteger
]

{ #category : 'accessing' }
PCRE2CompileContext >> characterTables [
	"Low-character tables used by this compile context, or nil when PCRE2 uses its built-in tables."

	^ characterTables
]

{ #category : 'accessing' }
PCRE2CompileContext >> characterTables: aPCRE2CharacterTables [
	"Use low-character tables for subsequent compilations through this context. Keep the tables alive while compiled patterns may reference them."

	aPCRE2CharacterTables ifNotNil: [
			aPCRE2CharacterTables isNull ifTrue: [ PCRE2Error signal: 'Character tables must hold a native table pointer' ].
			aPCRE2CharacterTables ffiLibraryName == self ffiLibraryName ifFalse: [
				PCRE2Error signal: 'Character tables must come from the same PCRE2 library width as the compile context' ] ].
	self checkSettingResult: (self setCharacterTables: aPCRE2CharacterTables).
	characterTables := aPCRE2CharacterTables
]

{ #category : 'private' }
PCRE2CompileContext >> checkSettingResult: resultCode [
	"PCRE2 context setters answer zero or a negative error code. Keep native validation centralized so accessors can stay small."

	resultCode < 0 ifTrue: [ self errorCode: resultCode ].
	^ resultCode
]

{ #category : 'accessing' }
PCRE2CompileContext >> clearCharacterTables [
	"Return this context to PCRE2's built-in low-character tables."

	^ self characterTables: nil
]

{ #category : 'accessing' }
PCRE2CompileContext >> disableAutoPossessification [
	"Disable PCRE2's auto-possessification optimization."

	^ self optimize: PCRE2 optimizeAutoPossessOff
]

{ #category : 'accessing' }
PCRE2CompileContext >> disableDotstarAnchoring [
	"Disable PCRE2's implicit dot-star anchoring optimization."

	^ self optimize: PCRE2 optimizeDotstarAnchorOff
]

{ #category : 'accessing' }
PCRE2CompileContext >> disableStartOptimization [
	"Disable PCRE2's start-of-match optimizations."

	^ self optimize: PCRE2 optimizeStartOff
]

{ #category : 'accessing' }
PCRE2CompileContext >> enableAutoPossessification [
	"Enable PCRE2's auto-possessification optimization."

	^ self optimize: PCRE2 optimizeAutoPossess
]

{ #category : 'accessing' }
PCRE2CompileContext >> enableDotstarAnchoring [
	"Enable PCRE2's implicit dot-star anchoring optimization."

	^ self optimize: PCRE2 optimizeDotstarAnchor
]

{ #category : 'accessing' }
PCRE2CompileContext >> enableStartOptimization [
	"Enable PCRE2's start-of-match optimizations."

	^ self optimize: PCRE2 optimizeStart
]

{ #category : 'external resource management' }
PCRE2CompileContext >> free [

	^ self subclassResponsibility
]

{ #category : 'accessing' }
PCRE2CompileContext >> maxPatternCompiledLength [
	"Maximum compiled pattern size in bytes, or nil when PCRE2 uses its default."

	^ maxPatternCompiledLength
]

{ #category : 'accessing' }
PCRE2CompileContext >> maxPatternCompiledLength: anInteger [
	"Set the maximum compiled pattern size in bytes accepted by pcre2_compile()."

	self
		requireSupportedFeature: 'Maximum compiled pattern length'
		since: '10.44'
		when: self ffiLibraryName supportsMaxPatternCompiledLength.
	self checkSettingResult: (self setMaxPatternCompiledLength: anInteger).
	maxPatternCompiledLength := anInteger
]

{ #category : 'accessing' }
PCRE2CompileContext >> maxPatternLength [
	"Maximum pattern length in code units, or nil when PCRE2 uses its default."

	^ maxPatternLength
]

{ #category : 'accessing' }
PCRE2CompileContext >> maxPatternLength: anInteger [
	"Set the maximum pattern length in code units accepted by pcre2_compile()."

	self checkSettingResult: (self setMaxPatternLength: anInteger).
	maxPatternLength := anInteger
]

{ #category : 'accessing' }
PCRE2CompileContext >> maxVarLookbehind [
	"Maximum length for bounded variable-length lookbehind, or nil when PCRE2 uses its default."

	^ maxVarLookbehind
]

{ #category : 'accessing' }
PCRE2CompileContext >> maxVarLookbehind: anInteger [
	"Set the maximum length for bounded variable-length lookbehind assertions."

	self requireSupportedFeature: 'Variable lookbehind limit' since: '10.43' when: self ffiLibraryName supportsMaxVarLookbehind.
	self checkSettingResult: (self setMaxVarLookbehind: anInteger).
	maxVarLookbehind := anInteger
]

{ #category : 'accessing' }
PCRE2CompileContext >> newline [
	"Configured newline convention, or nil when PCRE2 uses the library default."

	^ newline
]

{ #category : 'accessing' }
PCRE2CompileContext >> newline: anInteger [
	"Set which character sequence PCRE2 recognizes as a newline for compiled patterns."

	self checkSettingResult: (self setNewline: anInteger).
	newline := anInteger
]

{ #category : 'accessing' }
PCRE2CompileContext >> optimizationDirectives [
	"Optimization directives applied to this context in order."

	^ optimizationDirectives ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
PCRE2CompileContext >> optimize: directive [
	"Apply one PCRE2 optimization directive. Directives are cumulative; later directives may override earlier ones."

	self requireSupportedFeature: 'Optimization directives' since: '10.45' when: self ffiLibraryName supportsOptimizationDirectives.
	self checkSettingResult: (self setOptimize: directive).
	optimizationDirectives := self optimizationDirectives copyWith: directive
]

{ #category : 'accessing' }
PCRE2CompileContext >> options [
	"Extra compile option bits set through this context."

	^ options ifNil: [ 0 ]
]

{ #category : 'accessing' }
PCRE2CompileContext >> options: anInteger [
	"Set PCRE2 extra compile options. See PCRE2 class-side methods beginning with 'extra' for known values."

	self checkSettingResult: (self setOptions: anInteger).
	options := anInteger
]

{ #category : 'accessing' }
PCRE2CompileContext >> parensNestLimit [
	"Maximum parenthesis nesting depth, or nil when PCRE2 uses its default."

	^ parensNestLimit
]

{ #category : 'accessing' }
PCRE2CompileContext >> parensNestLimit: anInteger [
	"Set the maximum parenthesis nesting depth accepted by pcre2_compile()."

	self checkSettingResult: (self setParensNestLimit: anInteger).
	parensNestLimit := anInteger
]

{ #category : 'copying' }
PCRE2CompileContext >> postCopy [

	handle := self privateCopy.
	handle isNull ifTrue: [ PCRE2Error signal: 'Failed to obtain memory to copy compile context' ].
	optimizationDirectives ifNotNil: [ optimizationDirectives := optimizationDirectives copy ].
	self autoRelease
]

{ #category : 'private' }
PCRE2CompileContext >> privateCopy [

	^ self subclassResponsibility
]

{ #category : 'accessing' }
PCRE2CompileContext >> removeOptions: anInteger [

	^ self options: (self options bitAnd: anInteger bitInvert)
]

{ #category : 'private' }
PCRE2CompileContext >> requireSupportedFeature: featureName since: versionString when: aBoolean [
	"Fail before calling an FFI entry point that may not exist in older PCRE2 10.x runtimes."

	aBoolean ifTrue: [ ^ self ].
	PCRE2Error signal: featureName , ' requires PCRE2 ' , versionString , ' or newer; loaded ' , self ffiLibraryName versionString
]

{ #category : 'private' }
PCRE2CompileContext >> setBSR: value [

	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2CompileContext >> setCharacterTables: characterTablesOrNil [

	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2CompileContext >> setMaxPatternCompiledLength: value [

	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2CompileContext >> setMaxPatternLength: value [

	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2CompileContext >> setMaxVarLookbehind: value [

	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2CompileContext >> setNewline: value [

	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2CompileContext >> setOptimize: directive [

	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2CompileContext >> setOptions: value [

	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2CompileContext >> setParensNestLimit: value [

	^ self subclassResponsibility
]

{ #category : 'accessing' }
PCRE2CompileContext >> useBSRAnyCRLF [
	"\R matches only CR, LF, or CRLF."

	^ self bsr: PCRE2 bsrAnyCRLF
]

{ #category : 'accessing' }
PCRE2CompileContext >> useBSRUnicode [
	"\R matches any Unicode line ending sequence."

	^ self bsr: PCRE2 bsrUnicode
]

{ #category : 'accessing' }
PCRE2CompileContext >> useCharacterTablesFromCurrentLocale [
	"Build low-character tables from the current process locale and install them on this context."

	^ self characterTables: self ffiLibraryName newCharacterTables
]

{ #category : 'accessing' }
PCRE2CompileContext >> useFullOptimization [
	"Enable all optional compiler optimizations."

	^ self optimize: PCRE2 optimizationFull
]

{ #category : 'accessing' }
PCRE2CompileContext >> useNewlineAny [
	"Use any Unicode newline sequence."

	^ self newline: PCRE2 newlineAny
]

{ #category : 'accessing' }
PCRE2CompileContext >> useNewlineAnyCRLF [
	"Use CR, LF, or CRLF as newline sequences."

	^ self newline: PCRE2 newlineAnyCRLF
]

{ #category : 'accessing' }
PCRE2CompileContext >> useNewlineCR [
	"Use carriage return as the newline sequence."

	^ self newline: PCRE2 newlineCR
]

{ #category : 'accessing' }
PCRE2CompileContext >> useNewlineCRLF [
	"Use CRLF as the newline sequence."

	^ self newline: PCRE2 newlineCRLF
]

{ #category : 'accessing' }
PCRE2CompileContext >> useNewlineLF [
	"Use line feed as the newline sequence."

	^ self newline: PCRE2 newlineLF
]

{ #category : 'accessing' }
PCRE2CompileContext >> useNewlineNul [
	"Use NUL as the newline sequence."

	^ self newline: PCRE2 newlineNul
]

{ #category : 'accessing' }
PCRE2CompileContext >> useNoOptimization [
	"Disable all optional compiler optimizations."

	^ self optimize: PCRE2 optimizationNone
]
