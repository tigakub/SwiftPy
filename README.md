# SwiftPy
Repo demonstrating how to embed a self-contained Python installation in a Swift app, and how to call Python from Swift, and how to callback up to C and or Swift from Python.

# Swift, Python and C Interop, and DepthAI, Too

# Introduction

Python is ubiquitous. There are so many open-source modules out there that embedding an interpreter in your app may allow you to incorporate sophisticated features with very little new coding.

Embedding Python has never been trivial, but Apple’s obsession with security, and its shift from Intel to Apple Silicon, has added another level of complexity to an already cumbersome process.

There is a piece of open source software out there that promises to make this easy: `[PythonKit](https://github.com/pvieito/PythonKit)`. I was at first unsuccessful when following the provided instructions, and it took me quite a lot of experimentation and trial and error to discover the correct procedure.

In this tutorial, I delineate the exact steps I took to successfully embedded the Python interpreter in a  Swift app using Xcode.

# Prerequisite

I am assuming that readers will already have a working installation of Python, and will not be going over how to install Python, or set up a virtual environment. It doesn’t really matter what version it is, as long as you know the path to the base folder. For my case, I decided to try to embed Python3.10, after installing it in its own anaconda environment. I also installed NumPy and DepthAI, as a test to see if I could embed third-party modules as well.

# Configuring a New Xcode Project

Create a new Swift package in Xcode.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/e51a46da-cf04-4ccc-9ac7-1de6e385a73d/Untitled.png)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/79b43f93-a591-44a1-922a-ff2811f3272a/Untitled.png)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/8f740eb1-9db9-4722-a20e-945a34bf5826/Untitled.png)

# Add PythonKit Package Dependency

Select `Xcode→File→Add Packages` (I’m using Xcode 14.2 (14C18). Older versions may have different menu layouts.)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/d2f79988-edbf-4d99-80e3-98dc2948a9cc/Untitled.png)

In the search field in the upper right of the next dialog, type in the PythonKit git repo URL: [https://github.com/pvieito/PythonKit.git](https://github.com/pvieito/PythonKit.git). The search should return PythonKit in the columns below. Click on the PythonKit logo to select it, and hit `Add Package`.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/7eb6fb73-3d5b-4154-ae5f-ff3ebc86b2a0/Untitled.png)

# Embed Your System Python Installation

The Python3.10 installation I want to embed is located at the following path on my Mac.

```bash
/opt/homebrew/Caskroom/miniconda/base/envs/py310
```

That folder contains the following subfolders.

```bash
bin		include		man		ssl
conda-meta	lib		share
```

Drag the entire folder from the Finder into your project at the root level. The safest is to drag it on to the project root, or between the project root and the first entry below it. This ensures that the group is created at the right level, so that Xcode will automatically pick it up as a bundle resource to be copied into your app.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/da51fa1d-966d-403a-87a9-f0a005ac081a/Untitled.png)

Check `Copy items into destination group’s folder (if needed)`. (You could uncheck this, and then Xcode will pull in the system’s install of Python, in its current state at the time you build your app.)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/1f4bb9b3-c15e-4649-a98f-479fc8131b39/Untitled.png)

If successful, the new group will be listed under `Build Phases`→`Copy Bundle Resources`.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/869c9d5c-9be2-4be3-b9d4-6b650d575130/Untitled.png)

# Get Xcode to Automatically Codesign the Binaries in the Embedded Python Library

App Sandboxing and Hardened Runtime require that any binary code be codesigned before it can be loaded and executed. Here’s a script that will recursively codesign all shared, static, and dynamic libraries, as well as any mach executables in the embedded Python.

Still in the `Build Phases` pane, of the project settings, click on the small plus (indicated below), and select `New Run Script Phase`.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/2c519e4a-e487-4b56-b2ef-e953c91c942f/Untitled.png)

Expand the `Run Script` phase and in the provided text box, enter the following script. Uncheck `Base on dependency analysis` to ensure the script is run as the last phase in every build.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/2e6177a6-344e-4d50-80df-e58b903b5e1c/Untitled.png)

