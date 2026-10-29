Class {
	#name : 'PCRE2MatchState',
	#superclass : 'Object',
	#instVars : [
		'position',
		'captures',
		'tasks',
		'mark',
		'pendingDepth'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'private' }
PCRE2MatchState >> captures [

	^ captures
]

{ #category : 'private' }
PCRE2MatchState >> captures: aValue [

	captures := aValue
]

{ #category : 'matching' }
PCRE2MatchState >> initialize [

	pendingDepth := 0
]

{ #category : 'private' }
PCRE2MatchState >> mark [

	^ mark
]

{ #category : 'private' }
PCRE2MatchState >> mark: aValue [

	mark := aValue
]

{ #category : 'matching' }
PCRE2MatchState >> pendingDepth [

	^ pendingDepth
]

{ #category : 'matching' }
PCRE2MatchState >> pop [

	| node |
	node := tasks first.
	tasks := tasks second.
	pendingDepth := pendingDepth - 1.
	^ node
]

{ #category : 'private' }
PCRE2MatchState >> position [

	^ position
]

{ #category : 'private' }
PCRE2MatchState >> position: aValue [

	position := aValue
]

{ #category : 'private' }
PCRE2MatchState >> postCopy [

	captures := captures copy
]

{ #category : 'matching' }
PCRE2MatchState >> push: aNode [

	tasks := {
		         aNode.
		         tasks }.
	pendingDepth := pendingDepth + 1
]

{ #category : 'private' }
PCRE2MatchState >> tasks [

	^ tasks
]

{ #category : 'matching' }
PCRE2MatchState >> tasks: aList [

	| link |
	tasks := aList.
	pendingDepth := 0.
	link := aList.
	[ link isNotNil ] whileTrue: [
			pendingDepth := pendingDepth + 1.
			link := link second ]
]
