Extension { #name : 'PCRE2UTF32MatchContext' }

{ #category : '*PCRE2-FFIBackend' }
PCRE2UTF32MatchContext class >> fromHandle: address [

	^ self new backend: (PCRE2MatchContextUTF32FFIBackend fromHandle: address) initialize autoRelease
]
