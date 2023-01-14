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
