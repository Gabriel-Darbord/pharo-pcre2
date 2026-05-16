"
I am the abstract superclass for the native PCRE2 library bindings.

LibPCRE2UTF8 binds libpcre2-8, LibPCRE2UTF16 binds libpcre2-16, and LibPCRE2UTF32 binds libpcre2-32. This class keeps shared library discovery, version/configuration queries, serialization flow, error handling, and capability checks.

Runtime calls are made through LibPCRE2UTF8, LibPCRE2UTF16, or LibPCRE2UTF32.
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

{ #category : 'code-unit width' }
LibPCRE2 class >> codeUnitWidth [

	^ self subclassResponsibility
]

{ #category : 'code-unit width' }
LibPCRE2 class >> codeUnitWidthMask [

	^ self subclassResponsibility
]

{ #category : 'documentation' }
LibPCRE2 class >> config: option [

	^ self uniqueInstance config: option
]

{ #category : 'converting' }
LibPCRE2 class >> convertGlob: globPattern [
	"Convert a glob pattern into a PCRE2 pattern string for the receiver's code-unit width."

	^ self convertGlob: globPattern options: PCRE2 convertGlob
]

{ #category : 'converting' }
LibPCRE2 class >> convertGlob: globPattern context: convertContext [
	"Convert a glob pattern into a PCRE2 pattern string with the supplied convert context."

	^ self
		  convertGlob: globPattern
		  options: PCRE2 convertGlob
		  context: convertContext
]

{ #category : 'converting' }
LibPCRE2 class >> convertGlob: globPattern options: convertOptions [
	"Convert a glob pattern into a PCRE2 pattern string with explicit glob conversion options."

	^ self convertGlob: globPattern options: convertOptions context: nil
]

{ #category : 'converting' }
LibPCRE2 class >> convertGlob: globPattern options: convertOptions context: convertContext [
	"Convert a glob pattern into a PCRE2 pattern string for the receiver's code-unit width."

	^ self
		  convertPattern: globPattern
		  options: (convertOptions bitOr: PCRE2 convertUTF)
		  context: convertContext
]

{ #category : 'converting' }
LibPCRE2 class >> convertPOSIXBasic: posixPattern [
	"Convert a POSIX basic regular expression into a PCRE2 pattern string for the receiver's code-unit width."

	^ self
		  convertPattern: posixPattern
		  options: PCRE2 convertPOSIXBasic | PCRE2 convertUTF
]

{ #category : 'converting' }
LibPCRE2 class >> convertPOSIXBasic: posixPattern context: convertContext [
	"Convert a POSIX basic regular expression into a PCRE2 pattern string with the supplied convert context."

	^ self
		  convertPattern: posixPattern
		  options: PCRE2 convertPOSIXBasic | PCRE2 convertUTF
		  context: convertContext
]

{ #category : 'converting' }
LibPCRE2 class >> convertPOSIXExtended: posixPattern [
	"Convert a POSIX extended regular expression into a PCRE2 pattern string for the receiver's code-unit width."

	^ self
		  convertPattern: posixPattern
		  options: PCRE2 convertPOSIXExtended | PCRE2 convertUTF
]

{ #category : 'converting' }
LibPCRE2 class >> convertPOSIXExtended: posixPattern context: convertContext [
	"Convert a POSIX extended regular expression into a PCRE2 pattern string with the supplied convert context."

	^ self
		  convertPattern: posixPattern
		  options: PCRE2 convertPOSIXExtended | PCRE2 convertUTF
		  context: convertContext
]

{ #category : 'converting' }
LibPCRE2 class >> convertPattern: pattern options: convertOptions [
	"Convert a foreign pattern into a PCRE2 pattern string with explicit PCRE2_CONVERT_* option bits."

	^ self uniqueInstance
		  convertPattern: pattern
		  options: convertOptions
		  context: nil
]

{ #category : 'converting' }
LibPCRE2 class >> convertPattern: pattern options: convertOptions context: convertContext [
	"Convert a foreign pattern into a PCRE2 pattern string with an optional convert context."

	^ self uniqueInstance
		  convertPattern: pattern
		  options: convertOptions
		  context: convertContext
]

{ #category : 'persistence' }
LibPCRE2 class >> deserialize: bytes [

	^ self uniqueInstance deserialize: bytes
]

{ #category : 'testing' }
LibPCRE2 class >> isAbstract [

	^ self == LibPCRE2
]

{ #category : 'JIT' }
LibPCRE2 class >> jitFreeUnusedMemory [

	^ self uniqueInstance jitFreeUnusedMemory
]

{ #category : 'library path' }
LibPCRE2 class >> libraryBasename [

	^ self subclassResponsibility
]

{ #category : 'instance creation' }
LibPCRE2 class >> newCharacterTables [
	"Build low-character tables from the current process locale for this code-unit width."

	^ self uniqueInstance newCharacterTables
]

{ #category : 'instance creation' }
LibPCRE2 class >> newConvertContext [

	^ self uniqueInstance newConvertContext
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
LibPCRE2 class >> supports16BitCodeUnitWidth [

	^ self uniqueInstance supports16BitCodeUnitWidth
]

{ #category : 'version management' }
LibPCRE2 class >> supports32BitCodeUnitWidth [

	^ self uniqueInstance supports32BitCodeUnitWidth
]

{ #category : 'version management' }
LibPCRE2 class >> supports8BitCodeUnitWidth [

	^ self uniqueInstance supports8BitCodeUnitWidth
]

{ #category : 'version management' }
LibPCRE2 class >> supportsCodeUnitWidth [

	^ self uniqueInstance supportsCodeUnitWidth
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
LibPCRE2 class >> supportsPatternConversion [
	"PCRE2 10.30 added the experimental pattern conversion API."

	^ self uniqueInstance supportsPatternConversion
]

{ #category : 'version management' }
LibPCRE2 class >> supportsSubstitutionCallouts [
	"PCRE2 10.33 added pcre2_set_substitute_callout()."

	^ self uniqueInstance supportsSubstitutionCallouts
]

{ #category : 'version management' }
LibPCRE2 class >> supportsSubstitutionCaseCallouts [
	"PCRE2 10.45 added pcre2_set_substitute_case_callout()."

	^ self uniqueInstance supportsSubstitutionCaseCallouts
]

{ #category : 'version management' }
LibPCRE2 class >> supportsUnicode [

	^ self uniqueInstance supportsUnicode
]

{ #category : 'instance creation' }
LibPCRE2 class >> uniqueInstance [
	"LibPCRE2 is abstract. Use LibPCRE2UTF8, LibPCRE2UTF16, or LibPCRE2UTF32 for runtime calls."

	self isAbstract ifTrue: [
		PCRE2Error signal:
			'LibPCRE2 is abstract; use a concrete PCRE2 library binding' ].
	^ super uniqueInstance
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
	self supportsCodeUnitWidth ifFalse: [
		PCRE2Error signal: 'The loaded ' , self class libraryBasename
			, ' library was not compiled with ' , self codeUnitWidth asString
			, '-bit code unit support' ].
	self supportsUnicode ifFalse: [
		PCRE2Error signal:
			'The loaded PCRE2 library was not compiled with Unicode support' ].
	^ self
]

{ #category : 'private' }
LibPCRE2 >> codeUnitByteSize [
	"Answer the native byte size of one PCRE2 code unit for this library binding."

	^ self class codeUnitWidth // 8
]

{ #category : 'code-unit width' }
LibPCRE2 >> codeUnitWidth [

	^ self class codeUnitWidth
]

{ #category : 'code-unit width' }
LibPCRE2 >> codeUnitWidthMask [

	^ self class codeUnitWidthMask
]

{ #category : 'documentation' }
LibPCRE2 >> config: option [
	"Answer configuration information about the PCRE2 library.
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
	buffer := ByteArray new: 64 * self codeUnitByteSize. "PCRE2 currently reports short configuration strings; 64 code units leaves room for the terminating zero."
	rc := self config: option output: buffer. "if success, rc is the number of code units used, including the terminating zero"
	rc < 0 ifTrue: [ self errorCode: rc ].
	^ self stringFromConfigBytes: buffer codeUnits: rc - 1
]

{ #category : 'private' }
LibPCRE2 >> config: what output: where [
	"Width-specific primitive for pcre2_config_*()."

	^ self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> conversionErrorCode: errorCode in: patternBytes at: offset [
	"Signal a conversion error at the input offset reported by PCRE2."

	PCRE2CompileError
		signal: (PCRE2 translateErrorCode: errorCode)
		in: patternBytes asByteArray
		at: offset
]

{ #category : 'converting' }
LibPCRE2 >> convertPattern: pattern options: convertOptions [
	"Convert a foreign pattern into a PCRE2 pattern string using explicit PCRE2_CONVERT_* option bits."

	^ self convertPattern: pattern options: convertOptions context: nil
]

{ #category : 'converting' }
LibPCRE2 >> convertPattern: pattern options: convertOptions context: convertContext [
	"Convert a foreign pattern string into a PCRE2 pattern string and free the PCRE2-owned output buffer."

	| buffer convertedBytes input outputAddress outputLength rc |
	self requirePatternConversionSupport.
	input := self preparedConversionInputFor: pattern.
	buffer := ByteArray new: ExternalAddress wordSize.
	outputLength := SizeTHolder new.
	rc := self
		      patternConvert: input bytes
		      upTo: input size
		      options: convertOptions
		      output: buffer
		      size: outputLength
		      context: convertContext.
	outputAddress := buffer pointerAtOffset: 0.
	rc = 0 ifFalse: [
		outputAddress isNull ifFalse: [
			self convertedPatternFree: outputAddress ].
		self conversionErrorCode: rc in: input bytes at: outputLength value ].
	[
	convertedBytes := self
		                  copyExternalBytes: outputAddress
		                  size: outputLength value * self codeUnitByteSize.
	^ self
		  decodeConvertedPatternBytes: convertedBytes
		  codeUnitCount: outputLength value ] ensure: [
		self convertedPatternFree: outputAddress ]
]

{ #category : 'private' }
LibPCRE2 >> convertedPatternFree: convertedPattern [
	"Width-specific primitive for pcre2_converted_pattern_free_*()."

	^ self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> copyExternalBytes: externalBytes size: byteSize [
	"Copy byteSize bytes from a native PCRE2 buffer into a Pharo ByteArray."

	| bytes |
	bytes := ByteArray new: byteSize.
	1 to: byteSize do: [ :index |
		bytes at: index put: (externalBytes uint8AtOffset: index - 1) ].
	^ bytes
]

{ #category : 'private' }
LibPCRE2 >> createConvertContext [
	"Width-specific primitive for pcre2_convert_context_create_*()."

	^ self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> createMatchContext [
	"Width-specific primitive for pcre2_match_context_create_*()."

	^ self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> decodeConvertedPatternBytes: convertedBytes codeUnitCount: codeUnitCount [
	"Decode bytes returned by pcre2_pattern_convert_*() for this binding's code-unit width."

	^ self subclassResponsibility
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
	"Width-specific primitive for pcre2_serialize_decode_*()."

	^ self subclassResponsibility
]

{ #category : 'error handling' }
LibPCRE2 >> errorCode: errorCode [

	<debuggerCompleteToSender>
	PCRE2Error signal: (PCRE2 translateErrorCode: errorCode)
]

{ #category : 'private' }
LibPCRE2 >> freeCharacterTables: characterTables [
	"Width-specific primitive for pcre2_maketables_free_*()."

	^ self subclassResponsibility
]

{ #category : 'JIT' }
LibPCRE2 >> jitFreeUnusedMemory [
	"Width-specific primitive for pcre2_jit_free_unused_memory_*()."

	^ self subclassResponsibility
]

{ #category : 'accessing - platform' }
LibPCRE2 >> macLibraryName [
	"Can be installed with homebrew"

	^ FFIMacLibraryFinder findLibrary:
		  self class libraryBasename , '.dylib'
]

{ #category : 'private' }
LibPCRE2 >> makeCharacterTables [
	"Width-specific primitive for pcre2_maketables_*()."

	^ self subclassResponsibility
]

{ #category : 'instance creation' }
LibPCRE2 >> newCharacterTables [
	"Build low-character tables from the current process locale."

	| tables |
	tables := self makeCharacterTables.
	tables isNull ifTrue: [
		PCRE2Error signal:
			'Failed to obtain memory to create character tables' ].
	^ tables autoRelease
]

{ #category : 'instance creation' }
LibPCRE2 >> newConvertContext [
	"Create a width-specific convert context for pattern conversion."

	| context |
	self requirePatternConversionSupport.
	context := self createConvertContext.
	context isNull ifTrue: [
		PCRE2Error signal:
			'Failed to obtain memory to create convert context' ].
	^ context autoRelease
]

{ #category : 'instance creation' }
LibPCRE2 >> newMatchContext [

	| context |
	context := self createMatchContext.
	context isNull ifTrue: [
		PCRE2Error signal: 'Failed to obtain memory to create match context' ].
	^ context autoRelease
]

{ #category : 'private' }
LibPCRE2 >> patternConvert: pattern upTo: length options: convertOptions output: outputBuffer size: outputLength context: convertContext [
	"Width-specific primitive for pcre2_pattern_convert_*()."

	^ self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> preparedConversionInputFor: pattern [
	"Prepare a String or width-specific input object for pcre2_pattern_convert_*()."

	^ self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> requirePatternConversionSupport [
	"Fail before calling pattern-conversion entry points that do not exist in older runtimes."

	self supportsPatternConversion ifTrue: [ ^ self ].
	PCRE2Error signal:
		'Pattern conversion requires PCRE2 10.30 or newer; loaded '
		, self versionString
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

	| buffer bufferSize externBytes pointers rc wordSize |
	wordSize := ExternalAddress wordSize.
	pointers := ByteArray new: matchers size * wordSize.
	1 to: matchers size do: [ :index |
		pointers
			pointerAtOffset: wordSize * (index - 1)
			put: (matchers at: index) getHandle ].
	buffer := ByteArray new: wordSize.

	"bufferSize is updated with the size of the allocated memory."
	rc := self
		      serialize: pointers
		      count: matchers size
		      output: buffer
		      size: (bufferSize := SizeTHolder new).
	externBytes := buffer pointerAtOffset: 0.
	rc < 0 ifTrue: [
		externBytes isNull ifFalse: [ self serializeFree: externBytes ].
		self errorCode: rc ].

	"Copy the encoded bytes into the image and free the memory allocated by PCRE2."
	[ ^ self copyExternalBytes: externBytes size: bufferSize value ]
		ensure: [ self serializeFree: externBytes ]
]

{ #category : 'private' }
LibPCRE2 >> serialize: matchers count: count output: bytes size: bufferSize [
	"Width-specific primitive for pcre2_serialize_encode_*()."

	^ self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> serializeFree: bytes [
	"Width-specific primitive for pcre2_serialize_free_*()."

	^ self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> serializedNumberOfCodes: bytes [
	"Width-specific primitive for pcre2_serialize_get_number_of_codes_*()."

	^ self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> stringFromConfigBytes: buffer codeUnits: codeUnitCount [
	"Decode a native PCRE2 configuration string for this library width."

	| bytes |
	codeUnitCount = 0 ifTrue: [ ^ String new ].
	bytes := buffer copyFrom: 1 to: codeUnitCount * self codeUnitByteSize.
	self codeUnitWidth = 8 ifTrue: [
		^ ZnUTF8Encoder default decodeBytes: bytes ].
	self codeUnitWidth = 16 ifTrue: [
		^ (PCRE2UTF16Input fromNativeEndianBytes: bytes) decodeBytes: bytes ].
	self codeUnitWidth = 32 ifTrue: [
		^ (PCRE2UTF32Input fromNativeEndianBytes: bytes) decodeBytes: bytes ].
	PCRE2Error signal: 'Unsupported PCRE2 config string code-unit width'
]

{ #category : 'version management' }
LibPCRE2 >> supports16BitCodeUnitWidth [
	"PCRE2_CONFIG_COMPILED_WIDTHS is a bitmask; bit 1 means 16-bit support."

	^ ((self config: PCRE2 configCompiledWidths) bitAnd: 2) = 2
]

{ #category : 'version management' }
LibPCRE2 >> supports32BitCodeUnitWidth [
	"PCRE2_CONFIG_COMPILED_WIDTHS is a bitmask; bit 2 means 32-bit support."

	^ ((self config: PCRE2 configCompiledWidths) bitAnd: 4) = 4
]

{ #category : 'version management' }
LibPCRE2 >> supports8BitCodeUnitWidth [
	"PCRE2_CONFIG_COMPILED_WIDTHS is a bitmask; bit 0 means 8-bit support."

	^ ((self config: PCRE2 configCompiledWidths) bitAnd: 1) = 1
]

{ #category : 'version management' }
LibPCRE2 >> supportsCodeUnitWidth [
	"Answer whether the loaded PCRE2 runtime reports support for this binding's code-unit width."

	^ ((self config: PCRE2 configCompiledWidths) bitAnd:
		   self codeUnitWidthMask) = self codeUnitWidthMask
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
LibPCRE2 >> supportsPatternConversion [

	^ self versionAtLeastMajor: 10 minor: 30
]

{ #category : 'version management' }
LibPCRE2 >> supportsSubstitutionCallouts [

	^ self versionAtLeastMajor: 10 minor: 33
]

{ #category : 'version management' }
LibPCRE2 >> supportsSubstitutionCaseCallouts [

	^ self versionAtLeastMajor: 10 minor: 45
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
