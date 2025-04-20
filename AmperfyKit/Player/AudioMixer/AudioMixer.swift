//
//  AudiMixer.swift
//  Amperfy
//
//  Created by David Klopp on 20.04.25.
//  Copyright © 2025 Maximilian Bauer. All rights reserved.
//
import AVFoundation
import CoreAudio
import os.log

public class AudioMixer: NSObject {
  static func createAudioMix(
    track audioTrack: AVAssetTrack,
    audioProcessingChain: AudioProcessingChain
  )
    -> AVMutableAudioMix? {
    let audioMix = AVMutableAudioMix()
    let params = AVMutableAudioMixInputParameters(track: audioTrack)

    var callbacks = MTAudioProcessingTapCallbacks(
      version: kMTAudioProcessingTapCallbacksVersion_0,
      clientInfo: UnsafeMutableRawPointer(Unmanaged.passRetained(audioProcessingChain).toOpaque()),
      init: tapInit,
      finalize: tapFinalize,
      prepare: nil,
      unprepare: nil,
      process: tapProcess
    )
    var tap: Unmanaged<MTAudioProcessingTap>?
    let err = MTAudioProcessingTapCreate(
      kCFAllocatorDefault,
      &callbacks,
      kMTAudioProcessingTapCreationFlag_PostEffects,
      &tap
    )
    guard err == noErr else {
      os_log(.error, "Failed to create MTAudioProcessingTap: %s", err)
      return nil
    }

    params.audioTapProcessor = tap?.takeRetainedValue()
    audioMix.inputParameters = [params]
    return audioMix
  }

  // MARK: - Handler

  static let tapInit: MTAudioProcessingTapInitCallback = {
    tap, clientInfo, tapStorageOut in
    tapStorageOut.pointee = clientInfo
  }

  static let tapFinalize: MTAudioProcessingTapFinalizeCallback = {
    tap in
    let storage = MTAudioProcessingTapGetStorage(tap)
    let unmangedStorage = Unmanaged<AudioProcessingChain>.fromOpaque(storage)
    unmangedStorage.release()
  }

  static let tapProcess: MTAudioProcessingTapProcessCallback = {
    tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut in
    var timeRange = CMTimeRange.zero
    let status = MTAudioProcessingTapGetSourceAudio(
      tap,
      numberFrames,
      bufferListInOut,
      flagsOut,
      &timeRange,
      numberFramesOut
    )
    if status != noErr {
      os_log(.error, "MTAudioProcessingTap failed to get source: %s", status)
      return
    }
    let storage = MTAudioProcessingTapGetStorage(tap)
    let unmangedStorage = Unmanaged<AudioProcessingChain>.fromOpaque(storage)
    let audioProcessingChain = unmangedStorage.takeUnretainedValue()
    audioProcessingChain.process(timeRange: timeRange, bufferListInOut: bufferListInOut)
  }
}
