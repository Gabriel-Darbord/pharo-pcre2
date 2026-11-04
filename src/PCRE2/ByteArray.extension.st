Extension { #name : 'ByteArray' }

{ #category : '*PCRE2' }
ByteArray >> asPCRE2UTF8Input [
	"Prepare myself as UTF-8 input for PCRE2 matching."

	^ PCRE2UTF8Input fromBytes: self
]
