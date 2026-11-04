Extension { #name : 'PCRE2MatchContext' }

{ #category : '*PCRE2-Substitution' }
PCRE2MatchContext >> clearSubstituteCallout [

	backend clearSubstituteCallout
]

{ #category : '*PCRE2-Substitution' }
PCRE2MatchContext >> clearSubstituteCaseCallout [

	backend clearSubstituteCaseCallout
]

{ #category : '*PCRE2-Substitution' }
PCRE2MatchContext >> setSubstituteCalloutCallback: callback [

	^ backend setSubstituteCalloutCallback: callback
]

{ #category : '*PCRE2-Substitution' }
PCRE2MatchContext >> setSubstituteCaseCalloutCallback: callback [

	^ backend setSubstituteCaseCalloutCallback: callback
]

{ #category : '*PCRE2-Substitution' }
PCRE2MatchContext >> substituteCalloutBlock: aBlock [

	backend substituteCalloutBlock: aBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2MatchContext >> substituteCaseCalloutBlock: aBlock [

	backend substituteCaseCalloutBlock: aBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2MatchContext >> substituteCaseCalloutResultFor: event output: outputPointer block: aBlock [

	^ backend substituteCaseCalloutResultFor: event output: outputPointer block: aBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2MatchContext >> unsetSubstituteCalloutCallback [

	^ backend unsetSubstituteCalloutCallback
]

{ #category : '*PCRE2-Substitution' }
PCRE2MatchContext >> unsetSubstituteCaseCalloutCallback [

	^ backend unsetSubstituteCaseCalloutCallback
]
