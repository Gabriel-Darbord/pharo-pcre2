Extension { #name : 'PCRE2UTF16Match' }

{ #category : '*PCRE2-FFIBackend' }
PCRE2UTF16Match class >> fromHandle: address [

	^ self new backend: (PCRE2MatchUTF16FFIBackend fromHandle: address)
]
