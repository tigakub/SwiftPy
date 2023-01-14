//
//  EmbeddedPython.swift
//  SwiftPy
//
//  Created by Edward Janne on 1/12/23.
//

import Foundation

import PythonKit

class EmbeddedPython: NSObject, ObservableObject {
    var os: PythonObject
    var sys: PythonObject
    var math: PythonObject
    var np: PythonObject
    var dai: PythonObject
    
    // Start a new Python context, and load modules
    override init() {
        // Path to current working directory
        let bundlePath = Bundle.main.bundlePath
        
        //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        // CRITICAL: this must be done BEFORE starting starting Python
        //
        // PythonLibrary.useLibrary sets the PYTHON_LIBRARY environment
        // variable which tells PythonKit the path to the libpython
        // dynamic library to load.
        //
        // The setenv line sets the PYTHONHOME environment variable which
        // tells PythonKit the base path to the embedded Python
        // installation.
        //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				
        // Configure PythonKit to use the specified Python library binary
        PythonLibrary.useLibrary(at: "\(bundlePath)/Contents/Resources/py310/lib/libpython3.10.dylib")
        
        // Set the path to the root directory of the embedded Python installation
        setenv("PYTHONHOME", "\(bundlePath)/Contents/Resources/py310/", 1)
        
        // Set up module to test calling a C function from Python
        setUpTestModule()
        
        // Set up module to test calling a Swift closure from Python
        setUpMTestModule {
            print("Hello, world, from a Swift closure, called from Python via PythonKit, C, and Objective C")
        }
        
        // Load desired Python modules
        os = Python.import("os")
        sys = Python.import("sys")
        math = Python.import("math") // verifies `lib-dynload` is found and signed successfully
        np = Python.import("numpy")
        dai = Python.import("depthai")
        
        /*
            The above is equivalent to the below Python script
            
            import os
            import sys
            import math
            import numpy as np
            import depthai as dai
        */
        
        super.init()
    }
    
    deinit {
        // Clean up
        tearDownMTestModule()
    }
    
    // Print out Python information
    func printPythonInfo() {
        print("Python environment: \(os.environ)")
        print("Python Version: \(sys.version_info.major).\(sys.version_info.minor)")
        print("Python Encoding: \(sys.getdefaultencoding().upper())")
        print("Python Path: \(sys.path)")
        print("Python executable: \(sys.executable)")
        print("NumPy Version: \(np.__version__)")
        print("DepthAI Version: \(dai.__version__)")
    }
    
    // Call function in TestModule
    func callPrintHello() {
        PyRun_SimpleString(
            """
            import Test
            
            Test.printHello()
            """
        )
    }
    
    
    // Call function in MTestModule
    func callCallback() {
        PyRun_SimpleString(
            """
            import MTest
            
            MTest.callback()
            """
        )
    }
}