```bash
set -e

echo "Codesigning all embedded executables in $CODESIGNING_FOLDER_PATH/Contents/Resources/py310/bin"
find "$CODESIGNING_FOLDER_PATH/Contents/Resources/py310/bin/" -perm +0444 -type f -exec /usr/bin/codesign -s "$EXPANDED_CODE_SIGN_IDENTITY" -fv -o runtime --timestamp=none --preserve-metadata=identifier,entitlements,flags --generate-entitlement-der {} \;

echo "Codesigning all embedded shared libraries in $CODESIGNING_FOLDER_PATH/Contents/Resources/py310/"
find "$CODESIGNING_FOLDER_PATH/Contents/Resources/py310/" -name "*.so" -exec /usr/bin/codesign -s "$EXPANDED_CODE_SIGN_IDENTITY" -fv -o runtime --timestamp=none --preserve-metadata=identifier,entitlements,flags --generate-entitlement-der {} \;

echo "Codesigning all embedded static libraries in $CODESIGNING_FOLDER_PATH/Contents/Resources/py310/"
find "$CODESIGNING_FOLDER_PATH/Contents/Resources/py310/" -name "*.a" -exec /usr/bin/codesign -s "$EXPANDED_CODE_SIGN_IDENTITY" -fv -o runtime --timestamp=none --preserve-metadata=identifier,entitlements,flags --generate-entitlement-der {} \;

echo "Codesigning all embedded dynamic libraries in $CODESIGNING_FOLDER_PATH/Contents/Resources/py310/"
find "$CODESIGNING_FOLDER_PATH/Contents/Resources/py310/" -name "*.dylib" -exec /usr/bin/codesign -s "$EXPANDED_CODE_SIGN_IDENTITY" -fv -o runtime --timestamp=none --preserve-metadata=identifier,entitlements,flags --generate-entitlement-der {} \;
```

# Define a New Class to Expose Python to Swift

Hit ⌘N for a new file.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/10887486-9268-43ab-952d-cdeb4e05c2cd/Untitled.png)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/2e095657-d80c-49a4-8d84-478c0a1f3455/Untitled.png)

Enter the following Swift. If you do not have `DepthAI` or `NumPy` installed, remove the references to them from the code.

```swift
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
				// CRITICAL: this must be done BEFORE starting Python
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
}
```

Modify your main app class as follows (boilerplate in purple, modifications in orange).

```swift
//
//  SwiftPyApp.swift
//  SwiftPy
//
//  Created by Edward Janne on 1/12/23.
//

import SwiftUI

@main
struct SwiftPyApp: App {
    @StateObject var mp = EmbeddedPython()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    mp.printPythonInfo()
                }
        }
    }
}
```

Now hit ⌘R to build and run, and you should see the default Hello World window, and information about the embedded Python installation will scroll in the Xcode console.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/a46a9730-5893-4196-87a3-ebf8e11fa214/Untitled.png)

# Depth Telemetry from an OAK-D via Python

Start a new file entitled `StereoDepth.swift`.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/53b2f3a1-1cea-4ad5-a8d6-a4b255f59334/Untitled.png)

Enter the following code.

```swift
//
//  StereoDepth.swift
//  SwiftPy
//
//  Created by Edward Janne on 1/12/23.
//

import Foundation

import PythonKit

class StereoDepth: NSObject, ObservableObject {
    
    var mp: EmbeddedPython
    var pipeline: PythonObject
    var monoLeft: PythonObject
    var monoRight: PythonObject
    var depth: PythonObject
    var xout: PythonObject
    var device: PythonObject
    var depthQueue: PythonObject
    
    init(in embeddedPython: EmbeddedPython) {
        mp = embeddedPython
        
        // Get a reference to the DepthAI pipeline
        pipeline = mp.dai.Pipeline()
        
        // Create nodes for the left mono, and right mono cameras
        // a StereoDepth node, and an output node
        monoLeft = pipeline.create(mp.dai.node.MonoCamera)
        monoRight = pipeline.create(mp.dai.node.MonoCamera)
        depth = pipeline.create(mp.dai.node.StereoDepth)
        xout = pipeline.create(mp.dai.node.XLinkOut)
        
        // Set the output stream id
        xout.setStreamName("disparity")
        
        // Configure the camera nodes, and attach them to the
        // respective hardware
        monoLeft.setResolution(mp.dai.MonoCameraProperties.SensorResolution.THE_400_P)
        monoLeft.setBoardSocket(mp.dai.CameraBoardSocket.LEFT)
        monoRight.setResolution(mp.dai.MonoCameraProperties.SensorResolution.THE_400_P)
        monoRight.setBoardSocket(mp.dai.CameraBoardSocket.RIGHT)
        
        // Configure the StereoDepth node
        depth.setDefaultProfilePreset(mp.dai.node.StereoDepth.PresetMode.HIGH_DENSITY)
        depth.initialConfig.setMedianFilter(mp.dai.MedianFilter.KERNEL_7x7)
        depth.setLeftRightCheck(true)
        depth.setExtendedDisparity(false)
        depth.setSubpixel(false)
        
        // Connect the nodes
        monoLeft.out.link(depth.left)
        monoRight.out.link(depth.right)
        depth.disparity.link(xout.input)
        
        // Get a reference to the device
        device = mp.dai.Device(pipeline)
        
        // Get a reference to the output queue
        depthQueue = device.getOutputQueue(name: "disparity", maxSize: 4, blocking: false)
        
        super.init()
    }
}
```

