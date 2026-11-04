Extension { #name : 'PCRE2Matcher' }

{ #category : '*PCRE2-Trace' }
PCRE2Matcher >> traceMatch: aStringOrInput [
	"Run an instrumented non-JIT match and answer a trace without mutating the receiver."

	| eventSnapshots input match patternInput resultCode traceMatcher |
	traceMatcher := self traceMatcher.
	input := self preparedInputFor: aStringOrInput.
	patternInput := self patternInput.
	eventSnapshots := OrderedCollection new.
	traceMatcher context calloutBlock: [ :event |
			eventSnapshots add: event.
			0 ].
	match := traceMatcher newMatchData.
	resultCode := traceMatcher
		              matchBytes: input bytes
		              from: 1
		              to: input size
		              into: match.
	resultCode = PCRE2 errorNoMatch
		ifTrue: [ match := nil ]
		ifFalse: [ match input: input ].
	^ PCRE2MatchTrace
		  pattern: pattern
		  patternInput: patternInput
		  subject: aStringOrInput
		  input: input
		  calloutSites: traceMatcher calloutSites
		  events: eventSnapshots asArray
		  match: match
		  resultCode: resultCode
]

{ #category : '*PCRE2-Trace' }
PCRE2Matcher >> traceMatcher [
	"Answer a temporary matcher compiled for tracing. The receiver is not mutated."

	^ self temporaryMatcherAddingCompileOptions: (PCRE2 autoCallout bitOr: PCRE2 noStartOptimize) matchOptions: PCRE2 noJIT
]
