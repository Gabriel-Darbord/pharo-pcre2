Extension { #name : 'PCRE2UTF8MatchContext' }

{ #category : '*PCRE2-FFIBackend' }
PCRE2UTF8MatchContext class >> fromHandle: address [

	^ self new backend: (PCRE2MatchContextUTF8FFIBackend fromHandle: address) initialize autoRelease
]
