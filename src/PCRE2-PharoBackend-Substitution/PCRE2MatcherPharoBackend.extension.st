Extension { #name : 'PCRE2MatcherPharoBackend' }

{ #category : '*PCRE2-PharoBackend-Substitution' }
PCRE2MatcherPharoBackend >> conditionalValue: reference match: match options: options [

	| number known |
	number := (reference isNotEmpty and: [ reference allSatisfy: #isDigit ]) ifTrue: [ reference asInteger ].
	known := number ifNil: [ match namedGroups includes: reference ] ifNotNil: [ number < match ovectorCount ].
	(known not and: [ (options bitAnd: PCRE2 substituteUnknownUnset) = 0 ]) ifTrue: [ PCRE2MatchError signal: 'unknown substring' ].
	^ known ifTrue: [ number ifNil: [ match groupNamed: reference ] ifNotNil: [ match groupAt: number ] ]
]

{ #category : '*PCRE2-PharoBackend-Substitution' }
PCRE2MatcherPharoBackend >> expand: expression match: match options: options [

	^ PCRE2ReplacementExpander new
		  expand: expression
		  backend: self
		  match: match
		  options: options
]

{ #category : '*PCRE2-PharoBackend-Substitution' }
PCRE2MatcherPharoBackend >> replacementValue: name match: match options: substituteOptions [

	| value number known input |
	name isEmpty ifTrue: [ PCRE2MatchError signal: 'empty replacement reference' ].
	input := match input.
	name = '&' ifTrue: [ ^ match groupAt: 0 ].
	name = '_' ifTrue: [ ^ input readFrom: 1 to: input size ].
	name = (Character value: 96) asString ifTrue: [ ^ input readFrom: 1 to: (match startOffsetAt: 1) ].
	name = '''' ifTrue: [ ^ input readFrom: (match endOffsetAt: 1) + 1 to: input size ].
	name = '+' ifTrue: [
			value := match count > 1 ifTrue: [ match groupAt: match count - 1 ].
			value ifNotNil: [ ^ value ] ].
	name = '*MARK' ifTrue: [ ^ match mark ifNil: [ '' ] ].
	(name includes: $:) ifTrue: [ PCRE2UnsupportedFeature signal: 'Conditional replacements require extended substitution support' ].
	number := (name allSatisfy: #isDigit) ifTrue: [ name asInteger ].
	known := number ifNil: [ match namedGroups includes: name ] ifNotNil: [ number < match ovectorCount ].
	(known not and: [ (substituteOptions bitAnd: PCRE2 substituteUnknownUnset) = 0 ]) ifTrue: [
		PCRE2MatchError signal: 'unknown substring' ].
	value := known ifTrue: [ number ifNil: [ match groupNamed: name ] ifNotNil: [ match groupAt: number ] ].
	value ifNotNil: [ ^ value ].
	(substituteOptions bitAnd: PCRE2 substituteUnsetEmpty) ~= 0 ifTrue: [ ^ '' ].
	PCRE2MatchError signal: 'requested value is not set'
]

{ #category : '*PCRE2-PharoBackend-Substitution' }
PCRE2MatcherPharoBackend >> substituteBytes: subject replacement: replacement options: flags matchData: data [

	| allowed matchFlags input text replacementInput expression matches replacementOnly lastEnd count stopped callback outputOffset |
	matchFlags := PCRE2 anchored | PCRE2 endAnchored | PCRE2 notBOL | PCRE2 notEOL | PCRE2 notEmpty | PCRE2 notEmptyAtStart
	              | PCRE2 noJIT | PCRE2 disableRecurseloopCheck | PCRE2 copyMatchedSubject.
	allowed := matchFlags | PCRE2 substituteGlobal | PCRE2 substituteLiteral | PCRE2 substituteUnsetEmpty
	           | PCRE2 substituteUnknownUnset | PCRE2 substituteReplacementOnly | PCRE2 substituteOverflowLength
	           | PCRE2 substituteExtended | PCRE2 substituteMatched.
	(flags bitAnd: allowed bitInvert) ~= 0 ifTrue: [ PCRE2UnsupportedFeature signal: 'Unknown substitution option bits' ].
	input := matcher preparedInputFor: subject.
	text := input readFrom: 1 to: input size.
	text isString ifFalse: [ text := text asString ].
	replacementInput := matcher preparedInputFor: replacement.
	expression := replacementInput readFrom: 1 to: replacementInput size.
	expression isString ifFalse: [ expression := expression asString ].
	matches := self substitutionMatches: input options: flags matchData: data.
	replacementOnly := (flags bitAnd: PCRE2 substituteReplacementOnly) ~= 0.
	callback := matcher context backend substituteCalloutBlock.
	lastEnd := 0.
	count := 0.
	stopped := false.
	outputOffset := 0.
	^ String streamContents: [ :stream |
			  matches do: [ :match |
					  stopped ifFalse: [
							  | start end inserted response gap |
							  start := input characterCountUpToCodeUnitOffset: (match startOffsetAt: 1).
							  end := input characterCountUpToCodeUnitOffset: (match endOffsetAt: 1).
							  start < lastEnd ifTrue: [ PCRE2MatchError signal: 'invalid substitution match offsets' ].
							  replacementOnly ifFalse: [
									  gap := text copyFrom: lastEnd + 1 to: start.
									  stream nextPutAll: gap.
									  outputOffset := outputOffset + (matcher preparedInputFor: gap) size ].
							  inserted := (flags bitAnd: PCRE2 substituteLiteral) ~= 0
								              ifTrue: [ expression ]
								              ifFalse: [ self expand: expression match: match options: flags ].
							  count := count + 1.
							  response := 0.
							  callback ifNotNil: [
									  response := callback value: (PCRE2SubstitutionCalloutEvent new
											               match: match
											               replacement: inserted
											               count: count
											               outputStart: outputOffset
											               length: (matcher preparedInputFor: inserted) size).
									  response isInteger ifFalse: [ response := 0 ] ].
							  response = 0
								  ifTrue: [
										  stream nextPutAll: inserted.
										  outputOffset := outputOffset + (matcher preparedInputFor: inserted) size.
										  lastEnd := end ]
								  ifFalse: [
										  response < 0
											  ifTrue: [
													  stopped := true.
													  lastEnd := start ]
											  ifFalse: [
													  replacementOnly ifFalse: [
															  inserted := text copyFrom: start + 1 to: end.
															  stream nextPutAll: inserted.
															  outputOffset := outputOffset + (matcher preparedInputFor: inserted) size ].
													  lastEnd := end ] ] ] ].
			  replacementOnly ifFalse: [ stream nextPutAll: (text copyFrom: lastEnd + 1 to: text size) ] ]
]

{ #category : '*PCRE2-PharoBackend-Substitution' }
PCRE2MatcherPharoBackend >> substitutionMatches: input options: flags matchData: data [

	| temporary matches first count start next rc extra |
	temporary := matcher copy.
	temporary options: (flags bitAnd:
			 PCRE2 anchored | PCRE2 endAnchored | PCRE2 notBOL | PCRE2 notEOL | PCRE2 notEmpty | PCRE2 notEmptyAtStart | PCRE2 noJIT
			 | PCRE2 disableRecurseloopCheck).
	(flags bitAnd: PCRE2 substituteMatched) = 0 ifTrue: [
			^ (flags bitAnd: PCRE2 substituteGlobal) ~= 0
				  ifTrue: [ temporary findAllMatches: input ]
				  ifFalse: [ (temporary findMatch: input) ifNil: [ #(  ) ] ifNotNil: [ :match | { match } ] ] ].
	data ifNil: [ PCRE2MatchError signal: 'match data is required' ].
	first := matcher matchClass new
		         backend: data copy;
		         input: input;
		         namedGroups: matcher namedGroups.
	count := 1.
	1 to: data getCount - 1 do: [ :index | (data offsets at: index * 2 + 2) ~= PCRE2 unsetOffset ifTrue: [ count := index + 1 ] ].
	first
		resultCode: count;
		count: count.
	(flags bitAnd: PCRE2 substituteGlobal) = 0 ifTrue: [ ^ { first } ].
	matches := OrderedCollection with: first.
	start := first endOffsetAt: 1.
	extra := (first startOffsetAt: 1) = start
		         ifTrue: [ PCRE2 notEmptyAtStart ]
		         ifFalse: [ 0 ].
	[ start <= input size ] whileTrue: [
			next := temporary newMatchData.
			rc := temporary
				      matchBytes: input bytes
				      from: start + 1
				      to: input size
				      options: temporary options | extra
				      into: next.
			rc = PCRE2 errorNoMatch
				ifTrue: [
						extra = 0 ifTrue: [ ^ matches ].
						start := input nextMatchStartOffsetAfter: start.
						extra := 0 ]
				ifFalse: [
						next input: input.
						matches add: next.
						start := next endOffsetAt: 1.
						extra := (next startOffsetAt: 1) = start
							         ifTrue: [ PCRE2 notEmptyAtStart ]
							         ifFalse: [ 0 ] ] ].
	^ matches
]

{ #category : '*PCRE2-PharoBackend-Substitution' }
PCRE2MatcherPharoBackend >> transformCase: text mode: mode [

	| block event answer unicode |
	block := matcher context backend substituteCaseCalloutBlock.
	block ifNotNil: [
			event := PCRE2SubstitutionCaseCalloutEvent new
				         inputText: text
				         length: (matcher preparedInputFor: text) size
				         capacity: (matcher preparedInputFor: text) size
				         caseType: (mode = #upper
						          ifTrue: [ PCRE2 substituteCaseUpper ]
						          ifFalse: [ PCRE2 substituteCaseLower ])
				         codeUnitWidth: self codeUnitWidth.
			answer := block value: event.
			answer ifNil: [ PCRE2MatchError signal: (PCRE2 translateErrorCode: PCRE2 errorReplaceCase) ].
			^ answer isString
				  ifTrue: [ answer ]
				  ifFalse: [ event defaultTransformedText ] ].
	unicode := (compileOptions bitAnd: PCRE2 utf | PCRE2 ucp) ~= 0.
	^ text collect: [ :character | PCRE2UnicodeData case: character upper: mode = #upper unicode: unicode ]
]
