"
The backend that compiles and matches with the PCRE2 C library through UFFI. It implements the shared API at every code-unit width, with substitution and DFA matching, and the facilities only the library has: JIT compilation, locale character tables, glob and POSIX pattern conversion, and serialization of compiled patterns. It needs the library on the host.

The callback signatures are in C syntax, so `LiteralArrayContainsCommaRule` is banned for the package.
"
Class {
	#name : 'ManifestPCRE2FFIBackend',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-FFIBackend-Manifest',
	#package : 'PCRE2-FFIBackend',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2FFIBackend class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]

{ #category : 'code-critics' }
ManifestPCRE2FFIBackend class >> ruleLiteralArrayContainsCommaRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #( #( #( #RGPackageDefinition #( #'PCRE2-FFIBackend' ) ) #'2026-11-04T17:24:51.699909+01:00' ) )
]