Modify ContentView class as follows

```swift
//
//  ContentView.swift
//  SwiftPy
//
//  Created by Edward Janne on 1/12/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var stereoDepth: StereoDepth
    
    // Thread to poll OAK-D for telemetry
    var serialQueue = DispatchQueue(label: "Depth thread")
    
    // State variables to hold information about the telemetry
    @State var type: String = ""        // The data format of the telemetry
    @State var frameWidth: Int = 0      // The frame width
    @State var frameHeight: Int = 0     // The frame height
    @State var depthImage = NSImage()   // An image containing the depth information
    
    var body: some View {
        VStack {
            Text("\(type) \(frameWidth), \(frameHeight)")
            Image(nsImage: depthImage)
        }
            .onAppear {
                // Initiate new thread of execution
                depthLoop()
            }
            .padding()
    }
    
    // Recursive function to poll DepthAI for frames
    func depthLoop() {
        // Schedule task on serial queue
        serialQueue.asyncAfter(deadline: .now() + .milliseconds(33)) {
            // Get the next available image frame
            let imgFrame = stereoDepth.depthQueue.get()
            // Get the data
            let imgData = imgFrame.getData()
            // Get the data format
            let frameType = imgFrame.getType()
            
            // Set the display state
            type = String(frameType.name)!
            frameWidth = Int(imgFrame.getWidth())!
            frameHeight = Int(imgFrame.getHeight())!
            
            // Convert the DepthAI ImgFrame into an NSImage
            // for diplay
            if let array = Array<UInt8>(imgData) {
                // Encapsulate image in a Swift Data object
                let imgData = Data(bytes: array, count: array.count)
                // Create a core image from the data
                let ciImage = CIImage(
                    bitmapData: imgData,
                    bytesPerRow: frameWidth,
                    size: CGSizeMake(CGFloat(frameWidth), CGFloat(frameHeight)),
                    format: .L8,
                    colorSpace: CGColorSpace(name: CGColorSpace.extendedLinearGray))
                // Create an NSImageRep from the core image
                let ciRep = NSCIImageRep(ciImage: ciImage)
                // Create an NSImage
                depthImage = NSImage(size: NSMakeSize(CGFloat(frameWidth), CGFloat(frameHeight)))
                // And set its representation
                depthImage.addRepresentation(ciRep)
            }
            
            // Schedule the next iteration
            self.depthLoop()
        }
    }
}
```

Modify the SwiftPyApp class as follows.

```swift
//
//  SwiftPyApp.swift
//  SwiftPy
//
//  Created by Edward Janne on 1/12/23.
//

import SwiftUI

@main
struct SwiftPyApp: App {
    @StateObject var mp = EmbeddedPython()
    
    var body: some Scene {
        WindowGroup {
            ContentView(stereoDepth: StereoDepth(in: mp))
                .onAppear {
                    mp.printPythonInfo()
                }
        }
    }
}
```

One last thing: entitle the app to access the OAK-D.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/55b32070-c7fd-4dbb-ac77-0d8690be823a/Untitled.png)

Hit ⌘R to build and run.

[oakd_stereodepth_python_embedded.mov](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/c7398858-fa3f-4f1a-858c-125e6f8b860d/oakd_stereodepth_python_embedded.mov)

# Calling C from Python

You cannot call Swift directly from Python. But you can call compiled C functions, and a C module can be written as a wrapper around Objective C, which is toll-free bridged to Swift, which means that with a little indirection, you can call Swift closures from Python.

The basic procedure here is to create a compiled C function, wrap it in a Python module, and add the module to Python’s table of built-in modules.

### Configure the project

We need to tell Xcode to link against `libpython3.10.dylib` found in the embedded Python installation. 

Select the project root in the Project Navigator, select your app target, and the `General` tab.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/a49da1ac-95b4-474e-8bf2-2fba39b53c86/Untitled.png)

In the Project Navigator, expand `py310`→`lib`.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/f3c4d12e-3575-445a-bbd6-c30714e478b3/Untitled.png)

