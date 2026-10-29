Class {
	#name : 'PCRE2MatcherPharoBackend',
	#superclass : 'Object',
	#instVars : [
		'matcher',
		'root',
		'captureCount',
		'names',
		'groups',
		'compileOptions'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> autoRelease [

	^ self
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> calloutSitesDo: aBlock [

	^ self
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> codeUnitWidth [

	^ matcher codeUnitWidth
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> codeUnitsFor: character [

	| code |
	code := character asInteger.
	self codeUnitWidth = 32 ifTrue: [ ^ 1 ].
	self codeUnitWidth = 16 ifTrue: [
			^ code > 65535
				  ifTrue: [ 2 ]
				  ifFalse: [ 1 ] ].
	code < 128 ifTrue: [ ^ 1 ].
	code < 2048 ifTrue: [ ^ 2 ].
	^ code < 65536
		  ifTrue: [ 3 ]
		  ifFalse: [ 4 ]
]

{ #category : 'accessing' }
PCRE2MatcherPharoBackend >> compileOptions: anInteger [

	compileOptions := anInteger
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> copyWithCharacterTables [

	^ self copy
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> dfaMatch: subject from: start to: end matchData: matchData workspace: workspace size: workspaceSize [

	PCRE2UnsupportedFeature signal: 'DFA matching is not yet implemented by the Pharo backend'
]

{ #category : 'substitution' }
PCRE2MatcherPharoBackend >> expand: expression match: match options: substituteOptions [

	| index |
	index := 1.
	^ String streamContents: [ :stream |
			  [ index <= expression size ] whileTrue: [
					  | character name start delimiter value |
					  character := expression at: index.
					  index := index + 1.
					  character = $$
						  ifFalse: [ stream nextPut: character ]
						  ifTrue: [
								  index > expression size ifTrue: [ PCRE2MatchError signal: 'invalid replacement string' ].
								  character := expression at: index.
								  index := index + 1.
								  character = $$
									  ifTrue: [ stream nextPut: $$ ]
									  ifFalse: [
											  name := nil.
											  (character = (Character value: 123) or: [ character = $< ])
												  ifTrue: [
														  delimiter := character = $<
															               ifTrue: [ $> ]
															               ifFalse: [ $} ].
														  start := index.
														  [ index <= expression size and: [ (expression at: index) ~= delimiter ] ] whileTrue: [ index := index + 1 ].
														  index > expression size ifTrue: [ PCRE2MatchError signal: 'missing replacement delimiter' ].
														  name := expression copyFrom: start to: index - 1.
														  index := index + 1 ]
												  ifFalse: [
														  (character isAlphaNumeric or: [ character = $_ ])
															  ifTrue: [
																	  start := index - 1.
																	  character = $_ ifFalse: [
																			  [
																				  index <= expression size and: [
																						  | next |
																						  next := expression at: index.
																						  character isDigit
																							  ifTrue: [ next isDigit ]
																							  ifFalse: [ next isAlphaNumeric or: [ next = $_ ] ] ] ] whileTrue: [ index := index + 1 ] ].
																	  name := expression copyFrom: start to: index - 1 ]
															  ifFalse: [ name := character asString ] ].
											  value := self replacementValue: name match: match options: substituteOptions.
											  stream nextPutAll: value ] ] ] ]
]

{ #category : 'backends' }
PCRE2MatcherPharoBackend >> family [

	^ #pharo
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> ffiLibraryName [

	PCRE2UnsupportedFeature signal: 'The Pharo backend does not use a C library'
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> finalize [

	^ self
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> free [

	^ self
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> info: option [

	option = PCRE2 infoCaptureCount ifTrue: [ ^ captureCount ].
	option = PCRE2 infoNameCount ifTrue: [ ^ names size ].
	option = PCRE2 infoAllOptions ifTrue: [ ^ compileOptions ].
	option = PCRE2 infoJITSize ifTrue: [ ^ 0 ].
	PCRE2UnsupportedFeature signal: 'This pattern diagnostic is specific to the FFI backend'
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> isNull [

	^ false
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> match: bytes from: start to: length options: matchOptions matchData: matchData [

	| decoded text mapping initial engine state result anchored lastIndex converted rc allowed offsetLimit |
	allowed := PCRE2 anchored | PCRE2 endAnchored | PCRE2 notBOL | PCRE2 notEOL | PCRE2 notEmpty | PCRE2 notEmptyAtStart
	           | PCRE2 noJIT | PCRE2 copyMatchedSubject.
	(matchOptions bitAnd: allowed bitInvert) ~= 0 ifTrue: [
		PCRE2UnsupportedFeature signal: 'Match options are not yet implemented by the Pharo backend' ].
	decoded := self textAndOffsetsFor: bytes length: length.
	text := decoded first.
	mapping := decoded second.
	initial := (mapping indexOf: start ifAbsent: [ PCRE2MatchError signal: 'bad UTF offset' ]) - 1.
	engine := PCRE2BacktrackingMatcher new
		          subject: text
		          root: root
		          groups: groups
		          names: names
		          limit: matcher context matchLimit;
		          depthLimit: matcher context depthLimit;
		          initialPosition: initial;
		          matchOptions: (matchOptions bitOr: (compileOptions bitAnd: PCRE2 endAnchored)).
	anchored := ((matchOptions bitOr: compileOptions) bitAnd: PCRE2 anchored) ~= 0.
	offsetLimit := matcher context offsetLimit.
	offsetLimit ifNotNil: [
			(compileOptions bitAnd: PCRE2 useOffsetLimit) = 0 ifTrue: [
				PCRE2MatchError signal: 'offset limit is not enabled for this pattern' ] ].
	lastIndex := anchored
		             ifTrue: [ initial ]
		             ifFalse: [ text size ].
	offsetLimit ifNotNil: [ lastIndex := lastIndex min: (mapping count: [ :offset | offset <= offsetLimit ]) - 1 ].
	initial to: lastIndex do: [ :candidate |
			state := PCRE2MatchState new
				         position: candidate;
				         captures: (Array new: captureCount + 1 * 2 withAll: PCRE2 unsetOffset).
			state captures at: 1 put: candidate.
			state push: root.
			result := engine run: state.
			result ifNotNil: [
					result captures at: 2 put: result position.
					converted := result captures collect: [ :offset |
							             offset = PCRE2 unsetOffset
								             ifTrue: [ offset ]
								             ifFalse: [ mapping at: offset + 1 ] ].
					rc := 1.
					1 to: captureCount do: [ :index | (converted at: index * 2 + 2) ~= PCRE2 unsetOffset ifTrue: [ rc := index + 1 ] ].
					1 to: (converted size min: matchData offsets size) do: [ :index | matchData offsets at: index put: (converted at: index) ].
					matchData
						startIndex: (mapping at: candidate + 1);
						mark: result mark.
					^ rc > matchData getCount
						  ifTrue: [ 0 ]
						  ifFalse: [ rc ] ] ].
	^ PCRE2 errorNoMatch
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> matcher: aMatcher [

	matcher := aMatcher
]

{ #category : 'backends' }
PCRE2MatcherPharoBackend >> newMatchBackend [

	^ self newMatchBackendWithOvectorSize: captureCount + 1
]

{ #category : 'backends' }
PCRE2MatcherPharoBackend >> newMatchBackendWithOvectorSize: size [

	^ PCRE2MatchPharoBackend new
		  codeUnitWidth: matcher codeUnitWidth;
		  offsets: (Array new: size * 2 withAll: PCRE2 unsetOffset)
]

{ #category : 'backends' }
PCRE2MatcherPharoBackend >> newMatchContext [

	| contextClass |
	contextClass := matcher codeUnitWidth = 8
		                ifTrue: [ PCRE2UTF8MatchContext ]
		                ifFalse: [
				                matcher codeUnitWidth = 16
					                ifTrue: [ PCRE2UTF16MatchContext ]
					                ifFalse: [ PCRE2UTF32MatchContext ] ].
	^ contextClass new backend: (PCRE2ContextPharoBackend new codeUnitWidth: matcher codeUnitWidth)
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> prepareForMatch [

	^ self
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> readNamedGroups [

	| result |
	result := Array new: captureCount.
	names keysAndValuesDo: [ :index :name | result at: index put: name ].
	^ result
]

{ #category : 'substitution' }
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

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> requiresSessionRestore [

	^ false
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> root: aNode parser: parser [

	root := aNode.
	captureCount := parser captureCount.
	names := parser names.
	groups := parser groups
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> serialize [

	PCRE2UnsupportedFeature signal: 'C bytecode serialization is specific to the FFI backend'
]

{ #category : 'substitution' }
PCRE2MatcherPharoBackend >> substituteBytes: subject replacement: replacement options: substituteOptions matchData: matchData [

	| allowed matchFlags input text replacementInput expression temporary matches replacementOnly lastEnd |
	matchFlags := PCRE2 anchored | PCRE2 endAnchored | PCRE2 notBOL | PCRE2 notEOL | PCRE2 notEmpty | PCRE2 notEmptyAtStart
	              | PCRE2 noJIT.
	allowed := matchFlags | PCRE2 substituteGlobal | PCRE2 substituteLiteral | PCRE2 substituteUnsetEmpty
	           | PCRE2 substituteUnknownUnset | PCRE2 substituteReplacementOnly | PCRE2 substituteOverflowLength.
	(substituteOptions bitAnd: allowed bitInvert) ~= 0 ifTrue: [
		PCRE2UnsupportedFeature signal: 'These substitution options are not yet implemented by the Pharo backend' ].
	input := matcher preparedInputFor: subject.
	text := input readFrom: 1 to: input size.
	text isString ifFalse: [ text := text asString ].
	replacementInput := matcher preparedInputFor: replacement.
	expression := replacementInput readFrom: 1 to: replacementInput size.
	expression isString ifFalse: [ expression := expression asString ].
	temporary := matcher copy.
	temporary options: (substituteOptions bitAnd: matchFlags).
	matches := (substituteOptions bitAnd: PCRE2 substituteGlobal) ~= 0
		           ifTrue: [ temporary findAllMatches: input ]
		           ifFalse: [ (temporary findMatch: input) ifNil: [ #(  ) ] ifNotNil: [ :match | { match } ] ].
	replacementOnly := (substituteOptions bitAnd: PCRE2 substituteReplacementOnly) ~= 0.
	lastEnd := 0.
	^ String streamContents: [ :stream |
			  matches do: [ :match |
					  | start end |
					  start := input characterCountUpToCodeUnitOffset: (match startOffsetAt: 1).
					  end := input characterCountUpToCodeUnitOffset: (match endOffsetAt: 1).
					  start < lastEnd ifTrue: [ PCRE2MatchError signal: 'invalid substitution match offsets' ].
					  replacementOnly ifFalse: [ stream nextPutAll: (text copyFrom: lastEnd + 1 to: start) ].
					  stream nextPutAll: ((substituteOptions bitAnd: PCRE2 substituteLiteral) ~= 0
							   ifTrue: [ expression ]
							   ifFalse: [ self expand: expression match: match options: substituteOptions ]).
					  lastEnd := end ].
			  replacementOnly ifFalse: [ stream nextPutAll: (text copyFrom: lastEnd + 1 to: text size) ] ]
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> textAndOffsetsFor: bytes length: length [

	| input text mapping offset utf |
	(length < 0 or: [ length > (bytes size // matcher codeUnitByteSize) ]) ifTrue: [ PCRE2MatchError signal: 'bad subject length' ].
	input := matcher preparedInputFor: (bytes copyFrom: 1 to: length * matcher codeUnitByteSize).
	utf := (compileOptions bitAnd: PCRE2 utf) ~= 0.
	utf
		ifTrue: [
				text := [ input readFrom: 1 to: input size ]
					        on: Error
					        do: [ :error | PCRE2MatchError signal: 'invalid UTF subject' ].
				text isString ifFalse: [ text := text asString ] ]
		ifFalse: [
				self codeUnitWidth = 8
					ifTrue: [ text := input bytes asString ]
					ifFalse: [ PCRE2UnsupportedFeature signal: 'Non-UTF wide subjects are not yet implemented by the Pharo backend' ] ].
	mapping := Array new: text size + 1.
	offset := 0.
	mapping at: 1 put: 0.
	text withIndexDo: [ :character :index |
			offset := offset + (utf
				           ifTrue: [ self codeUnitsFor: character ]
				           ifFalse: [ 1 ]).
			mapping at: index + 1 put: offset ].
	^ {
		  text.
		  mapping }
]
