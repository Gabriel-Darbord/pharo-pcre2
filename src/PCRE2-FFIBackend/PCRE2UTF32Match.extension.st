Extension { #name : 'PCRE2UTF32Match' }

{ #category : '*PCRE2-FFIBackend' }
PCRE2UTF32Match class >> fromHandle: address [

	^ self new backend: (PCRE2MatchUTF32FFIBackend fromHandle: address)
]
