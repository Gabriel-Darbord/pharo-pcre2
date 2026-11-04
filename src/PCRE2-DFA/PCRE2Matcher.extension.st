Extension { #name : 'PCRE2Matcher' }

{ #category : '*PCRE2-DFA' }
PCRE2Matcher >> dfaMatch: subject [
	"Answer match data holding every match that starts at the first position where one does, or nil."

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

	^ self dfaMatch: subject workspaceSize: workspaceSize ovectorSize: 20
]

{ #category : '*PCRE2-DFA' }
PCRE2Matcher >> dfaMatch: subject workspaceSize: workspaceSize ovectorSize: ovectorSize [

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
	"start and end are an inclusive 1-based code-unit range of the prepared subject bytes. Answer the match data, or nil."

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
	"Fill aPCRE2Match; start and end are an inclusive 1-based code-unit range of the prepared subject bytes."

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
	"Answer the strings of every match that starts at the first position where one does, or an empty array."

	^ self dfaMatches: subject workspaceSize: 100
]

{ #category : '*PCRE2-DFA' }
PCRE2Matcher >> dfaMatches: subject workspaceSize: workspaceSize [

	^ self dfaMatches: subject workspaceSize: workspaceSize ovectorSize: 20
]

{ #category : '*PCRE2-DFA' }
PCRE2Matcher >> dfaMatches: subject workspaceSize: workspaceSize ovectorSize: ovectorSize [

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
