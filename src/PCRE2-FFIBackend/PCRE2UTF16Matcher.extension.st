Extension { #name : 'PCRE2UTF16Matcher' }

{ #category : '*PCRE2-FFIBackend' }
PCRE2UTF16Matcher class >> fromHandle: address [

	^ self new backend: (PCRE2MatcherUTF16FFIBackend fromHandle: address)
]
