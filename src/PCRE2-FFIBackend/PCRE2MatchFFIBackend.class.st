"
Owns a C match-data handle for a public PCRE2Match.
"
Class {
	#name : 'PCRE2MatchFFIBackend',
	#superclass : 'PCRE2Object',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'testing' }
PCRE2MatchFFIBackend class >> isAbstract [

	^ self == PCRE2MatchFFIBackend
]

{ #category : 'private' }
PCRE2MatchFFIBackend >> getHeapframesSize [

	self subclassResponsibility
]

{ #category : 'accessing' }
PCRE2MatchFFIBackend >> getMark [

	^ (PCRE2CalloutSite zeroTerminatedStringFrom: self getMarkPointer codeUnitWidth: self ffiLibraryName codeUnitWidth) ifNil: [ '' ]
]

{ #category : 'private' }
PCRE2MatchFFIBackend >> getMarkPointer [

	self subclassResponsibility
]

{ #category : 'private' }
PCRE2MatchFFIBackend >> getOffsets [

	self subclassResponsibility
]

{ #category : 'accessing' }
PCRE2MatchFFIBackend >> heapframesSize [

	^ self ffiLibraryName supportsMatchDataHeapframesSize
		  ifTrue: [ self getHeapframesSize ]
		  ifFalse: [ nil ]
]

{ #category : 'accessing' }
PCRE2MatchFFIBackend >> offsetsAt: pairIndex [

	| address index wordSize |
	address := self getOffsets.
	wordSize := ExternalAddress wordSize.
	index := 2 * (pairIndex - 1) * wordSize.
	wordSize = 8 ifTrue: [
			^ {
				  (address uint64AtOffset: index).
				  (address uint64AtOffset: index + 8) } ].
	wordSize = 4 ifTrue: [
			^ {
				  (address uint32AtOffset: index).
				  (address uint32AtOffset: index + 4) } ].
	^ {
		  (address platformSizeTAt: index + 1).
		  (address platformSizeTAt: index + wordSize + 1) }
]

{ #category : 'accessing' }
PCRE2MatchFFIBackend >> requiresSessionRestore [

	^ true
]
