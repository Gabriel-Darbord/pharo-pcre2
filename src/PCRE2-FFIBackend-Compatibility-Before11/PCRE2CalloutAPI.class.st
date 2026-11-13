"
The callout API of the PCRE2 libraries on Pharo 10.

A PCRE2 library calls out on a TFProcessLocalWorker. Pharo 11 registers a callback with the worker such a runner answers for callbacks, TFRunner>>forCallback. Pharo 10 registers it with the process-local runner itself, which has no handle for the VM to run the callback with: the registration fails, and the semaphores the runner registers on the way are never released. I register callbacks with the worker, as Pharo 11 does.
"
Class {
	#name : 'PCRE2CalloutAPI',
	#superclass : 'TFCalloutAPI',
	#category : 'PCRE2-FFIBackend-Compatibility-Before11',
	#package : 'PCRE2-FFIBackend-Compatibility-Before11'
}

{ #category : 'instance creation' }
PCRE2CalloutAPI class >> newCallbackBackendFor: aCallback [
	"Pharo 11's, registering the callback with the worker of the process-local runner, which Pharo 11 asks the runner for as its forCallback."

	^ (TFCallback
		   forCallback: aCallback
		   parameters: (aCallback functionSpec arguments collect: #tfExternalTypeWithArity) asArray
		   returnType: aCallback functionSpec returnType tfExternalTypeWithArity
		   runner: aCallback ffiLibrary runner worker)
		  runStrategy: aCallback ffiLibrary callbackRunningStrategy;
		  yourself
]
