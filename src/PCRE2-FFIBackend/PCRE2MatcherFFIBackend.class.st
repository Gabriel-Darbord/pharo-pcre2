"
Owns a C compiled-pattern handle for a public PCRE2Matcher and matches through it. Width-specific subclasses contain the UFFI entry points.
"
Class {
	#name : 'PCRE2MatcherFFIBackend',
	#superclass : 'PCRE2Object',
	#instVars : [
		'matcher',
		'options',
		'context'
	],
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'testing' }
PCRE2MatcherFFIBackend class >> isAbstract [

	^ self == PCRE2MatcherFFIBackend
]

{ #category : 'private - FFI' }
PCRE2MatcherFFIBackend >> calloutSiteFromEnumerationBlock: anExternalAddress [

	^ PCRE2CalloutSite fromEnumerationBlock: anExternalAddress codeUnitWidth: self codeUnitWidth
]

{ #category : 'private - FFI' }
PCRE2MatcherFFIBackend >> calloutSitesDo: aBlock [
	"Evaluate aBlock with each callout site of the compiled pattern, without matching."

	| callback rc |
	callback := self
		            newCallbackWithSignature: #(int (void *calloutBlock, void *userData))
		            block: [ :calloutBlock :userData |
			            aBlock value: (self calloutSiteFromEnumerationBlock: calloutBlock).
			            0 ].
	rc := self enumerateCalloutsWith: callback.
	rc < 0 ifTrue: [ self errorCode: rc ]
]

{ #category : 'private - FFI' }
PCRE2MatcherFFIBackend >> codeUnitByteSize [

	^ self codeUnitWidth // 8
]

{ #category : 'copying' }
PCRE2MatcherFFIBackend >> copyWithCharacterTables [

	| address |
	address := self privateCopyWithCharacterTables.
	address isNull ifTrue: [ PCRE2Error signal: 'Failed to obtain memory to copy matcher with character tables' ].
	^ (self class fromHandle: address) autoRelease
]

{ #category : 'private' }
PCRE2MatcherFFIBackend >> createMatchDataFromPattern [

	self subclassResponsibility
]

{ #category : 'private' }
PCRE2MatcherFFIBackend >> createMatchDataWithOvectorSize: ovectorSize [

	self subclassResponsibility
]

{ #category : 'private' }
PCRE2MatcherFFIBackend >> enumerateCalloutsWith: callback [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2MatcherFFIBackend >> errorCode: errorCode [

	<debuggerCompleteToSender>
	PCRE2MatchError signal: (PCRE2 translateErrorCode: errorCode)
]

{ #category : 'private - FFI' }
PCRE2MatcherFFIBackend >> info: option [
	"Answer information about the compiled pattern, or nil when it is unset. Valid options are the class-side PCRE2 constants starting with 'info'."

	| buffer size rc |
	size := (option == PCRE2 infoSize or: [
		         option == PCRE2 infoJITSize or: [ option == PCRE2 infoFirstBitmap or: [ option == PCRE2 infoNameTable ] ] ])
		        ifTrue: [ "size_t or pointer" ExternalAddress wordSize ]
		        ifFalse: [ "uint32" 4 ].
	buffer := ByteArray new: size.
	rc := self info: option output: buffer.
	rc < 0 ifTrue: [
			rc == PCRE2 errorUnset ifTrue: [ ^ nil ].
			super errorCode: rc "not a match error" ].

	(option == PCRE2 infoSize or: [ option == PCRE2 infoJITSize ]) ifTrue: [ "info is a size_t"
			^ size == 8
				  ifTrue: [ buffer uint64AtOffset: 0 ]
				  ifFalse: [ "size is 4 on 32-bit platforms" buffer uint32AtOffset: 0 ] ].
	(option == PCRE2 infoFirstBitmap or: [ option == PCRE2 infoNameTable ]) ifTrue: [ "a pointer to external data"
		^ (buffer allSatisfy: [ :byte | byte == 0 ]) ifFalse: [ buffer ] ].
	"info is a uint32 in all other cases"
	^ buffer uint32AtOffset: 0
]

{ #category : 'private' }
PCRE2MatcherFFIBackend >> info: what output: where [

	self subclassResponsibility
]

{ #category : 'accessing' }
PCRE2MatcherFFIBackend >> matcher: aMatcher [

	matcher := aMatcher
]

{ #category : 'private - FFI' }
PCRE2MatcherFFIBackend >> nameTableCaptureIndexAt: entryOffset in: nameTableAddress [
	"PCRE2-8 stores the capture index in the first two 8-bit code units; PCRE2-16/32 store it in the first native code unit."

	self codeUnitWidth = 8 ifTrue: [
			^ ((self nameTableCodeUnitAt: entryOffset in: nameTableAddress) bitShift: 8) bitOr:
				  (self nameTableCodeUnitAt: entryOffset + 1 in: nameTableAddress) ].
	^ self nameTableCodeUnitAt: entryOffset in: nameTableAddress
]

{ #category : 'private - FFI' }
PCRE2MatcherFFIBackend >> nameTableCodeUnitAt: codeUnitOffset in: nameTableAddress [

	self codeUnitWidth = 8 ifTrue: [ ^ nameTableAddress uint8AtOffset: codeUnitOffset ].
	self codeUnitWidth = 16 ifTrue: [ ^ nameTableAddress uint16AtOffset: codeUnitOffset * self codeUnitByteSize ].
	^ nameTableAddress uint32AtOffset: codeUnitOffset * self codeUnitByteSize
]

{ #category : 'private - FFI' }
PCRE2MatcherFFIBackend >> nameTableNameAt: entryOffset in: nameTableAddress [
	"Decode the zero-terminated group name stored after the capture index in a native name-table entry."

	self codeUnitWidth = 8 ifTrue: [
			^ (ByteArray streamContents: [ :stream |
					   | codeUnit offset |
					   offset := entryOffset + 1.
					   [
						   offset := offset + 1.
						   codeUnit := self nameTableCodeUnitAt: offset in: nameTableAddress.
						   codeUnit = 0 ] whileFalse: [ stream nextPut: codeUnit ] ]) utf8Decoded ].
	^ String streamContents: [ :stream |
			  | codeUnit offset |
			  offset := entryOffset.
			  [
				  offset := offset + 1.
				  codeUnit := self nameTableCodeUnitAt: offset in: nameTableAddress.
				  codeUnit = 0 ] whileFalse: [ stream nextPut: (Character value: codeUnit) ] ]
]

{ #category : 'accessing' }
PCRE2MatcherFFIBackend >> newMatchBackend [

	| pointer |
	pointer := self createMatchDataFromPattern.
	pointer isNull ifTrue: [ PCRE2Error signal: 'Failed to obtain memory to create match data' ].
	^ (self matchBackendClass fromHandle: pointer) autoRelease
]

{ #category : 'accessing' }
PCRE2MatcherFFIBackend >> newMatchBackendWithOvectorSize: size [

	| pointer |
	pointer := self createMatchDataWithOvectorSize: size.
	pointer isNull ifTrue: [ PCRE2Error signal: 'Failed to obtain memory to create match data' ].
	^ (self matchBackendClass fromHandle: pointer) autoRelease
]

{ #category : 'instance creation' }
PCRE2MatcherFFIBackend >> newMatchContext [

	^ self ffiLibraryName uniqueInstance newMatchContext
]

{ #category : 'copying' }
PCRE2MatcherFFIBackend >> postCopy [

	self setHandle: self privateCopy.
	self isNull ifTrue: [ PCRE2Error signal: 'Failed to obtain memory to copy matcher' ].
	self autoRelease
]

{ #category : 'private' }
PCRE2MatcherFFIBackend >> prepareForMatch [

	options := matcher options.
	context := matcher existingContext ifNotNil: [ :aContext | aContext backend ]
]

{ #category : 'private' }
PCRE2MatcherFFIBackend >> privateCopy [

	self subclassResponsibility
]

{ #category : 'private' }
PCRE2MatcherFFIBackend >> privateCopyWithCharacterTables [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2MatcherFFIBackend >> readNamedGroups [
	"Read PCRE2's native name table into a sparse Array keyed by capture group number."

	| buffer rc nameCount captureCount entrySize table |
	buffer := ByteArray new: 4.

	rc := self info: PCRE2 infoNameCount output: buffer.
	rc < 0 ifTrue: [ self errorCode: rc ].
	(nameCount := buffer uint32AtOffset: 0) = 0 ifTrue: [ ^ #(  ) ].

	rc := self info: PCRE2 infoCaptureCount output: buffer.
	rc < 0 ifTrue: [ self errorCode: rc ].
	captureCount := buffer uint32AtOffset: 0.
	table := Array new: captureCount.

	rc := self info: PCRE2 infoNameEntrySize output: buffer.
	rc < 0 ifTrue: [ self errorCode: rc ].
	entrySize := buffer uint32AtOffset: 0.

	buffer := ByteArray new: ExternalAddress wordSize.
	rc := self info: PCRE2 infoNameTable output: buffer.
	rc < 0 ifTrue: [ self errorCode: rc ].
	buffer := buffer pointerAtOffset: 0.

	1 to: nameCount do: [ :entryIndex |
			| entryOffset |
			entryOffset := entrySize * (entryIndex - 1).
			table at: (self nameTableCaptureIndexAt: entryOffset in: buffer) put: (self nameTableNameAt: entryOffset in: buffer) ].
	^ table
]

{ #category : 'private' }
PCRE2MatcherFFIBackend >> recompiledBy: compiler pattern: pattern [

	| compiled |
	compiled := compiler compileBasic: pattern.
	self finalize.
	self setHandle: compiled
]

{ #category : 'accessing' }
PCRE2MatcherFFIBackend >> requiresSessionRestore [

	^ true
]

{ #category : 'persistence' }
PCRE2MatcherFFIBackend >> restoreFrom: bytes [

	self ffiLibraryName restore: { matcher } from: bytes
]

{ #category : 'private - FFI' }
PCRE2MatcherFFIBackend >> serialize [
	"Answer the serialized compiled pattern, without JIT code. Serializing matchers of one width together with LibPCRE2 is more compact: each blob carries its own copy of the character tables."

	^ self ffiLibraryName serialize: { self }
]

{ #category : 'private' }
PCRE2MatcherFFIBackend >> substitute: subject from: start to: end options: substituteOptions matchData: aPCRE2Match replacement: replacement upTo: rLength output: buffer size: outSize [

	self subclassResponsibility
]

{ #category : 'private - FFI' }
PCRE2MatcherFFIBackend >> substituteBytes: subject replacement: replacement options: substituteOptions matchData: aPCRE2Match [
	"The holder counts code units while the buffer is sized in bytes. Case callouts can make PCRE2 underestimate the output size, hence the retry loop."

	| buffer bufferCodeUnitSize bytesPerCodeUnit effectiveOptions holder rc replacementInput subjectCodeUnitSize |
	bytesPerCodeUnit := self codeUnitByteSize.
	subjectCodeUnitSize := subject size // bytesPerCodeUnit.
	replacementInput := self preparedInputFor: replacement.
	effectiveOptions := substituteOptions bitOr: PCRE2 substituteOverflowLength.
	bufferCodeUnitSize := 4096.

	[
		holder := SizeTHolder new value: bufferCodeUnitSize.
		buffer := ByteArray new: bufferCodeUnitSize * bytesPerCodeUnit.
		rc := self
			      substitute: subject
			      from: 0
			      to: subjectCodeUnitSize
			      options: effectiveOptions
			      matchData: aPCRE2Match
			      replacement: replacementInput bytes
			      upTo: replacementInput size
			      output: buffer
			      size: holder.
		rc = PCRE2 errorNoMemory ] whileTrue: [ bufferCodeUnitSize := holder value max: bufferCodeUnitSize * 2 ].

	rc < 0 ifTrue: [ self errorCode: rc ].
	^ self decodeSubstitutionOutput: buffer codeUnits: holder value
]
