"
The property ranges of PCRE2UnicodeProperties, kept packed and decoded one property at a time on first read. A pattern names a handful of the 451 properties, and unpacking them all would take about half a megabyte.
"
Class {
	#name : 'PCRE2PackedProperties',
	#superclass : 'Object',
	#instVars : [
		'bytes',
		'offsets',
		'cache'
	],
	#category : 'PCRE2-UnicodeProperties',
	#package : 'PCRE2-UnicodeProperties'
}

{ #category : 'accessing' }
PCRE2PackedProperties >> at: property ifAbsent: aBlock [
	"Answer the inclusive ranges of this property, unpacking them on first use."

	^ cache at: property ifAbsentPut: [
			  | offset |
			  offset := offsets at: property ifAbsent: [ ^ aBlock value ].
			  PCRE2PackedUnicodeData readRangesFrom: (ReadStream on: bytes from: offset + 1 to: bytes size) ]
]

{ #category : 'initialization' }
PCRE2PackedProperties >> bytes: aByteArray offsets: aDictionary [

	bytes := aByteArray.
	offsets := aDictionary
]

{ #category : 'accessing' }
PCRE2PackedProperties >> includesKey: property [

	^ offsets includesKey: property
]

{ #category : 'initialization' }
PCRE2PackedProperties >> initialize [

	cache := Dictionary new
]

{ #category : 'accessing' }
PCRE2PackedProperties >> keys [

	^ offsets keys
]

{ #category : 'accessing' }
PCRE2PackedProperties >> size [

	^ offsets size
]