Scroll down to expose `libpython3.10.dylib`, and drag it into the `Frameworks, Libraries, and Embedded Content` list, but set it to `Do Not Embed`.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/da6d2309-69e5-4de7-8f41-dc25545f4e11/Untitled.png)

Expand `py310`→`include`→`python3.10` in the Project Navigator.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/14cb226c-2dbd-4a99-9fb7-89b2169c9a4f/Untitled.png)

Scroll down to expose the `Python.h` header file. Right-click it and select `Show in Finder`.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/5615979c-4cdd-4b5a-bc95-662e7cf3fba8/Untitled.png)

In the Finder, hit ⌘I to bring up the file info window.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/40727f0e-c028-4d67-a47a-7dfe5fea8000/Untitled.png)

Highlight the path to this file, and hit ⌘C.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/bfc5d912-a49a-4d28-8586-cbf305db4906/Untitled.png)

Go to the Build Settings tab in your project settings, and scroll down to `Search Paths` section. Double click the empty space beside `Header Search Paths`, and then hit the + button.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/43fa15ba-483d-472c-995c-d5ea452b471d/Untitled.png)

Paste in the path copied from the Finder info window. This tells Xcode to look here for the `Python.h` header file.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/122de537-4d90-44a8-9c9f-5455f9ee5c74/Untitled.png)

Replace the hard path with a soft one like so:

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/eb694ed7-baa1-48f2-962e-f9261b69a96e/Untitled.png)

Click on the value field for `Library Search Paths` (right below `Header Search Paths`), and ensure that Xcode knows where to look for `libpython3.10.dylib`.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/b6135f9b-d673-428b-8317-801ebce262b1/Untitled.png)

In the `Build Phases` tab, modify the script in the `Run Script` phase as follows.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/3c34e3e2-01b1-4d12-b3ea-388fb7beb8f2/Untitled.png)

This creates a symbolic link in the final product’s `Frameworks` folder, to `libpython3.10.dylib`, which is buried in the `Resource` fork. This enables the app to load the library at runtime. It is shared with PythonKit, which invokes Python by calling down into this same library. But we also have to link against it so that we can make use of the Python C API for our own purposes.

```bash
set -e

echo "Create Frameworks folder if it doesn't exist."
[ ! -d "$CODESIGNING_FOLDER_PATH/Contents/Frameworks" ] && mkdir "$CODESIGNING_FOLDER_PATH/Contents/Frameworks"

echo "Create soft link, if one does not exist, to libpython3.10.dylib in the target's Frameworks folder."
[ ! -f "$CODESIGNING_FOLDER_PATH/Contents/Frameworks/libpython3.10.dylib" ] && ln -s "$CODESIGNING_FOLDER_PATH/Contents/Resources/py310/lib/libpython3.10.dylib" "$CODESIGNING_FOLDER_PATH/Contents/Frameworks/libpython3.10.dylib"

echo "Codesigning all embedded executables in $CODESIGNING_FOLDER_PATH/Contents/Resources/py310/bin"
find "$CODESIGNING_FOLDER_PATH/Contents/Resources/py310/bin/" -perm +0444 -type f -exec /usr/bin/codesign -s "$EXPANDED_CODE_SIGN_IDENTITY" -fv -o runtime --timestamp=none --preserve-metadata=identifier,entitlements,flags --generate-entitlement-der {} \;

echo "Codesigning all embedded shared libraries in $CODESIGNING_FOLDER_PATH/Contents/Resources/py310/"
find "$CODESIGNING_FOLDER_PATH/Contents/Resources/py310/" -name "*.so" -exec /usr/bin/codesign -s "$EXPANDED_CODE_SIGN_IDENTITY" -fv -o runtime --timestamp=none --preserve-metadata=identifier,entitlements,flags --generate-entitlement-der {} \;

echo "Codesigning all embedded static libraries in $CODESIGNING_FOLDER_PATH/Contents/Resources/py310/"
find "$CODESIGNING_FOLDER_PATH/Contents/Resources/py310/" -name "*.a" -exec /usr/bin/codesign -s "$EXPANDED_CODE_SIGN_IDENTITY" -fv -o runtime --timestamp=none --preserve-metadata=identifier,entitlements,flags --generate-entitlement-der {} \;

echo "Codesigning all embedded dynamic libraries in $CODESIGNING_FOLDER_PATH/Contents/Resources/py310/"
find "$CODESIGNING_FOLDER_PATH/Contents/Resources/py310/" -name "*.dylib" -exec /usr/bin/codesign -s "$EXPANDED_CODE_SIGN_IDENTITY" -fv -o runtime --timestamp=none --preserve-metadata=identifier,entitlements,flags --generate-entitlement-der {} \;
```

