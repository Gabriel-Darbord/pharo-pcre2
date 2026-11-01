Extension { #name : 'PCRE2UTF16CompileContext' }

{ #category : '*PCRE2-FFIBackend' }
PCRE2UTF16CompileContext class >> fromHandle: address [

	^ self new backend: (PCRE2CompileContextUTF16FFIBackend fromHandle: address) initialize autoRelease
]
