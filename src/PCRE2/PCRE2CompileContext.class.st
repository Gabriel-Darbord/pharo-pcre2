"
Holds compile-time PCRE2 settings used by PCRE2Compiler.

Most patterns do not need a compile context. Use one when you need to tune behavior saved into the compiled pattern, for example newline handling, \R semantics, pattern-size limits, variable-lookbehind limits, or compiler optimizations.

    compiler := PCRE2Compiler new.
    compiler context newline: PCRE2 newlineAnyCRLF.
    matcher := compiler compile: '^value'.

The context records values set from Pharo for inspection and copying; PCRE2 validates them when the native context is configured.
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
		'optimizationDirectives'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

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
	bsr := anInteger.
	^ self
]

{ #category : 'private' }
PCRE2CompileContext >> checkSettingResult: resultCode [
	"PCRE2 context setters answer zero or a negative error code. Keep native validation centralized so accessors can stay small."

	resultCode < 0 ifTrue: [ self errorCode: resultCode ].
	^ resultCode
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
	"This function frees the memory occupied by a compile context.
	If the argument is NULL, the function returns immediately without doing anything."

	self ffiCall: #(void pcre2_compile_context_free_8(self))
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
		when: LibPCRE2 supportsMaxPatternCompiledLength.
	self checkSettingResult:
		(self setMaxPatternCompiledLength: anInteger).
	maxPatternCompiledLength := anInteger.
	^ self
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
	maxPatternLength := anInteger.
	^ self
]

{ #category : 'accessing' }
PCRE2CompileContext >> maxVarLookbehind [
	"Maximum length for bounded variable-length lookbehind, or nil when PCRE2 uses its default."

	^ maxVarLookbehind
]

{ #category : 'accessing' }
PCRE2CompileContext >> maxVarLookbehind: anInteger [
	"Set the maximum length for bounded variable-length lookbehind assertions."

	self
		requireSupportedFeature: 'Variable lookbehind limit'
		since: '10.43'
		when: LibPCRE2 supportsMaxVarLookbehind.
	self checkSettingResult: (self setMaxVarLookbehind: anInteger).
	maxVarLookbehind := anInteger.
	^ self
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
	newline := anInteger.
	^ self
]

{ #category : 'accessing' }
PCRE2CompileContext >> optimizationDirectives [
	"Optimization directives applied to this context in order."

	^ optimizationDirectives ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
PCRE2CompileContext >> optimize: directive [
	"Apply one PCRE2 optimization directive. Directives are cumulative; later directives may override earlier ones."

	self
		requireSupportedFeature: 'Optimization directives'
		since: '10.45'
		when: LibPCRE2 supportsOptimizationDirectives.
	self checkSettingResult: (self setOptimize: directive).
	optimizationDirectives := self optimizationDirectives copyWith:
		                          directive.
	^ self
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
	options := anInteger.
	^ self
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
	parensNestLimit := anInteger.
	^ self
]

{ #category : 'copying' }
PCRE2CompileContext >> postCopy [

	handle := self privateCopy.
	handle isNull ifTrue: [
		PCRE2Error signal: 'Failed to obtain memory to copy compile context' ].
	optimizationDirectives ifNotNil: [
		optimizationDirectives := optimizationDirectives copy ].
	self autoRelease
]

{ #category : 'private' }
PCRE2CompileContext >> privateCopy [
	"This function makes a new copy of a compile context."

	"The result is NULL if the memory cannot be obtained."

	"pcre2_compile_context *pcre2_compile_context_copy_8(pcre2_compile_context *ccontext)"

	self ffiCall: #( void #* pcre2_compile_context_copy_8
	   #( self ) )
]

{ #category : 'accessing' }
PCRE2CompileContext >> removeOptions: anInteger [

	^ self options: (self options bitAnd: anInteger bitInvert)
]

{ #category : 'private' }
PCRE2CompileContext >> requireSupportedFeature: featureName since: versionString when: aBoolean [
	"Fail before calling an FFI entry point that may not exist in older PCRE2 10.x runtimes."

	aBoolean ifTrue: [ ^ self ].
	PCRE2Error signal: featureName , ' requires PCRE2 ' , versionString
		, ' or newer; loaded ' , LibPCRE2 versionString
]

{ #category : 'private' }
PCRE2CompileContext >> setBSR: value [
	"This function sets the convention for processing \R within a compile context."

	"The second argument must be one of PCRE2_BSR_ANYCRLF or PCRE2_BSR_UNICODE."

	"The result is zero for success or PCRE2_ERROR_BADDATA if the second argument is invalid."

	self ffiCall: #( int pcre2_set_bsr_8 #( self #, uint32 value ) )
]

{ #category : 'private' }
PCRE2CompileContext >> setMaxPatternCompiledLength: value [
	"Set the native compiled-pattern size limit."

	"int pcre2_set_max_pattern_compiled_length_8(pcre2_compile_context *ccontext, PCRE2_SIZE value)"

	self ffiCall: #( int pcre2_set_max_pattern_compiled_length_8
		   #( self #, size_t value ) )
]

{ #category : 'private' }
PCRE2CompileContext >> setMaxPatternLength: value [
	"Set the native pattern length limit."

	"int pcre2_set_max_pattern_length_8(pcre2_compile_context *ccontext, PCRE2_SIZE value)"

	self ffiCall:
		#( int pcre2_set_max_pattern_length_8 #( self #, size_t value ) )
]

{ #category : 'private' }
PCRE2CompileContext >> setMaxVarLookbehind: value [
	"Set the native bounded variable-lookbehind limit."

	"int pcre2_set_max_varlookbehind_8(pcre2_compile_context *ccontext, uint32_t value)"

	self ffiCall:
		#( int pcre2_set_max_varlookbehind_8 #( self #, uint32 value ) )
]

{ #category : 'private' }
PCRE2CompileContext >> setNewline: value [
	"Set the newline convention in the native compile context."

	"int pcre2_set_newline_8(pcre2_compile_context *ccontext, uint32_t value)"

	self ffiCall: #( int pcre2_set_newline_8 #( self #, uint32 value ) )
]

{ #category : 'private' }
PCRE2CompileContext >> setOptimize: directive [
	"Apply an optimization directive to the native compile context."

	"int pcre2_set_optimize_8(pcre2_compile_context *ccontext, uint32_t directive)"

	self ffiCall:
		#( int pcre2_set_optimize_8 #( self #, uint32 directive ) )
]

{ #category : 'private' }
PCRE2CompileContext >> setOptions [
	"Backward-compatible private wrapper used by older callers in this package."

	^ self setOptions: self options
]

{ #category : 'private' }
PCRE2CompileContext >> setOptions: value [
	"Set extra compile options on the native context."

	"int pcre2_set_compile_extra_options_8(pcre2_compile_context *ccontext, uint32_t extra_options)"

	self ffiCall: #( int pcre2_set_compile_extra_options_8
		   #( self #, uint32 value ) )
]

{ #category : 'private' }
PCRE2CompileContext >> setParensNestLimit: value [
	"Set the native parenthesis nesting limit."

	"int pcre2_set_parens_nest_limit_8(pcre2_compile_context *ccontext, uint32_t value)"

	self ffiCall:
		#( int pcre2_set_parens_nest_limit_8 #( self #, uint32 value ) )
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
