"
Holders for the output parameters of PCRE2 functions (`int *`, `uint32_t *`, `PCRE2_SIZE *`), shared with the binding without becoming global classes.
"
Class {
	#name : 'PCRE2Types',
	#superclass : 'SharedPool',
	#classVars : [
		'IntHolder',
		'SizeTHolder',
		'UInt32Holder'
	],
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'class initialization' }
PCRE2Types class >> initialize [

	SizeTHolder := FFIExternalValueHolder ofType: 'size_t'.
	IntHolder := FFIExternalValueHolder ofType: 'int'.
	UInt32Holder := FFIExternalValueHolder ofType: 'uint32'
]
