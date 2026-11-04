"
Tracing a match: `PCRE2Matcher>>traceMatch:` runs a match with automatic callouts and answers a `PCRE2MatchTrace`, the steps of the match with the pattern and subject ranges of each. It runs on either backend, and the tools of PCRE2-Tools are built on it.
"
Class {
	#name : 'ManifestPCRE2Trace',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-Trace-Manifest',
	#package : 'PCRE2-Trace',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2Trace class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
