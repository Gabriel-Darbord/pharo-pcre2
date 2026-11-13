Extension { #name : 'SpAbstractListPresenter' }

{ #category : '*PCRE2-Compatibility-Before11' }
SpAbstractListPresenter >> whenSelectedItemChangedDo: aBlock [

	"Inform when the selected item is changed.
	 `aBlock` receive one optional argument: the selected item (can be nil)"

	self selection whenChangedDo: [ aBlock cull: self selectedItem ]
]
