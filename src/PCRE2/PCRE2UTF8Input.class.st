"
I represent a Smalltalk string prepared as UTF-8 input for PCRE2.
ASCII ByteStrings are already valid UTF-8, so I keep the original string as byte storage and use no decoder. Other strings are encoded through Zinc and remember the encoder for later decoding of PCRE2 byte offsets.

Users may keep one of my instances and pass it to matcher APIs when the same subject is matched repeatedly. This makes the encoding cost explicit and reusable while preserving the normal String-based API.
"
Class {
	#name : 'PCRE2UTF8Input',
	#superclass : 'Object',
	#instVars : [
		'bytes',
		'decoder'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'instance creation' }
PCRE2UTF8Input class >> bytes: bytesObject decoder: aDecoder [

	^ self new
		  bytes: bytesObject decoder: aDecoder;
		  yourself
]

{ #category : 'testing' }
PCRE2UTF8Input class >> canUseDirectly: aString [
	"Answer whether aString can be passed to PCRE2-8 as already-valid UTF-8 bytes. Only ASCII ByteStrings qualify; non-ASCII ByteStrings contain byte-sized Unicode code points, not UTF-8."

	^ aString isByteString and: [
		  (ZnUTF8Encoder default findFirstNonASCIIIn: aString startingAt: 1)
		  = 0 ]
]

{ #category : 'instance creation' }
PCRE2UTF8Input class >> fromString: aString [

	| encoder |
	(self canUseDirectly: aString) ifTrue: [
		^ self bytes: aString decoder: nil ].
	encoder := ZnUTF8Encoder default.
	^ self bytes: (encoder encodeString: aString) decoder: encoder
]

{ #category : 'converting' }
PCRE2UTF8Input >> asPCRE2UTF8Input [
	"Answer myself so matcher APIs can accept either Strings or prepared inputs."

	^ self
]

{ #category : 'accessing' }
PCRE2UTF8Input >> bytes [

	^ bytes
]

{ #category : 'initialization' }
PCRE2UTF8Input >> bytes: bytesObject decoder: aDecoder [

	bytes := bytesObject.
	decoder := aDecoder
]

{ #category : 'accessing' }
PCRE2UTF8Input >> decoder [

	^ decoder
]

{ #category : 'matching' }
PCRE2UTF8Input >> recordOn: aPCRE2Match [

	aPCRE2Match subject: bytes decoder: decoder
]

{ #category : 'accessing' }
PCRE2UTF8Input >> size [

	^ bytes size
]
