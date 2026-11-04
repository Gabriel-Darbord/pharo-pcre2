"
UTF-16 and UTF-32 patterns and subjects: the compilers, matchers, matches, contexts and inputs of the 16-bit and 32-bit code-unit widths, and the `String` and `ByteArray` conversions to those inputs. Both backends match them; without this package, patterns and subjects are UTF-8.
"
Class {
	#name : 'ManifestPCRE2Wide',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-Wide-Manifest',
	#package : 'PCRE2-Wide',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2Wide class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
