Class {
	#name : 'PCRE2Types',
	#superclass : 'SharedPool',
	#classVars : [
		'IntHolder',
		'SizeTHolder',
		'UInt32Holder'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'class initialization' }
PCRE2Types class >> initialize [

	SizeTHolder := FFIExternalValueHolder ofType: 'size_t'.
	IntHolder := FFIExternalValueHolder ofType: 'int'.
	UInt32Holder := FFIExternalValueHolder ofType: 'uint32'
]
