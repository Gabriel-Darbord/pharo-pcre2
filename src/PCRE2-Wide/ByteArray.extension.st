Extension { #name : 'ByteArray' }

{ #category : '*PCRE2-Wide' }
ByteArray >> asPCRE2UTF16BigEndianInput [

	^ PCRE2UTF16Input fromBigEndianBytes: self
]

{ #category : '*PCRE2-Wide' }
ByteArray >> asPCRE2UTF16Input [
	"My bytes are native-endian UTF-16."

	^ PCRE2UTF16Input fromNativeEndianBytes: self
]

{ #category : '*PCRE2-Wide' }
ByteArray >> asPCRE2UTF16InputDetectingBOM [
	"Strip a BOM when present and follow its byte order; without one, assume native endianness."

	^ PCRE2UTF16Input fromBytesDetectingBOM: self
]

{ #category : '*PCRE2-Wide' }
ByteArray >> asPCRE2UTF16InputWithBOM [
	"Require a BOM and strip it."

	^ PCRE2UTF16Input fromBytesWithBOM: self
]

{ #category : '*PCRE2-Wide' }
ByteArray >> asPCRE2UTF16LittleEndianInput [

	^ PCRE2UTF16Input fromLittleEndianBytes: self
]

{ #category : '*PCRE2-Wide' }
ByteArray >> asPCRE2UTF32BigEndianInput [

	^ PCRE2UTF32Input fromBigEndianBytes: self
]

{ #category : '*PCRE2-Wide' }
ByteArray >> asPCRE2UTF32Input [
	"My bytes are native-endian UTF-32."

	^ PCRE2UTF32Input fromNativeEndianBytes: self
]

{ #category : '*PCRE2-Wide' }
ByteArray >> asPCRE2UTF32InputDetectingBOM [
	"Strip a BOM when present and follow its byte order; without one, assume native endianness."

	^ PCRE2UTF32Input fromBytesDetectingBOM: self
]

{ #category : '*PCRE2-Wide' }
ByteArray >> asPCRE2UTF32InputWithBOM [
	"Require a BOM and strip it."

	^ PCRE2UTF32Input fromBytesWithBOM: self
]

{ #category : '*PCRE2-Wide' }
ByteArray >> asPCRE2UTF32LittleEndianInput [

	^ PCRE2UTF32Input fromLittleEndianBytes: self
]
