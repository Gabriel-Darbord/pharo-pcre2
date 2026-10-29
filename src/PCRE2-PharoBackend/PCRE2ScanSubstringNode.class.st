"
An anchored assertion over the first participating capture in an ordered list. The subject origin is preserved and its end is temporarily shortened.
"
Class {
	#name : 'PCRE2ScanSubstringNode',
	#superclass : 'PCRE2LookaheadNode',
	#instVars : [
		'references'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2ScanSubstringNode >> canBeCondition [

	^ false
]

{ #category : 'matching' }
PCRE2ScanSubstringNode >> dfaError [

	^ -42
]

{ #category : 'matching' }
PCRE2ScanSubstringNode >> executeIn: engine state: state [

	| index start end boundary |
	references do: [ :reference |
			index := engine captureIndexFor: reference state: state.
			index ifNotNil: [
					start := state captures at: index * 2 + 1.
					end := state captures at: index * 2 + 2.
					(start ~= PCRE2 unsetOffset and: [ end ~= PCRE2 unsetOffset ]) ifTrue: [
							boundary := PCRE2ScanSubstringEndNode new
								            position: state position assertions: state assertions alternations: state alternations;
								            previousSubject: state subjectText.
							state
								subjectText: (engine scanSubjectTo: end);
								position: start;
								assertions: {
										engine choiceDepth.
										state assertions };
								alternations: nil;
								push: boundary;
								push: child.
							^ state ] ] ].
	^ nil
]

{ #category : 'matching' }
PCRE2ScanSubstringNode >> references: aCollection [

	references := aCollection
]
