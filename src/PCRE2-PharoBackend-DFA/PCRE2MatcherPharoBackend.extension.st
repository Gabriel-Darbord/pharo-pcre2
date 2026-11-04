Extension { #name : 'PCRE2MatcherPharoBackend' }

{ #category : '*PCRE2-PharoBackend-DFA' }
PCRE2MatcherPharoBackend >> dfaMatch: bytes from: start to: length matchData: data workspace: workspace size: workspaceSize [

	| decoded text mapping initial engine state matches lastIndex options allowed minimum candidate continuation |
	options := matcher options.
	(workspaceSize < 20 or: [ workspace size < (workspaceSize * 4) ]) ifTrue: [
		PCRE2MatchError signal: (PCRE2 translateErrorCode: -43) ].
	continuation := (options bitAnd: PCRE2 dfaRestart) ~= 0
		                ifTrue: [ self restartDFAFrom: workspace ]
		                ifFalse: [
				                dfaStates ifNotNil: [ dfaStates removeKey: workspace ifAbsent: [ ] ].
				                nil ].
	allowed := PCRE2 anchored | PCRE2 endAnchored | PCRE2 notBOL | PCRE2 notEOL | PCRE2 notEmpty | PCRE2 notEmptyAtStart
	           | PCRE2 dfaShortest | PCRE2 dfaRestart | PCRE2 noUTFCheck | PCRE2 partialSoft | PCRE2 partialHard
	           | PCRE2 copyMatchedSubject.
	(options bitAnd: allowed bitInvert) ~= 0 ifTrue: [ PCRE2UnsupportedFeature signal: 'Unknown DFA match option bits' ].
	decoded := self textAndOffsetsFor: bytes length: length.
	text := decoded first.
	mapping := decoded second.
	initial := start.
	(start between: 0 and: text size) ifFalse: [ PCRE2MatchError signal: 'bad offset value' ].
	"PCRE2 leaves invalid UTF subjects to the ordinary matching function."
	self matchesInvalidUTF ifTrue: [ ^ PCRE2 errorDFAInvalidUTF ].
	((options bitAnd: PCRE2 noUTFCheck) = 0 and: [ (text isBoundary: start) not ]) ifTrue: [
		PCRE2MatchError signal: (PCRE2 translateErrorCode: -36) ].
	engine := PCRE2DFAMatchEngine new
		          subject: text
		          root: root
		          groups: groups
		          names: names
		          limit: self matchLimit;
		          depthLimit: self depthLimit;
		          initialPosition: initial;
		          matchOptions: (options bitOr: ((compileOptions bitAnd: PCRE2 endAnchored) bitOr: patternMatchOptions));
		          calloutBlock: matcher context backend calloutBlock mapping: mapping;
		          shortest: (options bitAnd: PCRE2 dfaShortest) ~= 0;
		          autoPossessEnabled: (compileOptions bitAnd: PCRE2 noAutoPossess) = 0;
		          workspaceLimit: workspaceSize;
		          allowEmptyPartial: self allowsEmptyPartial.
	lastIndex := (continuation isNotNil or: [ ((options bitOr: compileOptions) bitAnd: PCRE2 anchored) ~= 0 ])
		             ifTrue: [ initial ]
		             ifFalse: [ text size ].
	minimum := self shortestMatchLength.
	(compileOptions bitAnd: PCRE2 firstLine) ~= 0 ifTrue: [ lastIndex := lastIndex min: (self firstLineEndIn: text from: initial) ].
	candidate := initial.
	[ candidate <= lastIndex ] whileTrue: [
			(continuation isNotNil or: [
					 (compileOptions bitAnd: PCRE2 noStartOptimize) ~= 0 or: [
						 (options bitAnd: PCRE2 partialSoft | PCRE2 partialHard) ~= 0 or: [ text size - candidate >= minimum ] ] ]) ifTrue: [
					state := PCRE2MatchState new
						         position: candidate;
						         captures: (Array new: captureCount + 1 * 2 withAll: PCRE2 unsetOffset).
					state captures at: 1 put: candidate.
					state push: root.
					engine beginMatchAt: candidate.
					matches := continuation ifNil: [ engine allMatches: state ] ifNotNil: [
							           continuation do: [ :continued | continued captures at: 1 put: initial ].
							           engine allMatchesFrom: continuation ].
					engine abortedCode ifNotNil: [ :code | ^ code ].
					(engine hardPartialFound and: [ engine partialState isNotNil ]) ifTrue: [
							self rememberDFA: engine in: workspace.
							^ self storePartial: engine partialState mapping: mapping into: data ].
					matches ifNotEmpty: [
							(options bitAnd: PCRE2 dfaShortest) ~= 0 ifTrue: [ matches := { matches last } ].
							1 to: (matches size min: data getCount) do: [ :index |
									data offsets
										at: index * 2 - 1 put: (mapping at: candidate + 1);
										at: index * 2 put: (mapping at: (matches at: index) position + 1) ].
							data startIndex: (mapping at: candidate + 1).
							^ matches size > data getCount
								  ifTrue: [ 0 ]
								  ifFalse: [ matches size ] ] ].
			engine partialState ifNotNil: [ :partial |
					self rememberDFA: engine in: workspace.
					^ self storePartial: partial mapping: mapping into: data ].
			candidate := text nextOffsetFrom: candidate ].
	engine partialState ifNotNil: [ :partial |
			self rememberDFA: engine in: workspace.
			^ self storePartial: partial mapping: mapping into: data ].
	^ PCRE2 errorNoMatch
]

{ #category : '*PCRE2-PharoBackend-DFA' }
PCRE2MatcherPharoBackend >> rememberDFA: engine in: workspace [

	dfaStates ifNil: [ dfaStates := WeakIdentityKeyDictionary new ].
	dfaStates at: workspace put: engine restartStates.
	workspace uint32AtOffset: 0 put: 16r50435232.
	workspace uint32AtOffset: 4 put: engine restartStates size
]

{ #category : '*PCRE2-PharoBackend-DFA' }
PCRE2MatcherPharoBackend >> restartDFAFrom: workspace [

	| states |
	dfaStates ifNil: [ PCRE2MatchError signal: (PCRE2 translateErrorCode: -38) ].
	states := dfaStates removeKey: workspace ifAbsent: [ PCRE2MatchError signal: (PCRE2 translateErrorCode: -38) ].
	((workspace uint32AtOffset: 0) = 16r50435232 and: [ (workspace uint32AtOffset: 4) = states size ]) ifFalse: [
		PCRE2MatchError signal: (PCRE2 translateErrorCode: -38) ].
	^ states
]

{ #category : '*PCRE2-PharoBackend-DFA' }
PCRE2MatcherPharoBackend >> shortestMatchLength [
	"The least a match can be, in characters. It is compared against a count of code units, which only makes the bound safer."

	^ (root lengthBoundsUsing: groups names: names visited: IdentitySet new) first
]
