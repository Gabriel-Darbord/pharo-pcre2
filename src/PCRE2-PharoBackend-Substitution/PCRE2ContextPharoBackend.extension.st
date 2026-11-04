Extension { #name : 'PCRE2ContextPharoBackend' }

{ #category : '*PCRE2-PharoBackend-Substitution' }
PCRE2ContextPharoBackend >> clearSubstituteCallout [

	substituteCalloutBlock := nil
]

{ #category : '*PCRE2-PharoBackend-Substitution' }
PCRE2ContextPharoBackend >> clearSubstituteCaseCallout [

	substituteCaseCalloutBlock := nil
]

{ #category : '*PCRE2-PharoBackend-Substitution' }
PCRE2ContextPharoBackend >> substituteCalloutBlock [

	^ substituteCalloutBlock
]

{ #category : '*PCRE2-PharoBackend-Substitution' }
PCRE2ContextPharoBackend >> substituteCalloutBlock: block [

	substituteCalloutBlock := block
]

{ #category : '*PCRE2-PharoBackend-Substitution' }
PCRE2ContextPharoBackend >> substituteCaseCalloutBlock [

	^ substituteCaseCalloutBlock
]

{ #category : '*PCRE2-PharoBackend-Substitution' }
PCRE2ContextPharoBackend >> substituteCaseCalloutBlock: block [

	substituteCaseCalloutBlock := block
]
