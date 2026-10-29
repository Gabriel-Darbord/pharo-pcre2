Class {
	#name : 'PCRE2CompileContextFFIBackend',
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
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> addOptions: anInteger [

	^ self options: (self options bitOr: anInteger)
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> bsr [

	^ bsr
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> bsr: anInteger [
	"Set what \R matches. Prefer `useBSRAnyCRLF` and `useBSRUnicode` for named values."

	self checkSettingResult: (self setBSR: anInteger).
	bsr := anInteger
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> characterTables [
	"Low-character tables used by this compile context, or nil when PCRE2 uses its built-in tables."

	^ characterTables
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> characterTables: aPCRE2CharacterTables [
	"Use low-character tables for subsequent compilations through this context. Keep the tables alive while compiled patterns may reference them."

	aPCRE2CharacterTables ifNotNil: [
			aPCRE2CharacterTables isNull ifTrue: [ PCRE2Error signal: 'Character tables must hold a native table pointer' ].
			aPCRE2CharacterTables ffiLibraryName == self ffiLibraryName ifFalse: [
				PCRE2Error signal: 'Character tables must come from the same PCRE2 library width as the compile context' ] ].
	self checkSettingResult: (self setCharacterTables: aPCRE2CharacterTables).
	characterTables := aPCRE2CharacterTables
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> checkSettingResult: resultCode [
	"PCRE2 context setters answer zero or a negative error code. Keep native validation centralized so accessors can stay small."

	resultCode < 0 ifTrue: [ self errorCode: resultCode ].
	^ resultCode
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> clearCharacterTables [
	"Return this context to PCRE2's built-in low-character tables."

	^ self characterTables: nil
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> compilerClass [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> disableAutoPossessification [
	"Disable PCRE2's auto-possessification optimization."

	^ self optimize: PCRE2 optimizeAutoPossessOff
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> disableDotstarAnchoring [
	"Disable PCRE2's implicit dot-star anchoring optimization."

	^ self optimize: PCRE2 optimizeDotstarAnchorOff
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> disableStartOptimization [
	"Disable PCRE2's start-of-match optimizations."

	^ self optimize: PCRE2 optimizeStartOff
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> enableAutoPossessification [
	"Enable PCRE2's auto-possessification optimization."

	^ self optimize: PCRE2 optimizeAutoPossess
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> enableDotstarAnchoring [
	"Enable PCRE2's implicit dot-star anchoring optimization."

	^ self optimize: PCRE2 optimizeDotstarAnchor
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> enableStartOptimization [
	"Enable PCRE2's start-of-match optimizations."

	^ self optimize: PCRE2 optimizeStart
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> maxPatternCompiledLength [
	"Maximum compiled pattern size in bytes, or nil when PCRE2 uses its default."

	^ maxPatternCompiledLength
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> maxPatternCompiledLength: anInteger [
	"Set the maximum compiled pattern size in bytes accepted by pcre2_compile()."

	self
		requireSupportedFeature: 'Maximum compiled pattern length'
		since: '10.44'
		when: self ffiLibraryName supportsMaxPatternCompiledLength.
	self checkSettingResult: (self setMaxPatternCompiledLength: anInteger).
	maxPatternCompiledLength := anInteger
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> maxPatternLength [
	"Maximum pattern length in code units, or nil when PCRE2 uses its default."

	^ maxPatternLength
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> maxPatternLength: anInteger [
	"Set the maximum pattern length in code units accepted by pcre2_compile()."

	self checkSettingResult: (self setMaxPatternLength: anInteger).
	maxPatternLength := anInteger
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> maxVarLookbehind [
	"Maximum length for bounded variable-length lookbehind, or nil when PCRE2 uses its default."

	^ maxVarLookbehind
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> maxVarLookbehind: anInteger [
	"Set the maximum length for bounded variable-length lookbehind assertions."

	self requireSupportedFeature: 'Variable lookbehind limit' since: '10.43' when: self ffiLibraryName supportsMaxVarLookbehind.
	self checkSettingResult: (self setMaxVarLookbehind: anInteger).
	maxVarLookbehind := anInteger
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> newline [
	"Configured newline convention, or nil when PCRE2 uses the library default."

	^ newline
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> newline: anInteger [
	"Set which character sequence PCRE2 recognizes as a newline for compiled patterns."

	self checkSettingResult: (self setNewline: anInteger).
	newline := anInteger
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> optimizationDirectives [
	"Optimization directives applied to this context in order."

	^ optimizationDirectives ifNil: [ #(  ) ]
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> optimize: directive [
	"Apply one PCRE2 optimization directive. Directives are cumulative; later directives may override earlier ones."

	self requireSupportedFeature: 'Optimization directives' since: '10.45' when: self ffiLibraryName supportsOptimizationDirectives.
	self checkSettingResult: (self setOptimize: directive).
	optimizationDirectives := self optimizationDirectives copyWith: directive
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> options [
	"Extra compile option bits set through this context."

	^ options ifNil: [ 0 ]
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> options: anInteger [
	"Set PCRE2 extra compile options. See PCRE2 class-side methods beginning with 'extra' for known values."

	self checkSettingResult: (self setOptions: anInteger).
	options := anInteger
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> parensNestLimit [
	"Maximum parenthesis nesting depth, or nil when PCRE2 uses its default."

	^ parensNestLimit
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> parensNestLimit: anInteger [
	"Set the maximum parenthesis nesting depth accepted by pcre2_compile()."

	self checkSettingResult: (self setParensNestLimit: anInteger).
	parensNestLimit := anInteger
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> postCopy [

	handle := self privateCopy.
	handle isNull ifTrue: [ PCRE2Error signal: 'Failed to obtain memory to copy compile context' ].
	optimizationDirectives ifNotNil: [ optimizationDirectives := optimizationDirectives copy ].
	self autoRelease
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> privateCopy [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> removeOptions: anInteger [

	^ self options: (self options bitAnd: anInteger bitInvert)
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> requireSupportedFeature: featureName since: versionString when: aBoolean [
	"Fail before calling an FFI entry point that may not exist in older PCRE2 10.x runtimes."

	aBoolean ifTrue: [ ^ self ].
	PCRE2Error signal: featureName , ' requires PCRE2 ' , versionString , ' or newer; loaded ' , self ffiLibraryName versionString
]

{ #category : 'backends' }
PCRE2CompileContextFFIBackend >> restoreAfterStartup [
	"Recreate my native compile context and reapply remembered compile settings."

	| directives |
	self setHandle: (self compilerClass new backend: PCRE2CompilerFFIBackend) createCompileContext.
	self isNull ifTrue: [ PCRE2Error signal: 'Failed to restore compile context' ].
	bsr ifNotNil: [ self bsr: bsr ].
	options ifNotNil: [ self options: options ].
	newline ifNotNil: [ self newline: newline ].
	maxPatternLength ifNotNil: [ self maxPatternLength: maxPatternLength ].
	maxPatternCompiledLength ifNotNil: [ self maxPatternCompiledLength: maxPatternCompiledLength ].
	maxVarLookbehind ifNotNil: [ self maxVarLookbehind: maxVarLookbehind ].
	parensNestLimit ifNotNil: [ self parensNestLimit: parensNestLimit ].
	characterTables ifNotNil: [
			characterTables isNull ifTrue: [ characterTables restoreAfterStartup ].
			self characterTables: characterTables ].
	directives := optimizationDirectives.
	optimizationDirectives := nil.
	directives ifNotNil: [ directives do: [ :directive | self optimize: directive ] ]
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> setBSR: value [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> setCharacterTables: characterTablesOrNil [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> setMaxPatternCompiledLength: value [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> setMaxPatternLength: value [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> setMaxVarLookbehind: value [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> setNewline: value [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> setOptimize: directive [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> setOptions: value [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> setParensNestLimit: value [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> useBSRAnyCRLF [
	"\R matches only CR, LF, or CRLF."

	^ self bsr: PCRE2 bsrAnyCRLF
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> useBSRUnicode [
	"\R matches any Unicode line ending sequence."

	^ self bsr: PCRE2 bsrUnicode
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> useCharacterTablesFromCurrentLocale [
	"Build low-character tables from the current process locale and install them on this context."

	^ self characterTables: self ffiLibraryName newCharacterTables
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> useFullOptimization [
	"Enable all optional compiler optimizations."

	^ self optimize: PCRE2 optimizationFull
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> useNewlineAny [
	"Use any Unicode newline sequence."

	^ self newline: PCRE2 newlineAny
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> useNewlineAnyCRLF [
	"Use CR, LF, or CRLF as newline sequences."

	^ self newline: PCRE2 newlineAnyCRLF
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> useNewlineCR [
	"Use carriage return as the newline sequence."

	^ self newline: PCRE2 newlineCR
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> useNewlineCRLF [
	"Use CRLF as the newline sequence."

	^ self newline: PCRE2 newlineCRLF
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> useNewlineLF [
	"Use line feed as the newline sequence."

	^ self newline: PCRE2 newlineLF
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> useNewlineNul [
	"Use NUL as the newline sequence."

	^ self newline: PCRE2 newlineNul
]

{ #category : 'private - FFI' }
PCRE2CompileContextFFIBackend >> useNoOptimization [
	"Disable all optional compiler optimizations."

	^ self optimize: PCRE2 optimizationNone
]
