Extension { #name : 'PCRE2Matcher' }

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> decodeSubstitutionOutput: buffer codeUnits: codeUnitCount [

	self subclassResponsibility
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject with: replacement [
	"Answer subject with the first match substituted by replacement. PCRE2 treats replacement as a substitution expression unless substituteLiteral is set in the matcher options."

	^ self substitute: subject with: replacement options: self substitutionOptions
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject with: replacement addingOptions: substituteOptions [
	"Answer subject with substitutions applied using my substitution options plus substituteOptions."

	^ self substitute: subject with: replacement options: (self substitutionOptions bitOr: substituteOptions)
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject with: replacement calloutsDo: calloutBlock [
	"Answer subject with the first match substituted while invoking calloutBlock after the processed replacement."

	^ self
		  substitute: subject
		  with: replacement
		  options: self substitutionOptions
		  calloutsDo: calloutBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject with: replacement caseCallout: caseBlock [
	"Answer subject with the first match substituted while caseBlock handles replacement case escapes."

	^ self
		  substitute: subject
		  with: replacement
		  options: self substitutionOptions
		  caseCallout: caseBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject with: replacement options: substituteOptions [
	"Answer subject with substitutions applied using the supplied PCRE2 substitution options instead of the matcher options. PCRE2 treats replacement as a substitution expression unless PCRE2 substituteLiteral is set. The implementation may add PCRE2 substituteOverflowLength internally to size the output buffer."

	^ self
		  substitute: subject
		  with: replacement
		  options: substituteOptions
		  matchData: nil
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject with: replacement options: substituteOptions calloutsDo: calloutBlock [
	"Answer subject with substitutions applied using substituteOptions while invoking calloutBlock after each processed replacement."

	^ self
		  withSubstituteCallout: calloutBlock
		  do: [ :callbackMatcher | callbackMatcher substitute: subject with: replacement options: substituteOptions ]
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject with: replacement options: substituteOptions caseCallout: caseBlock [
	"Answer subject with substitutions applied using substituteOptions while caseBlock handles replacement case escapes. Case escapes require PCRE2 substituteExtended."

	^ self
		  withSubstituteCaseCallout: caseBlock
		  do: [ :callbackMatcher | callbackMatcher substitute: subject with: replacement options: substituteOptions ]
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject with: replacement options: substituteOptions matchData: aPCRE2Match [
	"Private helper for pcre2_substitute(). Prepare a normal subject or reuse a prepared input, then pass optional PCRE2 match data to the byte-level helper."

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
	"Answer subject with the first match substituted by replacement, treating replacement as literal text rather than a PCRE2 substitution expression."

	^ self substitute: subject with: replacement addingOptions: PCRE2 substituteLiteral
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject withUnknownCapturesEmpty: replacement [
	"Answer subject with the first match substituted by replacement, treating unknown and unset captures as empty strings. Use with care because typos in replacement group names no longer signal."

	^ self substitute: subject with: replacement addingOptions: PCRE2 substituteUnknownUnset | PCRE2 substituteUnsetEmpty
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitute: subject withUnsetCapturesEmpty: replacement [
	"Answer subject with the first match substituted by replacement, treating unset captures referenced by replacement as empty strings."

	^ self substitute: subject with: replacement addingOptions: PCRE2 substituteUnsetEmpty
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteAll: subject with: replacement [
	"Answer subject with every non-overlapping match substituted by replacement."

	^ self substitute: subject with: replacement addingOptions: PCRE2 substituteGlobal
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteAll: subject with: replacement calloutsDo: calloutBlock [
	"Answer subject with every non-overlapping match substituted while invoking calloutBlock after each processed replacement."

	^ self
		  substitute: subject
		  with: replacement
		  options: self substitutionOptions | PCRE2 substituteGlobal
		  calloutsDo: calloutBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteAll: subject with: replacement caseCallout: caseBlock [
	"Answer subject with every non-overlapping match substituted while caseBlock handles replacement case escapes."

	^ self
		  substitute: subject
		  with: replacement
		  options: self substitutionOptions | PCRE2 substituteGlobal
		  caseCallout: caseBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteAll: subject with: replacement options: substituteOptions caseCallout: caseBlock [
	"Answer subject with every non-overlapping match substituted using substituteOptions while caseBlock handles replacement case escapes."

	^ self
		  substitute: subject
		  with: replacement
		  options: substituteOptions | PCRE2 substituteGlobal
		  caseCallout: caseBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteAll: subject withLiteral: replacement [
	"Answer subject with every non-overlapping match substituted by replacement, treating replacement as literal text."

	^ self substitute: subject with: replacement addingOptions: PCRE2 substituteGlobal | PCRE2 substituteLiteral
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteAll: subject withUnknownCapturesEmpty: replacement [
	"Answer subject with every non-overlapping match substituted by replacement, treating unknown and unset captures as empty strings. Use with care because typos in replacement group names no longer signal."

	^ self
		  substitute: subject
		  with: replacement
		  addingOptions: PCRE2 substituteGlobal | PCRE2 substituteUnknownUnset | PCRE2 substituteUnsetEmpty
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteAll: subject withUnsetCapturesEmpty: replacement [
	"Answer subject with every non-overlapping match substituted by replacement, treating unset captures as empty strings."

	^ self substitute: subject with: replacement addingOptions: PCRE2 substituteGlobal | PCRE2 substituteUnsetEmpty
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteAllReplacementsOnly: subject with: replacement [
	"Answer only the replacement text generated for all non-overlapping matches, concatenated in match order."

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
	"Answer only the replacement text generated for the first match."

	^ self substitute: subject with: replacement addingOptions: PCRE2 substituteReplacementOnly
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement [
	"Answer the subject remembered by aPCRE2Match after substituting replacement for that already-computed match. The match must have been produced by this matcher over the same subject bytes."

	^ self substituteUsingMatch: aPCRE2Match with: replacement options: self substitutionOptions
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement calloutsDo: calloutBlock [
	"Answer the subject remembered by aPCRE2Match after substituting replacement for that already-computed match, while invoking calloutBlock after each processed replacement."

	^ self
		  substituteUsingMatch: aPCRE2Match
		  with: replacement
		  options: self substitutionOptions
		  calloutsDo: calloutBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement caseCallout: caseBlock [
	"Answer the subject remembered by aPCRE2Match after substituting replacement for that match, while caseBlock handles replacement case escapes."

	^ self
		  substituteUsingMatch: aPCRE2Match
		  with: replacement
		  options: self substitutionOptions
		  caseCallout: caseBlock
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement options: substituteOptions [
	"Answer the subject remembered by aPCRE2Match after substituting replacement for that already-computed match. PCRE2 requires the match data to come from this pattern, subject, and compatible match options."

	self validateSubstitutionMatchData: aPCRE2Match.
	^ self
		  substituteBytes: aPCRE2Match subject
		  replacement: replacement
		  options: substituteOptions | PCRE2 substituteMatched
		  matchData: aPCRE2Match
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement options: substituteOptions calloutsDo: calloutBlock [
	"Answer the subject remembered by aPCRE2Match after substituting replacement for that already-computed match, while invoking calloutBlock after each processed replacement. This uses the receiver directly because PCRE2_SUBSTITUTE_MATCHED requires the same native compiled-pattern handle that produced the match data."

	self context substituteCalloutBlock: calloutBlock.
	^ [ self substituteUsingMatch: aPCRE2Match with: replacement options: substituteOptions ] ensure: [
		  self context clearSubstituteCallout ]
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substituteUsingMatch: aPCRE2Match with: replacement options: substituteOptions caseCallout: caseBlock [
	"Answer the subject remembered by aPCRE2Match after substituting replacement for that match, while caseBlock handles replacement case escapes. This uses the receiver directly because PCRE2_SUBSTITUTE_MATCHED requires the same native compiled-pattern handle that produced the match data."

	self context substituteCaseCalloutBlock: caseBlock.
	^ [ self substituteUsingMatch: aPCRE2Match with: replacement options: substituteOptions ] ensure: [
		  self context clearSubstituteCaseCallout ]
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> substitutionOptions [
	"Answer matcher options that are safe to pass to pcre2_substitute_*(). Partial matching options are not valid for substitution."

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
	"Evaluate aBlock with a temporary matcher whose match context invokes calloutBlock after each processed pcre2_substitute_* replacement. The callout block receives a PCRE2SubstitutionCalloutEvent and may answer a PCRE2 substitute-callout return code; non-integer answers accept the replacement."

	| callbackMatcher |
	callbackMatcher := self temporaryMatcherForCallout.
	callbackMatcher context substituteCalloutBlock: calloutBlock.
	^ [ aBlock cull: callbackMatcher ] ensure: [ callbackMatcher context clearSubstituteCallout ]
]

{ #category : '*PCRE2-Substitution' }
PCRE2Matcher >> withSubstituteCaseCallout: caseBlock do: aBlock [
	"Evaluate aBlock with a temporary matcher whose match context lets caseBlock transform replacement case escapes such as \U, \L, \u, and \l. The case block receives a PCRE2SubstitutionCaseCalloutEvent and should answer transformed text."

	| callbackMatcher |
	callbackMatcher := self temporaryMatcherForCallout.
	callbackMatcher context substituteCaseCalloutBlock: caseBlock.
	^ [ aBlock cull: callbackMatcher ] ensure: [ callbackMatcher context clearSubstituteCaseCallout ]
]
