//
//  AudioProcessingNode.swift
//  Amperfy
//
//  Created by David Klopp on 20.04.25.
//  Copyright © 2025 Maximilian Bauer. All rights reserved.
//
import Accelerate
import AVFoundation
import CoreAudio
import CoreMedia

// MARK: - AudioProcessingNode

public protocol AudioProcessingNode: AnyObject {
  func process(timeRange: CMTimeRange, bufferListInOut: UnsafeMutablePointer<AudioBufferList>)
}

// MARK: - VolumenProcessing

// Update volume of audio track in realtime
public class VolumenProcessing: NSObject, AudioProcessingNode {
  private var volume: Float

  init(measuredDb: Float) {
    let targetDb: Float = -16.0
    let gainDb = targetDb - measuredDb
    self.volume = pow(10.0, gainDb / 20.0)
  }

  public func process(
    timeRange: CMTimeRange,
    bufferListInOut: UnsafeMutablePointer<AudioBufferList>
  ) {
    let bufferList = UnsafeMutableAudioBufferListPointer(bufferListInOut)
    for bufferIndex in 0 ..< bufferList.count {
      let audioBuffer = bufferList[bufferIndex]
      if let rawBuffer = audioBuffer.mData {
        let floatRawPointer = rawBuffer.assumingMemoryBound(to: Float.self)
        let frameCount = UInt(audioBuffer.mDataByteSize) / UInt(MemoryLayout<Float>.size)
        vDSP_vsmul(floatRawPointer, 1, &volume, floatRawPointer, 1, frameCount)
      }
    }
  }
}
