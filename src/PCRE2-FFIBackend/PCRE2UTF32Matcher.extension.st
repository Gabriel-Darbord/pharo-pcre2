Extension { #name : 'PCRE2UTF32Matcher' }

{ #category : '*PCRE2-FFIBackend' }
PCRE2UTF32Matcher class >> fromHandle: address [

	^ self new backend: (PCRE2MatcherUTF32FFIBackend fromHandle: address)
]
