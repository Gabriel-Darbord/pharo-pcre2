Extension { #name : 'PCRE2UTF8CompileContext' }

{ #category : '*PCRE2-FFIBackend' }
PCRE2UTF8CompileContext class >> fromHandle: address [

	^ self new backend: (PCRE2CompileContextUTF8FFIBackend fromHandle: address) initialize autoRelease
]
