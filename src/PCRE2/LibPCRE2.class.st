"
I locate and expose the native PCRE2 8-bit library used by this binding.

All exported calls target the libpcre2-8 API. String-like arguments are passed as prepared UTF-8 byte storage, typically through void* FFI declarations, so Pharo does not silently apply its own string conversion policy.

At startup I verify that the loaded native library is compatible with the binding's supported PCRE2 major version.
"
Class {
	#name : 'LibPCRE2',
	#superclass : 'FFILibrary',
	#pools : [
		'PCRE2Types'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'version management' }
LibPCRE2 class >> assertCompatibleLibrary [

	^ self uniqueInstance assertCompatibleLibrary
]

{ #category : 'documentation' }
LibPCRE2 class >> config: option [

	^ self uniqueInstance config: option
]

{ #category : 'persistence' }
LibPCRE2 class >> deserialize: bytes [

	^ self uniqueInstance deserialize: bytes
]

{ #category : 'library path' }
LibPCRE2 class >> libraryBasename [

	^ 'libpcre2-8'
]

{ #category : 'instance creation' }
LibPCRE2 class >> newMatchContext [

	^ self uniqueInstance newMatchContext
]

{ #category : 'version management' }
LibPCRE2 class >> requiredMajorVersion [
	"This binding targets PCRE2 10.x. Minor releases may change diagnostics or reported sizes, but a different major version should be reviewed before use."

	^ 10
]

{ #category : 'persistence' }
LibPCRE2 class >> restore: matchers from: bytes [

	self uniqueInstance restore: matchers from: bytes
]

{ #category : 'persistence' }
LibPCRE2 class >> serialize: matchers [

	^ self uniqueInstance serialize: matchers
]

{ #category : 'version management' }
LibPCRE2 class >> supports8BitCodeUnitWidth [

	^ self uniqueInstance supports8BitCodeUnitWidth
]

{ #category : 'version management' }
LibPCRE2 class >> supportsJIT [

	^ self uniqueInstance supportsJIT
]

{ #category : 'version management' }
LibPCRE2 class >> supportsMaxPatternCompiledLength [
	"PCRE2 10.44 added pcre2_set_max_pattern_compiled_length()."

	^ self uniqueInstance supportsMaxPatternCompiledLength
]

{ #category : 'version management' }
LibPCRE2 class >> supportsMaxVarLookbehind [
	"PCRE2 10.43 added bounded variable-length lookbehind support and its compile-context limit."

	^ self uniqueInstance supportsMaxVarLookbehind
]

{ #category : 'version management' }
LibPCRE2 class >> supportsOptimizationDirectives [
	"PCRE2 10.45 added pcre2_set_optimize()."

	^ self uniqueInstance supportsOptimizationDirectives
]

{ #category : 'version management' }
LibPCRE2 class >> supportsSubstitutionCallouts [
	"PCRE2 10.33 added pcre2_set_substitute_callout()."

	^ self uniqueInstance supportsSubstitutionCallouts
]

{ #category : 'version management' }
LibPCRE2 class >> supportsUnicode [

	^ self uniqueInstance supportsUnicode
]

{ #category : 'version management' }
LibPCRE2 class >> version [

	^ self uniqueInstance version
]

{ #category : 'version management' }
LibPCRE2 class >> versionDate [

	^ self uniqueInstance versionDate
]

{ #category : 'version management' }
LibPCRE2 class >> versionMajor [

	^ self uniqueInstance versionMajor
]

{ #category : 'version management' }
LibPCRE2 class >> versionMinor [

	^ self uniqueInstance versionMinor
]

{ #category : 'version management' }
LibPCRE2 class >> versionString [

	^ self uniqueInstance versionString
]

{ #category : 'documentation' }
LibPCRE2 >> allConfigs [
	"All configuration information about the PCRE2 library.
	Includes the obsolete PCRE2_CONFIG_STACKRECURSE at index 9 which is always 0."

	^ (0 to: 15) collect: [ :option | self config: option ]
]

{ #category : 'version management' }
LibPCRE2 >> assertCompatibleLibrary [
	"Fail early when the loaded native library does not match the assumptions of this binding."

	self versionMajor = self class requiredMajorVersion ifFalse: [
		PCRE2Error signal:
			'Unsupported PCRE2 major version ' , self versionMajor asString
			, ' from ' , self versionString , '. This binding targets PCRE2 '
			, self class requiredMajorVersion asString , '.x' ].
	self supports8BitCodeUnitWidth ifFalse: [
		PCRE2Error signal:
			'The loaded PCRE2 library was not compiled with 8-bit code unit support' ].
	self supportsUnicode ifFalse: [
		PCRE2Error signal:
			'The loaded PCRE2 library was not compiled with Unicode support' ].
	^ self
]

{ #category : 'documentation' }
LibPCRE2 >> config: option [
	"Returns some configuration information about the PCRE2 library.
	See class-side methods of PCRE2 starting with 'config' to find valid arguments."

	| buffer rc |
	(option = PCRE2 configJITTarget or: [
		 option = PCRE2 configUnicodeVersion or: [
			 option = PCRE2 configVersion ] ]) ifFalse: [ "requesting a number"
		buffer := UInt32Holder new.
		rc := self config: option output: buffer.
		rc < 0 ifTrue: [ self errorCode: rc ].
		^ buffer value ].

	"requesting a string"
	buffer := ByteArray new: 64. "should be big enough"
	rc := self config: option output: buffer. "if success, rc is the number of code units used, including the terminating zero"
	rc < 0 ifTrue: [ self errorCode: rc ].
	^ (String new: rc - 1)
		  replaceFrom: 1
		  to: rc - 1
		  with: buffer
		  startingAt: 1
]

{ #category : 'private' }
LibPCRE2 >> config: what output: where [
	"This function makes it possible for a client program to find out which optional features are available in the version of the PCRE2 library it is using.
	int pcre2_config(uint32_t what, void *where)"

	self ffiCall: #(int pcre2_config_8(uint32 what, void *where))
]

{ #category : 'private' }
LibPCRE2 >> createMatchContext [
	"This function creates and initializes a new match context.
	If its argument is NULL, malloc() is used to get the necessary memory; otherwise the memory allocation function within the general context is used.
	The result is NULL if the memory could not be obtained."

	self ffiCall: #(PCRE2MatchContext *pcre2_match_context_create_8(nil))
]

{ #category : 'serializing' }
LibPCRE2 >> deserialize: bytes [
	"Returns the array of handles for the compiled patterns deserialized from the bytes.
	Only useful if you know what to do with external addresses."

	| count pointers |
	count := self serializedNumberOfCodes: bytes.
	count < 0 ifTrue: [ self errorCode: count ].
	pointers := ByteArray new: count * ExternalAddress wordSize.
	count := self deserialize: bytes count: count output: pointers.
	count < 0 ifTrue: [ self errorCode: count ].
	^ pointers
]

{ #category : 'private' }
LibPCRE2 >> deserialize: bytes count: count output: buffer [
	"Decode a serialized byte stream into compiled-pattern pointers. Both arguments are raw byte/pointer buffers prepared by the caller, so keep UFFI out of their contents with void*.
	int32_t pcre2_serialize_decode_8(pcre2_code **codes, int32_t number_of_codes, const uint8_t *bytes, pcre2_general_context *gcontext)"

	self ffiCall:
		#( int32 pcre2_serialize_decode_8 #( void #* buffer #, int32 count
		      #, void #* bytes #, nil ) )
]

{ #category : 'error handling' }
LibPCRE2 >> errorCode: errorCode [

	<debuggerCompleteToSender>
	PCRE2Error signal: (PCRE2 translateErrorCode: errorCode)
]

{ #category : 'accessing - platform' }
LibPCRE2 >> macLibraryName [
	"Can be installed with homebrew"

	^ FFIMacLibraryFinder findLibrary:
		  self class libraryBasename , '.dylib'
]

{ #category : 'instance creation' }
LibPCRE2 >> newMatchContext [

	| context |
	context := self createMatchContext.
	context isNull ifTrue: [
		PCRE2Error signal: 'Failed to obtain memory to create match context' ].
	^ context autoRelease
]

{ #category : 'serializing' }
LibPCRE2 >> restore: matchers from: bytes [
	"Restore a list of compiled patterns from their serialized form. JIT data is not serialized, so matchers rebuild it best-effort afterwards."

	| count wordSize pointers rc |
	count := matchers size.
	wordSize := ExternalAddress wordSize.
	pointers := ByteArray new: count * wordSize.

	rc := self deserialize: bytes count: count output: pointers.
	rc < 0 ifTrue: [ self errorCode: rc ].

	1 to: count do: [ :i |
		| matcher |
		(matcher := matchers at: i) setHandle:
			(pointers pointerAtOffset: wordSize * (i - 1)).
		matcher restoreJITIfNeeded ]
]

{ #category : 'accessing' }
LibPCRE2 >> runner [

	^ TFProcessLocalWorker new
		  defaultWorker: TFSameThreadRunner uniqueInstance;
		  yourself
]

{ #category : 'serializing' }
LibPCRE2 >> serialize: matchers [

	| pointers buffer bufferSize rc externBytes bytes |
	bufferSize := ExternalAddress wordSize.
	pointers := ByteArray new: matchers size * bufferSize.
	1 to: matchers size do: [ :i |
		pointers
			pointerAtOffset: bufferSize * (i - 1)
			put: (matchers at: i) getHandle ].
	buffer := ByteArray new: bufferSize.

	"bufferSize is updated with the size of the allocated memory"
	rc := self
		      serialize: pointers
		      count: matchers size
		      output: buffer
		      size: (bufferSize := SizeTHolder new).
	rc < 0 ifTrue: [
		(buffer allSatisfy: [ :bit | bit == 0 ]) ifFalse: [ "if not NULL"
			self serializeFree: buffer ].
		self errorCode: rc ].

	"copy the encoded bytes into the image and free the memory"
	externBytes := buffer pointerAtOffset: 0.
	bytes := ByteArray new: (bufferSize := bufferSize value).
	1 to: bufferSize do: [ :i |
	bytes at: i put: (externBytes uint8AtOffset: i - 1) ].
	self serializeFree: externBytes.
	^ bytes
]

{ #category : 'private' }
LibPCRE2 >> serialize: matchers count: count output: bytes size: bufferSize [
	"Encode compiled-pattern pointers into a PCRE2-owned serialized byte stream. The pointers table and output pointer slot are raw memory buffers, so pass them as void*.
	int32_t pcre2_serialize_encode_8(const pcre2_code **codes, int32_t number_of_codes, uint8_t **serialized_bytes, PCRE2_SIZE *serialized_size, pcre2_general_context *gcontext)"

	self ffiCall:
		#( int32 pcre2_serialize_encode_8 #( void #* matchers #, int32 count
		      #, void #* bytes #, SizeTHolder #* bufferSize #, nil ) )
]

{ #category : 'private' }
LibPCRE2 >> serializeFree: bytes [
	"Free a serialized byte stream allocated by PCRE2."

	self ffiCall: #( void pcre2_serialize_free_8 #( void #* bytes ) )
]

{ #category : 'private' }
LibPCRE2 >> serializedNumberOfCodes: bytes [
	"Return the number of compiled patterns in a serialized byte stream. The byte stream is already materialized, so pass it as an opaque buffer.
	int32_t pcre2_serialize_get_number_of_codes_8(const uint8_t *bytes)"

	self ffiCall: #( int32 pcre2_serialize_get_number_of_codes_8
		   #( void #* bytes ) )
]

{ #category : 'version management' }
LibPCRE2 >> supports8BitCodeUnitWidth [
	"PCRE2_CONFIG_COMPILED_WIDTHS is a bitmask; bit 0 means 8-bit support."

	^ ((self config: PCRE2 configCompiledWidths) bitAnd: 1) = 1
]

{ #category : 'version management' }
LibPCRE2 >> supportsJIT [

	^ (self config: PCRE2 configJIT) = 1
]

{ #category : 'version management' }
LibPCRE2 >> supportsMaxPatternCompiledLength [

	^ self versionAtLeastMajor: 10 minor: 44
]

{ #category : 'version management' }
LibPCRE2 >> supportsMaxVarLookbehind [

	^ self versionAtLeastMajor: 10 minor: 43
]

{ #category : 'version management' }
LibPCRE2 >> supportsOptimizationDirectives [

	^ self versionAtLeastMajor: 10 minor: 45
]

{ #category : 'version management' }
LibPCRE2 >> supportsSubstitutionCallouts [

	^ self versionAtLeastMajor: 10 minor: 33
]

{ #category : 'version management' }
LibPCRE2 >> supportsUnicode [

	^ (self config: PCRE2 configUnicode) = 1
]

{ #category : 'accessing - platform' }
LibPCRE2 >> unix32LibraryName [

	^ FFIUnix32LibraryFinder findLibrary:
		  self class libraryBasename , '.so'
]

{ #category : 'accessing - platform' }
LibPCRE2 >> unix64LibraryName [

	^ FFIUnix64LibraryFinder findLibrary:
		  self class libraryBasename , '.so'
]

{ #category : 'accessing - platform' }
LibPCRE2 >> unixLibraryName [

	^ self unix32LibraryName
]

{ #category : 'version management' }
LibPCRE2 >> version [
	"Answer { major. minor. dateStringOrNil } parsed from the PCRE2 runtime version."

	| fields numbers |
	fields := self versionString substrings.
	numbers := fields first findTokens: '.'.
	^ {
		  numbers first asInteger.
		  (numbers at: 2 ifAbsent: [ '0' ]) asInteger.
		  (fields at: 2 ifAbsent: [ nil ]) }
]

{ #category : 'version management' }
LibPCRE2 >> versionAtLeastMajor: major minor: minor [
	"Answer whether the loaded runtime is at least the given PCRE2 version."

	self versionMajor > major ifTrue: [ ^ true ].
	self versionMajor = major ifFalse: [ ^ false ].
	^ self versionMinor >= minor
]

{ #category : 'version management' }
LibPCRE2 >> versionDate [

	^ self version third
]

{ #category : 'version management' }
LibPCRE2 >> versionMajor [

	^ self version first
]

{ #category : 'version management' }
LibPCRE2 >> versionMinor [

	^ self version second
]

{ #category : 'version management' }
LibPCRE2 >> versionString [
	"Answer the raw PCRE2 version string, for example '10.47 2025-10-21'."

	^ self config: PCRE2 configVersion
]

{ #category : 'accessing - platform' }
LibPCRE2 >> win32LibraryName [

	^ FFIWindowsLibraryFinder findLibrary:
		  self class libraryBasename , '.dll'
]
