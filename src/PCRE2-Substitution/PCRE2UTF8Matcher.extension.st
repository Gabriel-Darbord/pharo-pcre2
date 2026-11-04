Extension { #name : 'PCRE2UTF8Matcher' }

{ #category : '*PCRE2-Substitution' }
PCRE2UTF8Matcher >> decodeSubstitutionOutput: buffer codeUnits: codeUnitCount [
	"Decode a PCRE2-8 substitution output buffer. For this width, code units are bytes."

	codeUnitCount = 0 ifTrue: [ ^ String new ].
	^ (PCRE2UTF8Input bytes: buffer decoder: ZnUTF8Encoder default) readFrom: 1 to: codeUnitCount
]
