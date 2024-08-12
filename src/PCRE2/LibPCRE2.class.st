Class {
	#name : 'LibPCRE2',
	#superclass : 'FFILibrary',
	#pools : [
		'PCRE2Types'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

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

{ #category : 'persistence' }
LibPCRE2 class >> restore: codes from: bytes [

	self uniqueInstance restore: codes from: bytes
]

{ #category : 'persistence' }
LibPCRE2 class >> serialize: codes [

	^ self uniqueInstance serialize: codes
]

{ #category : 'documentation' }
LibPCRE2 >> allConfigs [
	"All configuration information about the PCRE2 library.
	Includes the obsolete PCRE2_CONFIG_STACKRECURSE at index 9 which is always 0."

	^ (0 to: 15) collect: [ :option | self config: option ]
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
	"This function makes it possible for a client program to find out which optional features are available in the version of the PCRE2 library it is using."

	"int pcre2_config(uint32_t what, void *where)"

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
	"Only useful if you know what you are doing with external addresses"

	| count codePointers |
	count := self serializedNumberOfCodes: bytes.
	count < 0 ifTrue: [ self errorCode: count ].
	codePointers := ByteArray new: count * ExternalAddress wordSize.
	count := self deserialize: bytes count: count output: codePointers.
	count < 0 ifTrue: [ self errorCode: count ].
	^ codePointers
]

{ #category : 'private' }
LibPCRE2 >> deserialize: bytes count: count output: buffer [
	"This function decodes a serialized set of compiled patterns back into a list of individual patterns.
	This is possible only on a host that is running the same version of PCRE2, with the same code unit width, and the host must also have the same endianness, pointer width and PCRE2_SIZE type."

	"int32_t pcre2_serialize_decode(pcre2_code **codes, int32_t number_of_codes, const uint8_t *bytes, pcre2_general_context *gcontext)"

	self ffiCall: #(int32 pcre2_serialize_decode_8(void *buffer, int32 count, const uint8 *bytes, nil))
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
LibPCRE2 >> restore: codes from: bytes [
	"Restore a list of compiled patterns from their serialized form"

	| count wordSize codePointers rc compiler |
	count := codes size.
	wordSize := ExternalAddress wordSize.
	codePointers := ByteArray new: count * wordSize.

	rc := self deserialize: bytes count: count output: codePointers.
	rc < 0 ifTrue: [ self errorCode: rc ].

	compiler := PCRE2Compiler new.
	1 to: count do: [ :i |
		| code |
		(code := codes at: i) setHandle:
			(codePointers pointerAtOffset: i - 1 * wordSize).
		code isJIT ifTrue: [ "recompile JIT if configured"
			compiler
				optionsJIT: code optionsJIT;
				compileJIT: code ] ]
]

{ #category : 'accessing' }
LibPCRE2 >> runner [

	^ TFProcessLocalWorker new
		  defaultWorker: TFSameThreadRunner uniqueInstance;
		  yourself
]

{ #category : 'serializing' }
LibPCRE2 >> serialize: codes [

	| codePointers buffer bufferSize rc externBytes bytes |
	bufferSize := ExternalAddress wordSize.
	codePointers := ByteArray new: codes size * bufferSize.
	1 to: codes size do: [ :i |
		codePointers
			pointerAtOffset: i - 1 * bufferSize
			put: (codes at: i) getHandle ].
	buffer := ByteArray new: bufferSize.

	"bufferSize is updated with the size of the allocated memory"
	rc := self
		      serialize: codePointers
		      count: codes size
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
LibPCRE2 >> serialize: codes count: count output: bytes size: bufferSize [
	"Encodes a list of compiled patterns into a byte stream.
	Note that this is not an abstract format like Java or .NET.
	Conversion of the byte stream back into usable compiled patterns can only happen
	on a host that is running the same version of PCRE2, with the same code unit width,
	and the host must also have the same endianness, pointer width and PCRE2_SIZE type."

	"int32_t pcre2_serialize_encode(const pcre2_code **codes, int32_t number_of_codes, uint8_t **serialized_bytes, PCRE2_SIZE *serialized_size, pcre2_general_context *gcontext)"

	self ffiCall: #(int32 pcre2_serialize_encode_8(void *codes, int32 count, uint8 *bytes, SizeTHolder *bufferSize, nil))
]

{ #category : 'private' }
LibPCRE2 >> serializeFree: bytes [

	self ffiCall: #(void pcre2_serialize_free_8(uint8 *bytes))
]

{ #category : 'private' }
LibPCRE2 >> serializedNumberOfCodes: bytes [
	"returns the number of serialized patterns in the byte stream, or one of the following negative error codes:
	PCRE2_ERROR_BADMAGIC  mismatch of id bytes in bytes
	PCRE2_ERROR_BADMODE   mismatch of variable unit size or PCRE version
	PCRE2_ERROR_NULL      the argument is NULL"

	"int32_t pcre2_serialize_get_number_of_codes(const uint8_t *bytes)"

	self ffiCall: #(int32 pcre2_serialize_get_number_of_codes_8(const uint8 *bytes))
]

{ #category : 'accessing - platform' }
LibPCRE2 >> unix32LibraryName [

	^ FFIUnix32LibraryFinder new findLibrary:
		  self class libraryBasename , '.so'
]

{ #category : 'accessing - platform' }
LibPCRE2 >> unix64LibraryName [

	^ FFIUnix64LibraryFinder new findLibrary:
		  self class libraryBasename , '.so'
]

{ #category : 'accessing - platform' }
LibPCRE2 >> unixLibraryName [

	^ self unix32LibraryName
]

{ #category : 'accessing - platform' }
LibPCRE2 >> win32LibraryName [

	^ FFIWindowsLibraryFinder new findLibrary:
		  self class libraryBasename , '.dll'
]
