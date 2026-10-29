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

{ #category : 'backends' }
PCRE2MatchPharoBackend >> codeUnitWidth [

	^ codeUnitWidth
]

{ #category : 'backends' }
PCRE2MatchPharoBackend >> codeUnitWidth: anInteger [

	codeUnitWidth := anInteger
]

{ #category : 'backends' }
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

{ #category : 'private' }
PCRE2MatchPharoBackend >> mark [

	^ mark
]

{ #category : 'private' }
PCRE2MatchPharoBackend >> mark: aValue [

	mark := aValue
]

{ #category : 'private' }
PCRE2MatchPharoBackend >> offsets [

	^ offsets
]

{ #category : 'private' }
PCRE2MatchPharoBackend >> offsets: aValue [

	offsets := aValue
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

{ #category : 'private' }
PCRE2MatchPharoBackend >> startIndex [

	^ startIndex
]

{ #category : 'private' }
PCRE2MatchPharoBackend >> startIndex: aValue [

	startIndex := aValue
]
