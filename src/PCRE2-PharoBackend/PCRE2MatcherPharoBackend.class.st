"
Compiled-pattern implementation for the Pharo backend. It owns the node tree and the capture metadata the parser produced, and runs ordinary, DFA, substitution and callout matching over them.
"
Class {
	#name : 'PCRE2MatcherPharoBackend',
	#superclass : 'Object',
	#instVars : [
		'matcher',
		'root',
		'captureCount',
		'names',
		'groups',
		'compileOptions',
		'newlineMode',
		'bsrMode',
		'maximumLookbehind',
		'calloutSites',
		'patternMatchOptions',
		'patternLimits',
		'dfaStates',
		'startLine',
		'startCharacters',
		'requiredCharacter',
		'startCharacterTable',
		'newlineConvention',
		'generatedMethod',
		'generatedOffsets'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'testing' }
PCRE2MatcherPharoBackend >> allowsEmptyPartial [
	"Whether PCRE2 counts a partial match that consumed nothing, which it does for a pattern that looks behind or can match an empty string."

	^ self maximumLookbehind > 0 or: [ root minimumLength = 0 ]
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> autoRelease [

	^ self
]

{ #category : 'callouts' }
PCRE2MatcherPharoBackend >> calloutSitesDo: block [

	calloutSites do: block
]

{ #category : 'generated matching' }
PCRE2MatcherPharoBackend >> canRunGeneratedIn: text options: matchOptions [
	"Whether the written method can answer this match on its own. It knows the shapes of pattern it was written for and nothing else, so everything it does not know is refused here rather than guessed at."

	| refused |
	refused := PCRE2 partialSoft | PCRE2 partialHard | PCRE2 notEmpty | PCRE2 notEmptyAtStart | PCRE2 notBOL | PCRE2 notEOL
	           | PCRE2 endAnchored.
	^ text isByteWide and: [
			  matcher context backend calloutBlock isNil and: [
					  ((matchOptions bitOr: patternMatchOptions) bitAnd: refused) = 0 and: [
							  (compileOptions bitAnd: PCRE2 endAnchored | PCRE2 firstLine) = 0 and: [
								  self limitsAreDefault and: [ self generatedMethod isNotNil ] ] ] ] ]
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> canStartAt: offset in: text [
	"Whether a match could begin with the character at this offset, read from the table of the codes a match can start with."

	| code |
	offset >= text size ifTrue: [ ^ false ].
	code := text codePointAtOffset: offset.
	code > 255 ifTrue: [ ^ startCharacters value: (PCRE2CodeUnit fromInteger: code) ].
	^ (startCharacterTable at: code + 1) = 1
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> codeUnitWidth [

	^ matcher codeUnitWidth
]

{ #category : 'accessing' }
PCRE2MatcherPharoBackend >> compileOptions: anInteger [

	compileOptions := anInteger
]

{ #category : 'diagnostics' }
PCRE2MatcherPharoBackend >> compiledStorageSize [

	| seen |
	seen := IdentitySet new.
	^ self sizeInMemory + (PCRE2CompiledPatternSize of: root seen: seen) + (PCRE2CompiledPatternSize of: groups seen: seen)
	  + (PCRE2CompiledPatternSize of: names seen: seen)
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> copyWithCharacterTables [

	^ self copy
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> depthLimit [

	^ matcher context depthLimit min: (patternLimits at: #depth ifAbsent: [ matcher context depthLimit ])
]

{ #category : 'accessing' }
PCRE2MatcherPharoBackend >> family [

	^ #pharo
]

{ #category : 'library path' }
PCRE2MatcherPharoBackend >> ffiLibraryName [

	PCRE2UnsupportedFeature signal: 'The Pharo backend does not use a C library'
]

{ #category : 'finalization' }
PCRE2MatcherPharoBackend >> finalize [

	^ self
]

{ #category : 'invalid UTF' }
PCRE2MatcherPharoBackend >> firstFragmentIn: text from: start [
	"The lookbehind floor and the bounds of the fragment a match starting at this offset belongs to. A start offset inside an invalid sequence moves on to the next character, as PCRE2 specifies, and nothing may then be read behind that."

	| total begin floor end |
	total := text codeUnitCount.
	begin := text characterStartFrom: start upTo: total.
	floor := begin = start
		         ifTrue: [ self lookbehindFloorIn: text at: begin ]
		         ifFalse: [ begin ].
	[
		end := text invalidOffsetFrom: floor.
		end isNotNil and: [ end < begin ] ] whileTrue: [ "The invalid sequence lies behind the match, in what a lookbehind could otherwise have reached."
		floor := text characterStartFrom: end + 1 upTo: begin ].
	^ {
		  floor.
		  begin.
		  (end ifNil: [ total ]) }
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> firstLineEndIn: text from: start [

	| offset |
	offset := start.
	[ offset < text size ] whileTrue: [
			(newlineConvention lengthAt: offset + 1 in: text) > 0 ifTrue: [ ^ offset ].
			offset := text nextOffsetFrom: offset ].
	^ text size
]

{ #category : 'invalid UTF' }
PCRE2MatcherPharoBackend >> fragmentAfter: offset in: text [
	"The lookbehind floor and the bounds of the next non-empty fragment of valid UTF, which begins past the invalid sequence at this offset, or nil when the subject has none left. A later fragment cannot be entered from behind, so its floor is its start."

	| total begin end |
	total := text codeUnitCount.
	end := offset.
	[
		begin := text characterStartFrom: end + 1 upTo: total.
		begin >= total ifTrue: [ ^ nil ].
		end := text invalidOffsetFrom: begin.
		end ifNil: [
				^ {
					  begin.
					  begin.
					  total } ].
		end > begin ifTrue: [
				^ {
					  begin.
					  begin.
					  end } ] ] repeat
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> free [

	^ self
]

{ #category : 'generated matching' }
PCRE2MatcherPharoBackend >> generatedMethod [
	"The method written for this pattern, or nil when its shape does not allow one. Written and compiled on first use, so a pattern that is never matched never pays for it."

	generatedMethod == #pending ifTrue: [
			generatedMethod := self writtenMethod.
			generatedOffsets := Array new: captureCount + 1 * 2 ].
	^ generatedMethod
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> heapLimit [

	^ matcher context heapLimit min: (patternLimits at: #heap ifAbsent: [ matcher context heapLimit ])
]

{ #category : 'diagnostics' }
PCRE2MatcherPharoBackend >> info: option [

	option = PCRE2 infoSize ifTrue: [ ^ self compiledStorageSize ].
	option = PCRE2 infoFrameSize ifTrue: [ ^ PCRE2MatchState new sizeInMemory ].
	option = PCRE2 infoNewline ifTrue: [ ^ newlineMode ].
	option = PCRE2 infoBSR ifTrue: [ ^ bsrMode ].
	option = PCRE2 infoArgOptions ifTrue: [ ^ compileOptions ].
	option = PCRE2 infoMaxLookbehind ifTrue: [ ^ self maximumLookbehind ].
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

{ #category : 'generated matching' }
PCRE2MatcherPharoBackend >> limitsAreDefault [
	"Whether nothing has asked this match for a limit of its own. The written method keeps no count of its work and allocates nothing to bound, so a pattern or a context that sets a limit is left to the engine, which does both."

	patternLimits ifNotEmpty: [ ^ false ].
	^ self matchLimit = PCRE2ContextPharoBackend defaultMatchLimit and: [
		  self depthLimit = PCRE2ContextPharoBackend defaultDepthLimit and: [
			  self heapLimit = PCRE2ContextPharoBackend defaultHeapLimit ] ]
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> lineStartFrom: offset in: text matchStart: origin [
	"The first position at or after this one that follows a line terminator, giving up at the end of the subject. A pattern every branch of which starts at a line start is only ever tried there, except at the offset the caller asked to match from, which is always tried as it stands."

	| position |
	offset <= origin ifTrue: [ ^ offset ].
	position := offset.
	[ position < text size and: [ (newlineConvention lengthEndingAt: position in: text) = 0 ] ] whileTrue: [
		position := text nextOffsetFrom: position ].
	^ position
]

{ #category : 'invalid UTF' }
PCRE2MatcherPharoBackend >> lookbehindFloorIn: text at: offset [
	"How far behind the start of a match a lookbehind may still read: as many characters as the pattern's longest one, which is how PCRE2 bounds the subject it checks."

	| floor remaining |
	floor := offset.
	remaining := self maximumLookbehind.
	[ remaining > 0 and: [ floor > 0 ] ] whileTrue: [
			floor := text previousOffsetFrom: floor.
			remaining := remaining - 1 ].
	^ floor
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> match: bytes from: start to: length options: matchOptions matchData: matchData [

	| decoded text mapping allowed |
	allowed := PCRE2 anchored | PCRE2 endAnchored | PCRE2 notBOL | PCRE2 notEOL | PCRE2 notEmpty | PCRE2 notEmptyAtStart
	           | PCRE2 noJIT | PCRE2 disableRecurseloopCheck | PCRE2 noUTFCheck | PCRE2 copyMatchedSubject | PCRE2 partialSoft
	           | PCRE2 partialHard.
	(matchOptions bitAnd: allowed bitInvert) ~= 0 ifTrue: [ PCRE2UnsupportedFeature signal: 'Unknown match option bits' ].
	decoded := self textAndOffsetsFor: bytes length: length.
	text := decoded first.
	mapping := decoded second.
	(start between: 0 and: text size) ifFalse: [ PCRE2MatchError signal: 'bad offset value' ].
	self matchesInvalidUTF ifTrue: [
			^ self
				  matchFragmentsIn: text
				  from: start
				  mapping: mapping
				  options: matchOptions
				  matchData: matchData ].
	((matchOptions bitAnd: PCRE2 noUTFCheck) = 0 and: [ (text isBoundary: start) not ]) ifTrue: [
		PCRE2MatchError signal: (PCRE2 translateErrorCode: -36) ].
	^ self
		  matchIn: text
		  from: start
		  matchStart: start
		  mapping: mapping
		  options: matchOptions
		  matchData: matchData
]

{ #category : 'invalid UTF' }
PCRE2MatcherPharoBackend >> matchFragmentsIn: text from: start mapping: mapping options: matchOptions matchData: matchData [
	"PCRE2_MATCH_INVALID_UTF reads the subject as fragments of valid UTF separated by invalid sequences. An invalid sequence is a barrier no match may cross, so each fragment is matched in turn as if it were the whole subject, except that an internal edge is neither the start nor the end of a line. Only the last fragment may answer a partial match."

	| total fragment end options rc |
	total := text codeUnitCount.
	fragment := self firstFragmentIn: text from: start.
	options := matchOptions.
	[
		end := fragment third.
		rc := self
			      matchIn: (text fragmentFrom: fragment first to: end)
			      from: fragment second
			      matchStart: start
			      mapping: mapping
			      options: (end < total
					       ifTrue: [ options bitOr: PCRE2 notEOL ]
					       ifFalse: [ options ])
			      matchData: matchData.
		end < total and: [ rc = PCRE2 errorNoMatch or: [ rc = PCRE2 errorPartial ] ] ] whileTrue: [
			fragment := self fragmentAfter: end in: text.
			fragment ifNil: [
					matchData offsets atAllPut: PCRE2 unsetOffset.
					^ PCRE2 errorNoMatch ].
			options := matchOptions bitOr: PCRE2 notBOL ].
	^ rc
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> matchIn: text from: begin matchStart: origin mapping: mapping options: matchOptions matchData: matchData [
	"Search text, which may be one fragment of a larger subject, for a match beginning at or after begin. What \G and PCRE2_NOT_EMPTY_AT_START pin themselves to is origin, the offset the caller asked to match from."

	| engine state result anchored lastIndex converted rc offsetLimit candidate filtering jumpsToLineStarts optimizing generated |
	optimizing := (compileOptions bitAnd: PCRE2 noStartOptimize) = 0 and: [
		              (matchOptions bitAnd: PCRE2 partialSoft | PCRE2 partialHard) = 0 ].
	(optimizing and: [
		 requiredCharacter isNotNil and: [ (text anyCodeSatisfy: [ :code | requiredCharacter acceptsCode: code ]) not ] ]) ifTrue: [
		^ PCRE2 errorNoMatch ].
	anchored := ((matchOptions bitOr: compileOptions) bitAnd: PCRE2 anchored) ~= 0.
	offsetLimit := matcher context offsetLimit.
	offsetLimit ifNotNil: [
		(compileOptions bitAnd: PCRE2 useOffsetLimit) = 0 ifTrue: [ PCRE2MatchError signal: (PCRE2 translateErrorCode: -56) ] ].
	lastIndex := anchored
		             ifTrue: [ begin ]
		             ifFalse: [ text size ].
	offsetLimit ifNotNil: [ lastIndex := lastIndex min: offsetLimit ].
	(compileOptions bitAnd: PCRE2 firstLine) ~= 0 ifTrue: [ lastIndex := lastIndex min: (self firstLineEndIn: text from: begin) ].
	(self canRunGeneratedIn: text options: matchOptions) ifTrue: [
			generated := self
				             runGeneratedIn: text
				             from: begin
				             to: lastIndex
				             mapping: mapping
				             matchData: matchData.
			generated ifNotNil: [ ^ generated ] ].
	engine := PCRE2MatchEngine new
		          subject: text
		          root: root
		          groups: groups
		          names: names
		          limit: self matchLimit;
		          depthLimit: self depthLimit;
		          heapLimit: self heapLimit;
		          allowEmptyPartial: self allowsEmptyPartial;
		          initialPosition: origin;
		          matchOptions: (matchOptions bitOr: ((compileOptions bitAnd: PCRE2 endAnchored) bitOr: patternMatchOptions)).
	engine calloutBlock: matcher context backend calloutBlock mapping: mapping.
	"PCRE2 looks either for the characters a match can start with or for a line start, never for both, and it keeps the first of them to itself while matching partially."
	jumpsToLineStarts := startLine and: [ anchored not ].
	filtering := startCharacters isNotNil and: [
			             jumpsToLineStarts not and: [
					             (compileOptions bitAnd: PCRE2 noStartOptimize) = 0 and: [
						             anchored or: [ (matchOptions bitAnd: PCRE2 partialSoft | PCRE2 partialHard) = 0 ] ] ] ].
	candidate := jumpsToLineStarts
		             ifTrue: [ self lineStartFrom: begin in: text matchStart: origin ]
		             ifFalse: [ begin ].
	[ candidate <= lastIndex ] whileTrue: [
			(filtering not or: [ self canStartAt: candidate in: text ]) ifTrue: [
					state := PCRE2MatchState new
						         position: candidate;
						         captures: (Array new: captureCount + 1 * 2 withAll: PCRE2 unsetOffset).
					state captures at: 1 put: candidate.
					state push: root.
					engine beginMatchAt: candidate.
					result := engine run: state.
					engine abortedCode ifNotNil: [ :code | ^ code ].
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
								  ifFalse: [ rc ] ].
					engine hardPartialFound ifTrue: [ ^ self storePartial: engine partialState mapping: mapping into: matchData ].
					engine committed ifTrue: [ ^ PCRE2 errorNoMatch ] ].
			candidate := text nextOffsetFrom: candidate.
			engine skipPosition ifNotNil: [ :skip | candidate := candidate max: skip ].
			jumpsToLineStarts ifTrue: [ candidate := self lineStartFrom: candidate in: text matchStart: origin ] ].
	engine partialState ifNotNil: [ :partial | ^ self storePartial: partial mapping: mapping into: matchData ].
	matchData mark: engine lastMark.
	^ PCRE2 errorNoMatch
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> matchLimit [

	^ matcher context matchLimit min: (patternLimits at: #match ifAbsent: [ matcher context matchLimit ])
]

{ #category : 'accessing' }
PCRE2MatcherPharoBackend >> matcher: aMatcher [

	matcher := aMatcher
]

{ #category : 'testing' }
PCRE2MatcherPharoBackend >> matchesInvalidUTF [
	"Whether PCRE2_MATCH_INVALID_UTF was compiled in, making an invalid sequence in the subject a barrier rather than an error."

	^ (compileOptions bitAnd: PCRE2 matchInvalidUTF) ~= 0
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> maximumLookbehind [

	^ maximumLookbehind ifNil: [ 0 ]
]

{ #category : 'instance creation' }
PCRE2MatcherPharoBackend >> newMatchBackend [

	^ self newMatchBackendWithOvectorSize: captureCount + 1
]

{ #category : 'instance creation' }
PCRE2MatcherPharoBackend >> newMatchBackendWithOvectorSize: size [

	^ PCRE2MatchPharoBackend new
		  codeUnitWidth: matcher codeUnitWidth;
		  offsets: (Array new: size * 2 withAll: PCRE2 unsetOffset)
]

{ #category : 'instance creation' }
PCRE2MatcherPharoBackend >> newMatchContext [

	^ matcher matchContextClass new backend: (PCRE2ContextPharoBackend new codeUnitWidth: matcher codeUnitWidth)
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

{ #category : 'compiling' }
PCRE2MatcherPharoBackend >> recompiledBy: compiler pattern: pattern [

	^ compiler backend compilePreparedInput: (compiler preparedPatternFor: pattern)
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> requiresSessionRestore [

	^ false
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> root: aNode parser: parser [
	"The start optimizations are worked out here rather than per match: the tree does not change once it is compiled, which is also when PCRE2 studies it. The written method waits for the first match that could use it."

	root := aNode.
	patternLimits := parser patternLimits.
	patternMatchOptions := parser patternMatchOptions.
	calloutSites := parser calloutSites.
	maximumLookbehind := parser maximumLookbehind.
	newlineMode := parser newlineMode.
	newlineConvention := PCRE2NewlineConvention new mode: newlineMode.
	bsrMode := parser bsrMode.
	captureCount := parser captureCount.
	names := parser names.
	groups := parser groups.
	startLine := parser startLine.
	requiredCharacter := root requiredNode.
	startCharacters := root minimumLength = 0
		                   ifTrue: [ nil ]
		                   ifFalse: [ root firstLiteralPredicate ifNil: [ root startPredicate ] ].
	startCharacterTable := startCharacters ifNotNil: [ PCRE2CharacterNode tableFor: startCharacters ].
	generatedMethod := #pending
]

{ #category : 'generated matching' }
PCRE2MatcherPharoBackend >> runGeneratedIn: text from: begin to: last mapping: mapping matchData: matchData [
	"Run the written method over the subject bytes, or answer nil when it meets a byte it cannot judge and the engine has to take over. A group that did not take part comes back as a negative offset, which is how the written method says what PCRE2 calls unset."

	| answer count |
	answer := generatedMethod valueWithReceiver: self arguments: {
			          begin.
			          last.
			          text storage.
			          generatedOffsets }.
	answer ifNil: [ ^ nil ].
	answer ifFalse: [
			matchData mark: nil.
			^ PCRE2 errorNoMatch ].
	count := 1.
	1 to: captureCount do: [ :index | (generatedOffsets at: index * 2 + 2) >= 0 ifTrue: [ count := index + 1 ] ].
	1 to: (generatedOffsets size min: matchData offsets size) do: [ :index |
			| offset |
			offset := generatedOffsets at: index.
			matchData offsets at: index put: (offset < 0
					 ifTrue: [ PCRE2 unsetOffset ]
					 ifFalse: [ mapping at: offset + 1 ]) ].
	matchData
		startIndex: (mapping at: (generatedOffsets at: 1) + 1);
		mark: nil.
	^ count > matchData getCount
		  ifTrue: [ 0 ]
		  ifFalse: [ count ]
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> serialize [

	PCRE2UnsupportedFeature signal: 'C bytecode serialization is specific to the FFI backend'
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> storePartial: state mapping: mapping into: data [

	data offsets atAllPut: PCRE2 unsetOffset.
	data offsets
		at: 1 put: (mapping at: state captures first + 1);
		at: 2 put: mapping last.
	data
		startIndex: (mapping at: state captures first + 1);
		mark: state mark.
	^ PCRE2 errorPartial
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> textAndOffsetsFor: bytes length: length [

	| input subject utf effectiveLength |
	effectiveLength := length = PCRE2 zeroTerminated
		                   ifTrue: [ self zeroTerminatedLength: bytes ]
		                   ifFalse: [ length ].
	(effectiveLength < 0 or: [ effectiveLength > (bytes size // matcher codeUnitByteSize) ]) ifTrue: [
		PCRE2MatchError signal: 'bad subject length' ].
	input := matcher preparedInputFor: (bytes copyFrom: 1 to: effectiveLength * matcher codeUnitByteSize).
	utf := (compileOptions bitAnd: PCRE2 utf) ~= 0.
	(utf and: [ self matchesInvalidUTF not ]) ifTrue: [ PCRE2CodeUnitText validateUTF: input bytes width: self codeUnitWidth ].
	subject := PCRE2SubjectText new bytes: input bytes width: self codeUnitWidth utf: utf.
	^ {
		  subject.
		  (0 to: subject size) }
]

{ #category : 'generated matching' }
PCRE2MatcherPharoBackend >> writtenMethod [
	"A method matching this pattern alone, or nil for a shape the generator does not know. A pattern that can only begin a line needs the byte ending one. The compiler may refuse a method too deep or with too many locals, and the engine keeps that pattern. The method keeps neither its source nor its argument names."

	| terminator source |
	terminator := startLine ifTrue: [ newlineConvention singleTerminator ifNil: [ ^ nil ] ].
	source := (PCRE2MatchGenerator sourceFor: root captures: captureCount lineStart: terminator) ifNil: [ ^ nil ].
	^ [
		  (OpalCompiler new
			   class: self class;
			   source: source;
			   compile)
			  removeProperty: #source;
			  removeProperty: #argumentNames;
			  yourself ]
		  on: Error
		  do: [ :error | nil ]
]

{ #category : 'matching' }
PCRE2MatcherPharoBackend >> zeroTerminatedLength: bytes [

	| width |
	width := matcher codeUnitByteSize.
	1 to: bytes size - width + 1 by: width do: [ :index |
		((index to: index + width - 1) allSatisfy: [ :offset | (bytes at: offset) asInteger = 0 ]) ifTrue: [ ^ index - 1 // width ] ].
	^ bytes size // width
]
