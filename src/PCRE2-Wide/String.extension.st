Extension { #name : 'String' }

{ #category : '*PCRE2-Wide' }
String >> asPCRE2UTF16Input [
	"Prepare myself as reusable UTF-16 input for PCRE2 matching."

	^ PCRE2UTF16Input fromString: self
]

{ #category : '*PCRE2-Wide' }
String >> asPCRE2UTF32Input [
	"Prepare myself as reusable UTF-32 input for PCRE2 matching."

	^ PCRE2UTF32Input fromString: self
]
