"
Match-data implementation for the Pharo backend. It holds the offsets vector, the last mark and the start index as ordinary image objects, and reports its sizes in terms of that representation rather than of C allocations.
"
Class {
	#name : 'PCRE2MatchPharoBackend',
	#superclass : 'Object',
	#instVars : [
		'offsets',
		'startIndex',
		'mark',
		'codeUnitWidth'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> autoRelease [

	^ self
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> codeUnitWidth [

	^ codeUnitWidth
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> codeUnitWidth: anInteger [

	codeUnitWidth := anInteger
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> family [

	^ #pharo
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> finalize [

	^ self
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> free [

	^ self
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> getCount [

	^ offsets size // 2
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> getMark [

	^ mark ifNil: [ '' ]
]

{ #category : 'diagnostics' }
PCRE2MatchPharoBackend >> getMatchDataSize [

	^ self sizeInMemory + offsets sizeInMemory
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> getStartIndex [

	^ startIndex
]

{ #category : 'diagnostics' }
PCRE2MatchPharoBackend >> heapframesSize [

	^ 0
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> isNull [

	^ false
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> mark [

	^ mark
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> mark: aString [

	mark := aString
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> offsets [

	^ offsets
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> offsets: anArray [

	offsets := anArray
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> offsetsAt: pairIndex [

	^ {
		  (offsets at: pairIndex * 2 - 1).
		  (offsets at: pairIndex * 2) }
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> requiresSessionRestore [

	^ false
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> startIndex [

	^ startIndex
]

{ #category : 'accessing' }
PCRE2MatchPharoBackend >> startIndex: anInteger [

	startIndex := anInteger
]
