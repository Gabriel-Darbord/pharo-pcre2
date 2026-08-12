"
Abstract superclass for PCRE2 low-character table wrappers.

PCRE2 builds these tables from the process locale with pcre2_maketables(). A compile context can use them to define locale-sensitive behavior for character codes below 256, such as \w, \d, POSIX classes, and caseless matching. Keep the wrapper alive for as long as any compiled pattern may still reference its native table pointer.

Before image shutdown, bePersistent snapshots the native table bytes. On restore, the wrapper rebuilds native memory from that snapshot so behavior does not depend on the locale of the restarted process.
"
Class {
	#name : 'PCRE2CharacterTables',
	#superclass : 'PCRE2Object',
	#instVars : [
		'persistedBytes',
		'usesPCRE2Allocator'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'testing' }
PCRE2CharacterTables class >> isAbstract [

	^ self == PCRE2CharacterTables
]

{ #category : 'constants' }
PCRE2CharacterTables class >> tableByteSize [
	"PCRE2 serializes one copy of low-character tables as 1088 bytes."

	^ 1088
]

{ #category : 'persistence' }
PCRE2CharacterTables >> bePersistent [
	"Snapshot my native table bytes so restore does not depend on the current process locale."

	self isNull ifFalse: [ persistedBytes := self copyBytesFromNativeTable ]
]

{ #category : 'documentation' }
PCRE2CharacterTables >> codeUnitWidth [
	"Answer the PCRE2 library width that allocated these tables."

	^ self ffiLibraryName codeUnitWidth
]

{ #category : 'private' }
PCRE2CharacterTables >> copyBytesFromNativeTable [
	"Answer a Pharo copy of the native low-character tables."

	| bytes |
	bytes := ByteArray new: self class tableByteSize.
	1 to: bytes size do: [ :index | bytes at: index put: (handle uint8AtOffset: index - 1) ].
	^ bytes
]

{ #category : 'private' }
PCRE2CharacterTables >> copyPersistedBytesToNativeMemory [
	"Answer native memory containing the persisted low-character table bytes. The caller owns the returned memory."

	| pointer |
	pointer := ExternalAddress allocate: persistedBytes size.
	pointer isNull ifTrue: [ PCRE2Error signal: 'Failed to obtain memory to restore character tables' ].
	1 to: persistedBytes size do: [ :index | pointer uint8AtOffset: index - 1 put: (persistedBytes at: index) ].
	^ pointer
]

{ #category : 'external resource management' }
PCRE2CharacterTables >> free [
	"Free the native character tables according to the allocator that produced them."

	self isNull ifTrue: [ ^ self ].
	usesPCRE2Allocator
		ifTrue: [ self ffiLibraryName uniqueInstance freeCharacterTables: self ]
		ifFalse: [ handle free ]
]

{ #category : 'initialization' }
PCRE2CharacterTables >> initialize [

	super initialize.
	usesPCRE2Allocator := true
]

{ #category : 'persistence' }
PCRE2CharacterTables >> restore [
	"Recreate low-character tables from persisted bytes when available, otherwise from the current process locale."

	persistedBytes
		ifNil: [
				self setHandle: self ffiLibraryName uniqueInstance makeCharacterTables.
				usesPCRE2Allocator := true ]
		ifNotNil: [
				self setHandle: self copyPersistedBytesToNativeMemory.
				usesPCRE2Allocator := false ].
	self isNull ifTrue: [ PCRE2Error signal: 'Failed to restore character tables' ]
]
