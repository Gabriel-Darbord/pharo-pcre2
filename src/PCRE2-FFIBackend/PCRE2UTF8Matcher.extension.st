Extension { #name : 'PCRE2UTF8Matcher' }

{ #category : '*PCRE2-FFIBackend' }
PCRE2UTF8Matcher class >> fromHandle: address [

	^ self new backend: (PCRE2MatcherUTF8FFIBackend fromHandle: address)
]
