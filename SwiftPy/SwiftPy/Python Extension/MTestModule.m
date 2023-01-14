//
//  MTestModule.m
//  SwiftPy
//
//  Created by Edward Janne on 1/13/23.
//

#import <Foundation/Foundation.h>

#import "MTestModule.h"

#include "Python.h"

MTestModule *gTestModule = NULL;

// Function to expose to Python
// (MUST HAVE THIS SIGNATURE, i.e. return type, and parameter list)
PyObject *callback(PyObject *self, PyObject *args) {
    // Send MTestModule the callback message
    if(gTestModule) [gTestModule callback];
    return Py_None;
}

// Method definition (MUST BE GLOBAL)
PyMethodDef mMethods[] = {
    { "callback", callback, METH_VARARGS, "Calls swift closure" },
    { NULL, NULL, 0, NULL }
};

// Module definition (MUST BE GLOBAL)
PyModuleDef mModuleDef = {
    PyModuleDef_HEAD_INIT,
    "MTest",
    "Module exposing custom Swift API",
    -1,
    mMethods,
    NULL,
    NULL,
    NULL,
    NULL
};

// Function to create a Python module from the definition
PyMODINIT_FUNC createMTestModule(void) {
    PyObject *module = PyModule_Create(&mModuleDef);
    
    return module;
}

// Instantiates an MTestModule at the global scope, passing
// it a closure.
// Appends the module to Python's table of built-in modules
void setUpMTestModule(void (^iClosure)(void)) {
    if(!gTestModule) {
        gTestModule = [[MTestModule alloc] init: iClosure];
    }
    PyImport_AppendInittab("MTest", &createMTestModule);
}

// Performs clean up
void tearDownMTestModule(void) {
    // Autoreference counting will free allocations
    // Not strictly necessary, but good practice
    gTestModule = nil;
}

// Implementation of Objective C class
@implementation MTestModule {
    // Private member to store a closure
    void (^closure)(void);
}

// Constructor
- (id) init: (void (^)(void)) iClosure {
    if(self = [super init]) {
        // Initialize private member
        self->closure = iClosure;
    }
    return self;
}

// Callback message
- (void) callback {
    // Invoke the closure
    self->closure();
}

@end
