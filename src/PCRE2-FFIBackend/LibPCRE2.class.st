"
Abstract superclass of the bindings to the PCRE2 C library: LibPCRE2UTF8, LibPCRE2UTF16 and LibPCRE2UTF32 bind libpcre2-8, -16 and -32. It holds library discovery, version and configuration queries, serialization, pattern conversion and capability checks.
"
Class {
	#name : 'LibPCRE2',
	#superclass : 'FFILibrary',
	#pools : [
		'PCRE2Types'
	],
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'version management' }
LibPCRE2 class >> assertCompatibleLibrary [

	^ self uniqueInstance assertCompatibleLibrary
]

{ #category : 'code-unit width' }
LibPCRE2 class >> codeUnitWidth [

	self subclassResponsibility
]

{ #category : 'code-unit width' }
LibPCRE2 class >> codeUnitWidthMask [

	self subclassResponsibility
]

{ #category : 'documentation' }
LibPCRE2 class >> config: option [

	^ self runtimeConfigurationLibrary uniqueInstance config: option
]

{ #category : 'converting' }
LibPCRE2 class >> convertGlob: globPattern [

	^ self convertGlob: globPattern options: PCRE2 convertGlob
]

{ #category : 'converting' }
LibPCRE2 class >> convertGlob: globPattern context: convertContext [

	^ self convertGlob: globPattern options: PCRE2 convertGlob context: convertContext
]

{ #category : 'converting' }
LibPCRE2 class >> convertGlob: globPattern options: convertOptions [

	^ self convertGlob: globPattern options: convertOptions context: nil
]

{ #category : 'converting' }
LibPCRE2 class >> convertGlob: globPattern options: convertOptions context: convertContext [

	^ self convertPattern: globPattern options: (convertOptions bitOr: PCRE2 convertUTF) context: convertContext
]

{ #category : 'converting' }
LibPCRE2 class >> convertPOSIXBasic: posixPattern [

	^ self convertPattern: posixPattern options: PCRE2 convertPOSIXBasic | PCRE2 convertUTF
]

{ #category : 'converting' }
LibPCRE2 class >> convertPOSIXBasic: posixPattern context: convertContext [

	^ self convertPattern: posixPattern options: PCRE2 convertPOSIXBasic | PCRE2 convertUTF context: convertContext
]

{ #category : 'converting' }
LibPCRE2 class >> convertPOSIXExtended: posixPattern [

	^ self convertPattern: posixPattern options: PCRE2 convertPOSIXExtended | PCRE2 convertUTF
]

{ #category : 'converting' }
LibPCRE2 class >> convertPOSIXExtended: posixPattern context: convertContext [

	^ self convertPattern: posixPattern options: PCRE2 convertPOSIXExtended | PCRE2 convertUTF context: convertContext
]

{ #category : 'converting' }
LibPCRE2 class >> convertPattern: pattern options: convertOptions [

	^ self uniqueInstance convertPattern: pattern options: convertOptions context: nil
]

{ #category : 'converting' }
LibPCRE2 class >> convertPattern: pattern options: convertOptions context: convertContext [

	^ self uniqueInstance convertPattern: pattern options: convertOptions context: convertContext
]

{ #category : 'persistence' }
LibPCRE2 class >> deserialize: bytes [

	^ self uniqueInstance deserialize: bytes
]

{ #category : 'testing' }
LibPCRE2 class >> isAbstract [

	^ self == LibPCRE2
]

{ #category : 'testing' }
LibPCRE2 class >> isNativeLibraryAvailable [

	^ self uniqueInstance nativeLibraryPath isNotNil
]

{ #category : 'JIT' }
LibPCRE2 class >> jitFreeUnusedMemory [

	^ self uniqueInstance jitFreeUnusedMemory
]

{ #category : 'library path' }
LibPCRE2 class >> libraryBasename [

	self subclassResponsibility
]

{ #category : 'instance creation' }
LibPCRE2 class >> newCharacterTables [
	"Build low-character tables from the current process locale."

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
	"This binding targets PCRE2 10.x; another major version needs review before use."

	^ 10
]

{ #category : 'persistence' }
LibPCRE2 class >> restore: matchers from: bytes [

	self uniqueInstance restore: matchers from: bytes
]

{ #category : 'private' }
LibPCRE2 class >> runtimeConfigurationLibrary [
	"Library-wide configuration and version queries go through the 8-bit library, which is always required."

	^ LibPCRE2UTF8
]

{ #category : 'persistence' }
LibPCRE2 class >> serialize: matchers [

	^ self uniqueInstance serialize: matchers
]

{ #category : 'version management' }
LibPCRE2 class >> supports16BitCodeUnitWidth [

	^ self runtimeConfigurationLibrary uniqueInstance supports16BitCodeUnitWidth
]

{ #category : 'version management' }
LibPCRE2 class >> supports32BitCodeUnitWidth [

	^ self runtimeConfigurationLibrary uniqueInstance supports32BitCodeUnitWidth
]

{ #category : 'version management' }
LibPCRE2 class >> supports8BitCodeUnitWidth [

	^ self runtimeConfigurationLibrary uniqueInstance supports8BitCodeUnitWidth
]

{ #category : 'version management' }
LibPCRE2 class >> supportsCodeUnitWidth [

	^ self uniqueInstance supportsCodeUnitWidth
]

{ #category : 'version management' }
LibPCRE2 class >> supportsJIT [

	^ self runtimeConfigurationLibrary uniqueInstance supportsJIT
]

{ #category : 'version management' }
LibPCRE2 class >> supportsMatchDataHeapframesSize [
	"PCRE2 10.43 added pcre2_get_match_data_heapframes_size()."

	^ self runtimeConfigurationLibrary uniqueInstance supportsMatchDataHeapframesSize
]

{ #category : 'version management' }
LibPCRE2 class >> supportsMaxPatternCompiledLength [
	"PCRE2 10.44 added pcre2_set_max_pattern_compiled_length()."

	^ self runtimeConfigurationLibrary uniqueInstance supportsMaxPatternCompiledLength
]

{ #category : 'version management' }
LibPCRE2 class >> supportsMaxVarLookbehind [
	"PCRE2 10.43 added bounded variable-length lookbehind support and its compile-context limit."

	^ self runtimeConfigurationLibrary uniqueInstance supportsMaxVarLookbehind
]

{ #category : 'version management' }
LibPCRE2 class >> supportsOptimizationDirectives [
	"PCRE2 10.45 added pcre2_set_optimize()."

	^ self runtimeConfigurationLibrary uniqueInstance supportsOptimizationDirectives
]

{ #category : 'version management' }
LibPCRE2 class >> supportsPatternConversion [
	"PCRE2 10.30 added the experimental pattern conversion API."

	^ self runtimeConfigurationLibrary uniqueInstance supportsPatternConversion
]

{ #category : 'version management' }
LibPCRE2 class >> supportsSubstitutionCallouts [
	"PCRE2 10.33 added pcre2_set_substitute_callout()."

	^ self runtimeConfigurationLibrary uniqueInstance supportsSubstitutionCallouts
]

{ #category : 'version management' }
LibPCRE2 class >> supportsSubstitutionCaseCallouts [
	"PCRE2 10.45 added pcre2_set_substitute_case_callout()."

	^ self runtimeConfigurationLibrary uniqueInstance supportsSubstitutionCaseCallouts
]

{ #category : 'version management' }
LibPCRE2 class >> supportsUnicode [

	^ self runtimeConfigurationLibrary uniqueInstance supportsUnicode
]

{ #category : 'instance creation' }
LibPCRE2 class >> uniqueInstance [

	self isAbstract ifTrue: [ PCRE2Error signal: 'LibPCRE2 is abstract; use a concrete PCRE2 library binding' ].
	^ super uniqueInstance
]

{ #category : 'version management' }
LibPCRE2 class >> version [

	^ self runtimeConfigurationLibrary uniqueInstance version
]

{ #category : 'version management' }
LibPCRE2 class >> versionDate [

	^ self runtimeConfigurationLibrary uniqueInstance versionDate
]

{ #category : 'version management' }
LibPCRE2 class >> versionMajor [

	^ self runtimeConfigurationLibrary uniqueInstance versionMajor
]

{ #category : 'version management' }
LibPCRE2 class >> versionMinor [

	^ self runtimeConfigurationLibrary uniqueInstance versionMinor
]

{ #category : 'version management' }
LibPCRE2 class >> versionString [

	^ self runtimeConfigurationLibrary uniqueInstance versionString
]

{ #category : 'documentation' }
LibPCRE2 >> allConfigs [
	"The obsolete PCRE2_CONFIG_STACKRECURSE, at index 9, is always 0."

	^ (0 to: 15) collect: [ :option | self config: option ]
]

{ #category : 'version management' }
LibPCRE2 >> assertCompatibleLibrary [
	"Fail unless the loaded library is PCRE2 10.x, with Unicode support and this code-unit width."

	self versionMajor = self class requiredMajorVersion ifFalse: [
			PCRE2Error signal: (String streamContents: [ :stream |
						 stream
							 nextPutAll: 'Unsupported PCRE2 major version ';
							 print: self versionMajor;
							 nextPutAll: ' from ';
							 nextPutAll: self versionString;
							 nextPutAll: '. This binding targets PCRE2 ';
							 print: self class requiredMajorVersion;
							 nextPutAll: '.x' ]) ].
	self supportsCodeUnitWidth ifFalse: [
			PCRE2Error signal: (String streamContents: [ :stream |
						 stream
							 nextPutAll: 'The loaded ';
							 nextPutAll: self class libraryBasename;
							 nextPutAll: ' library was not compiled with ';
							 print: self codeUnitWidth;
							 nextPutAll: '-bit code unit support' ]) ].
	self supportsUnicode ifFalse: [ PCRE2Error signal: 'The loaded PCRE2 library was not compiled with Unicode support' ]
]

{ #category : 'private' }
LibPCRE2 >> characterTablesClass [

	self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> codeUnitByteSize [

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
	"Valid options are the class-side PCRE2 constants starting with 'config'."

	| buffer rc |
	(option = PCRE2 configJITTarget or: [ option = PCRE2 configUnicodeVersion or: [ option = PCRE2 configVersion ] ]) ifFalse: [ "requesting a number"
			buffer := UInt32Holder new.
			rc := self config: option output: buffer.
			rc < 0 ifTrue: [ self errorCode: rc ].
			^ buffer value ].

	"requesting a string"
	buffer := ByteArray new: 64 * self codeUnitByteSize. "PCRE2 configuration strings are short; 64 code units leave room for the terminating zero."
	rc := self config: option output: buffer. "if success, rc is the number of code units used, including the terminating zero"
	rc < 0 ifTrue: [ self errorCode: rc ].
	^ self stringFromConfigBytes: buffer codeUnits: rc - 1
]

{ #category : 'private' }
LibPCRE2 >> config: what output: where [

	self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> conversionErrorCode: errorCode in: input at: codeUnitOffset [
	"codeUnitOffset is zero-based."

	PCRE2CompileError signal: (PCRE2 translateErrorCode: errorCode) in: input at: codeUnitOffset
]

{ #category : 'private' }
LibPCRE2 >> convertContextClass [

	self subclassResponsibility
]

{ #category : 'converting' }
LibPCRE2 >> convertPattern: pattern options: convertOptions [

	^ self convertPattern: pattern options: convertOptions context: nil
]

{ #category : 'converting' }
LibPCRE2 >> convertPattern: pattern options: convertOptions context: convertContext [
	"Answer pattern converted to PCRE2 syntax. convertOptions are PCRE2_CONVERT_* bits and convertContext may be nil."

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
			outputAddress isNull ifFalse: [ self convertedPatternFree: outputAddress ].
			self conversionErrorCode: rc in: input at: outputLength value ].
	^ [
		  convertedBytes := self copyExternalBytes: outputAddress size: outputLength value * self codeUnitByteSize.
		  self decodeConvertedPatternBytes: convertedBytes codeUnitCount: outputLength value ] ensure: [
		  self convertedPatternFree: outputAddress ]
]

{ #category : 'private' }
LibPCRE2 >> convertedPatternFree: convertedPattern [

	self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> copyExternalBytes: externalBytes size: byteSize [

	| bytes |
	bytes := ByteArray new: byteSize.
	1 to: byteSize do: [ :index | bytes at: index put: (externalBytes uint8AtOffset: index - 1) ].
	^ bytes
]

{ #category : 'private' }
LibPCRE2 >> createConvertContext [

	self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> createMatchContext [

	self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> decodeConvertedPatternBytes: convertedBytes codeUnitCount: codeUnitCount [

	self subclassResponsibility
]

{ #category : 'serializing' }
LibPCRE2 >> deserialize: bytes [
	"Answer a ByteArray holding a native pointer to each deserialized compiled pattern. The caller owns the patterns."

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

	self subclassResponsibility
]

{ #category : 'error handling' }
LibPCRE2 >> errorCode: errorCode [

	<debuggerCompleteToSender>
	PCRE2Error signal: (PCRE2 translateErrorCode: errorCode)
]

{ #category : 'private' }
LibPCRE2 >> freeCharacterTables: characterTables [

	self subclassResponsibility
]

{ #category : 'JIT' }
LibPCRE2 >> jitFreeUnusedMemory [

	self subclassResponsibility
]

{ #category : 'accessing - platform' }
LibPCRE2 >> macLibraryName [
	"Can be installed with homebrew"

	^ FFIMacLibraryFinder findLibrary: self class libraryBasename , '.dylib'
]

{ #category : 'private' }
LibPCRE2 >> makeCharacterTables [

	self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> matchContextClass [

	self subclassResponsibility
]

{ #category : 'library path' }
LibPCRE2 >> nativeLibraryFilename [

	| platform |
	platform := OSPlatform current.
	platform isMacOS ifTrue: [ ^ self class libraryBasename , '.dylib' ].
	platform isUnix ifTrue: [ ^ self class libraryBasename , '.so' ].
	platform isWindows ifTrue: [ ^ self class libraryBasename , '.dll' ]
]

{ #category : 'library path' }
LibPCRE2 >> nativeLibraryFinder [

	| platform |
	platform := OSPlatform current.
	platform isMacOS ifTrue: [ ^ FFIMacLibraryFinder new ].
	platform isUnix64 ifTrue: [ ^ FFIUnix64LibraryFinder new ].
	platform isUnix32 ifTrue: [ ^ FFIUnix32LibraryFinder new ].
	platform isWindows ifTrue: [ ^ FFIWindowsLibraryFinder new ]
]

{ #category : 'library path' }
LibPCRE2 >> nativeLibraryPath [

	| filename finder |
	filename := self nativeLibraryFilename.
	filename ifNil: [ ^ nil ].
	finder := self nativeLibraryFinder.
	finder ifNil: [ ^ nil ].
	^ finder paths detect: [ :directory | (directory / filename) exists ] ifNone: [ nil ]
]

{ #category : 'instance creation' }
LibPCRE2 >> newCharacterTables [
	"Build low-character tables from the current process locale."

	| pointer |
	pointer := self makeCharacterTables.
	pointer isNull ifTrue: [ PCRE2Error signal: 'Failed to obtain memory to create character tables' ].
	^ (self characterTablesClass fromHandle: pointer) initialize autoRelease
]

{ #category : 'instance creation' }
LibPCRE2 >> newConvertContext [

	| pointer |
	self requirePatternConversionSupport.
	pointer := self createConvertContext.
	pointer isNull ifTrue: [ PCRE2Error signal: 'Failed to obtain memory to create convert context' ].
	^ (self convertContextClass fromHandle: pointer) initialize autoRelease
]

{ #category : 'instance creation' }
LibPCRE2 >> newMatchContext [

	| pointer |
	pointer := self createMatchContext.
	pointer isNull ifTrue: [ PCRE2Error signal: 'Failed to obtain memory to create match context' ].
	^ (self matchContextClass fromHandle: pointer) initialize autoRelease
]

{ #category : 'private' }
LibPCRE2 >> patternConvert: pattern upTo: length options: convertOptions output: outputBuffer size: outputLength context: convertContext [

	self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> preparedConversionInputFor: pattern [

	self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> requirePatternConversionSupport [

	self supportsPatternConversion ifTrue: [ ^ self ].
	PCRE2Error signal: 'Pattern conversion requires PCRE2 10.30 or newer; loaded ' , self versionString
]

{ #category : 'serializing' }
LibPCRE2 >> restore: matchers from: bytes [
	"Give each matcher, in order, its compiled pattern from bytes. JIT code is not serialized, so each matcher rebuilds it if needed."

	| count wordSize pointers rc |
	count := matchers size.
	wordSize := ExternalAddress wordSize.
	pointers := ByteArray new: count * wordSize.

	rc := self deserialize: bytes count: count output: pointers.
	rc < 0 ifTrue: [ self errorCode: rc ].

	1 to: count do: [ :i |
			| matcher |
			(matcher := matchers at: i) setHandle: (pointers pointerAtOffset: wordSize * (i - 1)).
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
	1 to: matchers size do: [ :index | pointers pointerAtOffset: wordSize * (index - 1) put: (matchers at: index) getHandle ].
	buffer := ByteArray new: wordSize.


	rc := self
		      serialize: pointers
		      count: matchers size
		      output: buffer
		      size: (bufferSize := SizeTHolder new).
	externBytes := buffer pointerAtOffset: 0.
	rc < 0 ifTrue: [
			externBytes isNull ifFalse: [ self serializeFree: externBytes ].
			self errorCode: rc ].


	^ [ self copyExternalBytes: externBytes size: bufferSize value ] ensure: [ self serializeFree: externBytes ]
]

{ #category : 'private' }
LibPCRE2 >> serialize: matchers count: count output: bytes size: bufferSize [

	self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> serializeFree: bytes [

	self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> serializedNumberOfCodes: bytes [

	self subclassResponsibility
]

{ #category : 'private' }
LibPCRE2 >> stringFromConfigBytes: buffer codeUnits: codeUnitCount [

	| bytes |
	codeUnitCount = 0 ifTrue: [ ^ String new ].
	bytes := buffer copyFrom: 1 to: codeUnitCount * self codeUnitByteSize.
	self codeUnitWidth = 8 ifTrue: [ ^ ZnUTF8Encoder default decodeBytes: bytes ].
	self codeUnitWidth = 16 ifTrue: [ ^ (PCRE2UTF16Input fromNativeEndianBytes: bytes) decodeBytes: bytes ].
	self codeUnitWidth = 32 ifTrue: [ ^ (PCRE2UTF32Input fromNativeEndianBytes: bytes) decodeBytes: bytes ].
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

	^ ((self config: PCRE2 configCompiledWidths) bitAnd: self codeUnitWidthMask) = self codeUnitWidthMask
]

{ #category : 'version management' }
LibPCRE2 >> supportsJIT [

	^ (self config: PCRE2 configJIT) = 1
]

{ #category : 'version management' }
LibPCRE2 >> supportsMatchDataHeapframesSize [

	^ self versionAtLeastMajor: 10 minor: 43
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

	^ FFIUnix32LibraryFinder findLibrary: self class libraryBasename , '.so'
]

{ #category : 'accessing - platform' }
LibPCRE2 >> unix64LibraryName [

	^ FFIUnix64LibraryFinder findLibrary: self class libraryBasename , '.so'
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

	^ FFIWindowsLibraryFinder findLibrary: self class libraryBasename , '.dll'
]
