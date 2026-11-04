Extension { #name : 'PCRE2Matcher' }

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> decodeSubstitutionOutput: buffer codeUnits: codeUnitCount [

	self subclassResponsibility
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject with: replacement [
	"Answer subject with its first match replaced. replacement follows the PCRE2 replacement syntax unless the matcher options include substituteLiteral."

	^ self substitute: subject with: replacement options: self substitutionOptions
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject with: replacement addingOptions: substituteOptions [

	^ self substitute: subject with: replacement options: (self substitutionOptions bitOr: substituteOptions)
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject with: replacement calloutsDo: calloutBlock [

	^ self
		  substitute: subject
		  with: replacement
		  options: self substitutionOptions
		  calloutsDo: calloutBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject with: replacement caseCallout: caseBlock [

	^ self
		  substitute: subject
		  with: replacement
		  options: self substitutionOptions
		  caseCallout: caseBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject with: replacement options: substituteOptions [
	"substituteOptions replace the matcher options. The implementation may add substituteOverflowLength to size the output buffer."

	^ self
		  substitute: subject
		  with: replacement
		  options: substituteOptions
		  matchData: nil
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject with: replacement options: substituteOptions calloutsDo: calloutBlock [
	"calloutBlock runs after each replacement is processed."

	^ self
		  withSubstituteCallout: calloutBlock
		  do: [ :callbackMatcher | callbackMatcher substitute: subject with: replacement options: substituteOptions ]
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject with: replacement options: substituteOptions caseCallout: caseBlock [
	"caseBlock transforms the text of the case escapes, which need substituteExtended."

	^ self
		  withSubstituteCaseCallout: caseBlock
		  do: [ :callbackMatcher | callbackMatcher substitute: subject with: replacement options: substituteOptions ]
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject with: replacement options: substituteOptions matchData: aPCRE2Match [
	"aPCRE2Match is the match data to pass to pcre2_substitute, or nil."

	| input |
	input := self preparedInputFor: subject.
	^ self
		  substituteBytes: input bytes
		  replacement: replacement
		  options: substituteOptions
		  matchData: aPCRE2Match
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject withLiteral: replacement [

	^ self substitute: subject with: replacement addingOptions: PCRE2 substituteLiteral
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject withUnknownCapturesEmpty: replacement [
	"Unknown and unset groups become empty, so a misspelled group name in replacement no longer signals an error."

	^ self substitute: subject with: replacement addingOptions: PCRE2 substituteUnknownUnset | PCRE2 substituteUnsetEmpty
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject withUnsetCapturesEmpty: replacement [

	^ self substitute: subject with: replacement addingOptions: PCRE2 substituteUnsetEmpty
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteAll: subject with: replacement [

	^ self substitute: subject with: replacement addingOptions: PCRE2 substituteGlobal
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteAll: subject with: replacement calloutsDo: calloutBlock [

	^ self
		  substitute: subject
		  with: replacement
		  options: self substitutionOptions | PCRE2 substituteGlobal
		  calloutsDo: calloutBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteAll: subject with: replacement caseCallout: caseBlock [

	^ self
		  substitute: subject
		  with: replacement
		  options: self substitutionOptions | PCRE2 substituteGlobal
		  caseCallout: caseBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteAll: subject with: replacement options: substituteOptions caseCallout: caseBlock [

	^ self
		  substitute: subject
		  with: replacement
		  options: substituteOptions | PCRE2 substituteGlobal
		  caseCallout: caseBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteAll: subject withLiteral: replacement [

	^ self substitute: subject with: replacement addingOptions: PCRE2 substituteGlobal | PCRE2 substituteLiteral
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteAll: subject withUnknownCapturesEmpty: replacement [
	"Unknown and unset groups become empty, so a misspelled group name in replacement no longer signals an error."

	^ self
		  substitute: subject
		  with: replacement
		  addingOptions: PCRE2 substituteGlobal | PCRE2 substituteUnknownUnset | PCRE2 substituteUnsetEmpty
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteAll: subject withUnsetCapturesEmpty: replacement [

	^ self substitute: subject with: replacement addingOptions: PCRE2 substituteGlobal | PCRE2 substituteUnsetEmpty
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteAllReplacementsOnly: subject with: replacement [
	"Answer the replacement texts alone, concatenated in match order."

	^ self substitute: subject with: replacement addingOptions: PCRE2 substituteGlobal | PCRE2 substituteReplacementOnly
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteBytes: subject replacement: replacement options: substituteOptions matchData: matchData [

	^ backend
		  prepareForMatch;
		  substituteBytes: subject
		  replacement: replacement
		  options: substituteOptions
		  matchData: (matchData ifNotNil: [ matchData backend ])
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteReplacementsOnly: subject with: replacement [

	^ self substitute: subject with: replacement addingOptions: PCRE2 substituteReplacementOnly
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement [
	"Replace the match aPCRE2Match already holds, in the subject it remembers. The match must come from this matcher."

	^ self substituteUsingMatch: aPCRE2Match with: replacement options: self substitutionOptions
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement calloutsDo: calloutBlock [

	^ self
		  substituteUsingMatch: aPCRE2Match
		  with: replacement
		  options: self substitutionOptions
		  calloutsDo: calloutBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement caseCallout: caseBlock [

	^ self
		  substituteUsingMatch: aPCRE2Match
		  with: replacement
		  options: self substitutionOptions
		  caseCallout: caseBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement options: substituteOptions [
	"PCRE2 requires aPCRE2Match to come from this pattern and subject, with compatible match options."

	self validateSubstitutionMatchData: aPCRE2Match.
	^ self
		  substituteBytes: aPCRE2Match subject
		  replacement: replacement
		  options: substituteOptions | PCRE2 substituteMatched
		  matchData: aPCRE2Match
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement options: substituteOptions calloutsDo: calloutBlock [
	"The callout is set on the receiver rather than on a temporary matcher, because PCRE2_SUBSTITUTE_MATCHED needs the compiled pattern that produced the match."

	self context substituteCalloutBlock: calloutBlock.
	^ [ self substituteUsingMatch: aPCRE2Match with: replacement options: substituteOptions ] ensure: [
		  self context clearSubstituteCallout ]
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement options: substituteOptions caseCallout: caseBlock [
	"The callout is set on the receiver rather than on a temporary matcher, because PCRE2_SUBSTITUTE_MATCHED needs the compiled pattern that produced the match."

	self context substituteCaseCalloutBlock: caseBlock.
	^ [ self substituteUsingMatch: aPCRE2Match with: replacement options: substituteOptions ] ensure: [
		  self context clearSubstituteCaseCallout ]
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitutionOptions [
	"The matcher options without the partial matching ones, which pcre2_substitute rejects."

	^ options bitAnd: (PCRE2 partialSoft | PCRE2 partialHard) bitInvert
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> validateSubstitutionMatchData: aPCRE2Match [

	aPCRE2Match ifNil: [ PCRE2Error signal: 'Substitution match data must hold an external PCRE2 match data block' ].
	aPCRE2Match isPersistent ifTrue: [ PCRE2Error signal: 'Persistent match data cannot be passed back to pcre2_substitute' ].
	aPCRE2Match isNull ifTrue: [ PCRE2Error signal: 'Substitution match data must hold an external PCRE2 match data block' ].
	aPCRE2Match subject ifNil: [ PCRE2Error signal: 'Substitution match data must remember its subject bytes' ].
	aPCRE2Match isComplete ifFalse: [ PCRE2Error signal: 'Substitution match data must contain a complete match' ]
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> withSubstituteCallout: calloutBlock do: aBlock [
	"Evaluate aBlock with a temporary matcher that calls calloutBlock with a PCRE2SubstitutionCalloutEvent after each replacement. calloutBlock may answer a substitute-callout return code; any non-integer accepts the replacement."

	| callbackMatcher |
	callbackMatcher := self temporaryMatcherForCallout.
	callbackMatcher context substituteCalloutBlock: calloutBlock.
	^ [ aBlock cull: callbackMatcher ] ensure: [ callbackMatcher context clearSubstituteCallout ]
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> withSubstituteCaseCallout: caseBlock do: aBlock [
	"Evaluate aBlock with a temporary matcher that hands each case escape (\U, \L, \u, \l) to caseBlock as a PCRE2SubstitutionCaseCalloutEvent; caseBlock answers the transformed text."

	| callbackMatcher |
	callbackMatcher := self temporaryMatcherForCallout.
	callbackMatcher context substituteCaseCalloutBlock: caseBlock.
	^ [ aBlock cull: callbackMatcher ] ensure: [ callbackMatcher context clearSubstituteCaseCallout ]
]
