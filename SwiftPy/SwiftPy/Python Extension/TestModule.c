//
//  TestModule.c
//  SwiftPy
//
//  Created by Edward Janne on 1/13/23.
//

#include "TestModule.h"

#include "Python.h"

// Function to expose to Python
// (MUST HAVE THIS SIGNATURE, i.e. return type, and parameter list)
PyObject *printHello(PyObject *self, PyObject *args) {
    printf("Hello world\n");
    return Py_None;
}

// Method definition (MUST BE GLOBAL)
PyMethodDef methods[] = {
    { "printHello", printHello, METH_NOARGS, "Prints hello" },
    { NULL, NULL, 0, NULL }
};

// Module definition (MUST BE GLOBAL)
PyModuleDef moduleDef = {
    PyModuleDef_HEAD_INIT,
    "Test",
    "Module exposing custom API",
    -1,
    methods,
    NULL,
    NULL,
    NULL,
    NULL
};

// Function to create a Python module from the definition
PyMODINIT_FUNC createModule(void) {
    PyObject *module = PyModule_Create(&moduleDef);
    
    return module;
}

// Appends the module to Python's table of built-in modules
void setUpTestModule(void) {
    PyImport_AppendInittab("Test", &createModule);
}
