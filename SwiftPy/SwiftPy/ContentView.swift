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
