Extension { #name : 'PCRE2Matcher' }

{ #category : '*PCRE2-DFA' }
PCRE2Matcher >> dfaMatch: subject [
	"Run a DFA match and answer all same-start alternatives as standalone match data."

	^ self dfaMatch: subject workspaceSize: 100
]

{ #category : '*PCRE2-DFA' }
PCRE2Matcher >> dfaMatch: subject from: start to: end matchData: matchData workspace: workspace size: workspaceSize [

	matchData invalidateResult.
	^ backend
		  prepareForMatch;
		  dfaMatch: subject
		  from: start
		  to: end
		  matchData: matchData backend
		  workspace: workspace
		  size: workspaceSize
]

{ #category : '*PCRE2-DFA' }
PCRE2Matcher >> dfaMatch: subject workspaceSize: workspaceSize [
	"Run a DFA match with caller-controlled workspace storage."

	^ self dfaMatch: subject workspaceSize: workspaceSize ovectorSize: 20
]

{ #category : '*PCRE2-DFA' }
PCRE2Matcher >> dfaMatch: subject workspaceSize: workspaceSize ovectorSize: ovectorSize [
	"Run a DFA match with explicit workspace and ovector sizes."

	| input match |
	input := self preparedInputFor: subject.
	match := self
		         dfaMatchBytes: input bytes
		         from: 1
		         to: input size
		         workspaceSize: workspaceSize
		         ovectorSize: ovectorSize.
	match ifNotNil: [ match input: input ].
	^ match
]

{ #category : '*PCRE2-DFA' }
PCRE2Matcher >> dfaMatchBytes: subject from: start to: end workspaceSize: workspaceSize ovectorSize: ovectorSize [
	"Run a DFA match over prepared subject byte storage using an inclusive 1-based PCRE2 code-unit range; answer standalone match data, or nil."

	| match rc |
	match := self newMatchDataWithOvectorSize: ovectorSize.
	rc := self
		      dfaMatchBytes: subject
		      from: start
		      to: end
		      workspaceSize: workspaceSize
		      ovectorSize: ovectorSize
		      into: match.
	rc == PCRE2 errorNoMatch ifTrue: [ ^ nil ].
	match subject: subject decoder: nil.
	^ match
]

{ #category : '*PCRE2-DFA' }
PCRE2Matcher >> dfaMatchBytes: subject from: start to: end workspaceSize: workspaceSize ovectorSize: ovectorSize into: aPCRE2Match [
	"Run a DFA match over prepared subject byte storage using an inclusive 1-based PCRE2 code-unit range, and populate caller-provided match data."

	| rc workspace |
	self validateDFAWorkspaceSize: workspaceSize ovectorSize: ovectorSize.
	self validateUsableMatchData: aPCRE2Match.
	aPCRE2Match reset.
	workspace := ByteArray new: workspaceSize * 4.
	rc := self
		      dfaMatch: subject
		      from: start - 1
		      to: end
		      matchData: aPCRE2Match
		      workspace: workspace
		      size: workspaceSize.
	^ self recordDFAMatchResult: rc in: aPCRE2Match
]

{ #category : '*PCRE2-DFA' }
PCRE2Matcher >> dfaMatches: subject [
	"Return all same-start DFA alternatives decoded back to Pharo strings."

	^ self dfaMatches: subject workspaceSize: 100
]

{ #category : '*PCRE2-DFA' }
PCRE2Matcher >> dfaMatches: subject workspaceSize: workspaceSize [
	"Return all same-start DFA alternatives decoded back to Pharo strings."

	^ self dfaMatches: subject workspaceSize: workspaceSize ovectorSize: 20
]

{ #category : '*PCRE2-DFA' }
PCRE2Matcher >> dfaMatches: subject workspaceSize: workspaceSize ovectorSize: ovectorSize [
	"Return all same-start DFA alternatives decoded back to Pharo strings."

	^ (self dfaMatch: subject workspaceSize: workspaceSize ovectorSize: ovectorSize)
		  ifNil: [ #(  ) ]
		  ifNotNil: [ :match | match readMatches ]
]

{ #category : '*PCRE2-DFA' }
PCRE2Matcher >> recordDFAMatchResult: rc in: aPCRE2Match [

	aPCRE2Match resultCode: rc.
	rc > 0 ifTrue: [
			aPCRE2Match count: rc.
			^ rc ].

	rc == PCRE2 errorPartial ifTrue: [
			aPCRE2Match count: 1.
			^ rc ].

	aPCRE2Match count: 0.
	rc == PCRE2 errorNoMatch ifTrue: [ ^ rc ].

	rc == 0 ifTrue: [ PCRE2Error signal: 'Not enough match data ovector slots to store DFA results' ].

	self errorCode: rc
]

{ #category : '*PCRE2-DFA' }
PCRE2Matcher >> validateDFAWorkspaceSize: workspaceSize ovectorSize: ovectorSize [

	(workspaceSize isInteger and: [ workspaceSize >= 20 ]) ifFalse: [
		self error: 'DFA workspace size must be an integer greater than or equal to 20' ].
	(ovectorSize isInteger and: [ ovectorSize >= 1 ]) ifFalse: [ self error: 'DFA ovector size must be a positive integer' ]
]
