Extension { #name : 'PCRE2UTF16MatchContext' }

{ #category : '*PCRE2-FFIBackend' }
PCRE2UTF16MatchContext class >> fromHandle: address [

	^ self new backend: (PCRE2MatchContextUTF16FFIBackend fromHandle: address) initialize autoRelease
]
