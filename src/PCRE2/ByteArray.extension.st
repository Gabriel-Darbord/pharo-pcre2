Extension { #name : 'ByteArray' }

{ #category : '*PCRE2' }
ByteArray >> asPCRE2UTF16BigEndianInput [
	"Prepare myself as UTF-16 big-endian input for PCRE2 matching."

	^ PCRE2UTF16Input fromBigEndianBytes: self
]

{ #category : '*PCRE2' }
ByteArray >> asPCRE2UTF16Input [
	"Prepare myself as native-endian UTF-16 input for PCRE2 matching."

	^ PCRE2UTF16Input fromNativeEndianBytes: self
]

{ #category : '*PCRE2' }
ByteArray >> asPCRE2UTF16LittleEndianInput [
	"Prepare myself as UTF-16 little-endian input for PCRE2 matching."

	^ PCRE2UTF16Input fromLittleEndianBytes: self
]

{ #category : '*PCRE2' }
ByteArray >> asPCRE2UTF32BigEndianInput [
	"Prepare myself as UTF-32 big-endian input for PCRE2 matching."

	^ PCRE2UTF32Input fromBigEndianBytes: self
]

{ #category : '*PCRE2' }
ByteArray >> asPCRE2UTF32Input [
	"Prepare myself as native-endian UTF-32 input for PCRE2 matching."

	^ PCRE2UTF32Input fromNativeEndianBytes: self
]

{ #category : '*PCRE2' }
ByteArray >> asPCRE2UTF32LittleEndianInput [
	"Prepare myself as UTF-32 little-endian input for PCRE2 matching."

	^ PCRE2UTF32Input fromLittleEndianBytes: self
]
