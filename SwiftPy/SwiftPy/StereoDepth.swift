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
