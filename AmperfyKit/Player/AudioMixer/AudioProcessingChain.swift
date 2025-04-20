//
//  AudioProcessingChain.swift
//  Amperfy
//
//  Created by David Klopp on 20.04.25.
//  Copyright © 2025 Maximilian Bauer. All rights reserved.
//
import CoreMedia

public class AudioProcessingChain: NSObject {
  public let nodes: [AudioProcessingNode]

  init(nodes: [any AudioProcessingNode] = []) {
    self.nodes = nodes
  }

  public func process(
    timeRange: CMTimeRange,
    bufferListInOut: UnsafeMutablePointer<AudioBufferList>
  ) {
    nodes.forEach { node in
      node.process(timeRange: timeRange, bufferListInOut: bufferListInOut)
    }
  }
}
