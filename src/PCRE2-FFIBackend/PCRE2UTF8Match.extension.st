Extension { #name : 'PCRE2UTF8Match' }

{ #category : '*PCRE2-FFIBackend' }
PCRE2UTF8Match class >> fromHandle: address [

	^ self new backend: (PCRE2MatchUTF8FFIBackend fromHandle: address)
]
