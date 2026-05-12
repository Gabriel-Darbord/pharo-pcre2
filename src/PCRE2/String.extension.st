Extension { #name : 'String' }

{ #category : '*PCRE2' }
String >> asPCRE2UTF8Input [
	"Prepare myself as reusable UTF-8 input for PCRE2 matching."

	^ PCRE2UTF8Input fromString: self
]

{ #category : '*PCRE2' }
String >> asPCRegex [
	"Compile myself as a perl-compatible regex matcher. May raise PCRE2CompileError."

	^ PCRE2Compiler default compile: self
]

{ #category : '*PCRE2' }
String >> asPCRegexIgnoringCase [
	"Compile myself as a perl-compatible regex matcher. May raise PCRE2CompileError."

	^ PCRE2Compiler new
		  addOptions: PCRE2 caseless;
		  compile: self
]

{ #category : '*PCRE2' }
String >> asPCRegexWithOptions: compileOptions [
	"Compile myself as a perl-compatible regex matcher. May raise PCRE2CompileError.
	Use the PCRE2Compiler API if you want to avoid default options."

	^ PCRE2Compiler new
		  addOptions: compileOptions;
		  compile: self
]
