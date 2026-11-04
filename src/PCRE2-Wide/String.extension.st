Extension { #name : 'String' }

{ #category : '*PCRE2-Wide' }
String >> asPCRE2UTF16Input [

	^ PCRE2UTF16Input fromString: self
]

{ #category : '*PCRE2-Wide' }
String >> asPCRE2UTF32Input [

	^ PCRE2UTF32Input fromString: self
]
