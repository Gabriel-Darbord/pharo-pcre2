"
Represents raw 32-bit code units that cannot be represented by Pharo Character. Used only in non-UTF matching.
"
Class {
	#name : 'PCRE2CodeUnit',
	#superclass : 'Magnitude',
	#instVars : [
		'value'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'instance creation' }
PCRE2CodeUnit class >> fromInteger: code [

	code <= 16r10FFFF ifTrue: [ ^ Character value: code ].
	^ [ Character value: code ]
		  on: PrimitiveFailed
		  do: [ self new rawValue: code ]
]

{ #category : 'accessing' }
PCRE2CodeUnit >> < other [

	^ value < other asciiValue
]

{ #category : 'comparing' }
PCRE2CodeUnit >> = other [

	^ (other isKindOf: self class) and: [ value = other value ]
]

{ #category : 'accessing' }
PCRE2CodeUnit >> asInteger [

	^ value
]

{ #category : 'accessing' }
PCRE2CodeUnit >> asLowercase [

	^ self
]

{ #category : 'accessing' }
PCRE2CodeUnit >> asUppercase [

	^ self
]

{ #category : 'accessing' }
PCRE2CodeUnit >> asciiValue [

	^ value
]

{ #category : 'accessing' }
PCRE2CodeUnit >> digitValue [

	^ -1
]

{ #category : 'comparing' }
PCRE2CodeUnit >> hash [

	^ value hash
]

{ #category : 'accessing' }
PCRE2CodeUnit >> isAlphaNumeric [

	^ false
]

{ #category : 'accessing' }
PCRE2CodeUnit >> isDigit [

	^ false
]

{ #category : 'accessing' }
PCRE2CodeUnit >> isLetter [

	^ false
]

{ #category : 'accessing' }
PCRE2CodeUnit >> isLowercase [

	^ false
]

{ #category : 'accessing' }
PCRE2CodeUnit >> isSeparator [

	^ false
]

{ #category : 'accessing' }
PCRE2CodeUnit >> isUppercase [

	^ false
]

{ #category : 'printing' }
PCRE2CodeUnit >> printOn: stream [

	stream
		nextPutAll: '16r';
		nextPutAll: (value printStringBase: 16)
]

{ #category : 'accessing' }
PCRE2CodeUnit >> rawValue: code [

	value := code
]

{ #category : 'accessing' }
PCRE2CodeUnit >> value [

	^ value
]
