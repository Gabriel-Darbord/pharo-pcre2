Extension { #name : 'PCRE2TraceStep' }

{ #category : '*PCRE2-Tools' }
PCRE2TraceStep >> debuggerCalloutLabel [

	| calloutEvent |
	calloutEvent := self event.
	calloutEvent isAutomatic ifTrue: [ ^ 'automatic' ].
	calloutEvent string ifNotNil: [ :string |
			^ String streamContents: [ :stream |
					  stream
						  nextPut: $#;
						  print: calloutEvent number;
						  space;
						  print: string ] ].
	^ '#' , calloutEvent number asString
]

{ #category : '*PCRE2-Tools' }
PCRE2TraceStep >> debuggerKindLabel [

	kind = #startMatch ifTrue: [ ^ 'start' ].
	kind = #progress ifTrue: [ ^ 'advance' ].
	kind = #backtrack ifTrue: [ ^ 'backtrack' ].
	^ kind asString
]

{ #category : '*PCRE2-Tools' }
PCRE2TraceStep >> debuggerPatternRangeLabel [

	^ self debuggerRangeLabelFor: self patternRange
]

{ #category : '*PCRE2-Tools' }
PCRE2TraceStep >> debuggerRangeLabelFor: anIntervalOrNil [

	anIntervalOrNil ifNil: [ ^ '' ].
	anIntervalOrNil isEmpty ifTrue: [ ^ anIntervalOrNil first asString , ' (empty)' ].
	^ String streamContents: [ :stream | stream << anIntervalOrNil first asString << '-' << anIntervalOrNil last asString ]
]

{ #category : '*PCRE2-Tools' }
PCRE2TraceStep >> debuggerSubjectRangeLabel [

	^ self debuggerRangeLabelFor: self subjectRange
]
