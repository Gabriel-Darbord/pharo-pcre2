Extension { #name : 'PCRE2MatchState' }

{ #category : '*PCRE2-PharoBackend-DFA' }
PCRE2MatchState >> dfaKey [

	| node keys |
	keys := OrderedCollection new.
	node := tasks.
	[ node isNotNil ] whileTrue: [
			keys add: node first dfaKey.
			node := node second ].
	^ {
		  position.
		  keys asArray }
]

{ #category : '*PCRE2-PharoBackend-DFA' }
PCRE2MatchState >> restartAfter: size [

	| nodes link |
	nodes := OrderedCollection new.
	link := tasks.
	[ link isNotNil ] whileTrue: [
			nodes add: ((link first isKindOf: PCRE2RepeatFrame)
					 ifTrue: [ link first copy previousPosition: (link first previousPosition ifNotNil: [ :offset | offset - size ]) ]
					 ifFalse: [ link first ]).
			link := link second ].
	self tasks: nil.
	nodes reverseDo: [ :node | self push: node ].
	position := 0
]
