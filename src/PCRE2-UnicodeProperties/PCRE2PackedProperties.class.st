"
The Unicode property ranges of PCRE2UnicodeProperties, kept packed until a pattern asks for one.

A pattern names a handful of properties, while the pinned catalog holds 451 of them, so unpacking all of them would put about half a megabyte of arrays in the image for nothing. I keep the packed bytes and the offset of each property in them, and decode a property the first time it is read.
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