### Create a Python Extension group in your project

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/2d912009-79f6-41d5-a088-3a9febb29466/Untitled.png)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/8390a7ae-69d7-49b4-993a-58b2dd602412/Untitled.png)

### Create a new C source file

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/968c279f-29d0-4379-9b08-ad83b689c008/Untitled.png)

Let’s name it `TestModule`. Ensure that `Also create a header file` is checked.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/de721bb4-7cb9-4e43-be4b-30bf308b740c/Untitled.png)

Xcode will ask you if you want a bridging header. This exposes the C/Objective-C binaries to Swift. So click `Create Bridging Header`.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/bcc97d7f-5560-4a3e-a395-90caacbef186/Untitled.png)

In the TestModule.h header, enter the following.

```c
//
//  TestModule.h
//  SwiftPy
//
//  Created by Edward Janne on 1/13/23.
//

#ifndef TestModule_h
#define TestModule_h

#include <stdio.h>

void setUpTestModule(void);

#endif /* TestModule_h */
```

And the following in TestModule.c.

```c
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
```

Include `TestModule.h,` as well as `Python.h` in the bridging header.

```c
//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include "TestModule.h"
#include "Python.h"
```

### Add your custom module to Python

In the `EmbeddedPython.swift` file, call `setUpTestModule()`. This must be called before Python is first invoked. And add a function that calls `PyRun_SimpleString()`, to execute a string as a Python script. The script imports the `Test` module, and calls `printHello()`.

```swift
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
}
```

In `SwiftPyApp.swift`, add a line to invoke `callPrintHello()`.

```swift
//
//  SwiftPyApp.swift
//  SwiftPy
//
//  Created by Edward Janne on 1/12/23.
//

import SwiftUI

@main
struct SwiftPyApp: App {
    @StateObject var mp = EmbeddedPython()
    
    var body: some Scene {
        WindowGroup {
            ContentView(stereoDepth: StereoDepth(in: mp))
                .onAppear {
                    mp.printPythonInfo()
                    mp.callPrintHello()
                }
        }
    }
}
```

### Hit ⌘R to Run.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/b6d25edb-1ca9-462b-a930-387e1d2c0c65/Untitled.png)

# Calling Swift from Python

It’s convoluted, but there are probably use cases out there for calling back into Swift code from Python.

The basic idea is to encapsulate a Swift closure in an Objective-C class, and then wrap the Objective-C in regular C which can then be called from Python.

### Create the Objective-C class

Hit ⌘N for a new `Header File`.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/f0816d02-df4b-48f0-8bbd-37b4c654f583/Untitled.png)

Name it `MTestModue.h`.

Paste the following into the header.

```objectivec
//
//  MTestModule.h
//  SwiftPy
//
//  Created by Edward Janne on 1/13/23.
//

#ifndef MTestModule_h
#define MTestModule_h

#import <Foundation/Foundation.h>

// Creates module and installs it in Python's table of built-in modules
void setUpMTestModule(void (^closure)(void));

// Performs clean up
void tearDownMTestModule(void);

// Objective C class to encapsulate a Swift closure
@interface MTestModule: NSObject {
}

// Constructor which takes a closure as an argument
- (id) init: (void (^)(void)) iClosure;

// Message which invokes the encapsulated closure
- (void) callback;

@end

#endif /* MTestModule_h */
```

Hit ⌘N again. This time select `Objective-C.`

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/4d8e02fb-9b45-4722-aa7a-4e9f6e410b33/Untitled.png)

Name it `MTestModule.m`.

Paste the following into it.

```objectivec
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
```

In the bridging header, include `MTestModule.h.`

```c
//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include "TestModule.h"
#include "MTestModule.h"
#include "Python.h"
```

### Update Swift Code to Add `MTestModule` to Python

In the EmbeddedPython.swift file, make the following additions.

```swift
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
```

Then in SwiftPyApp.swift, invoke `MTestModule.callCallback()`.

```swift
//
//  SwiftPyApp.swift
//  SwiftPy
//
//  Created by Edward Janne on 1/12/23.
//

import SwiftUI

@main
struct SwiftPyApp: App {
    @StateObject var mp = EmbeddedPython()
    
    var body: some Scene {
        WindowGroup {
            ContentView(stereoDepth: StereoDepth(in: mp))
                .onAppear {
                    mp.printPythonInfo()
                    mp.callPrintHello()
                    mp.callCallback()
                }
        }
    }
}
```

Hit ⌘R, to see this in action.
