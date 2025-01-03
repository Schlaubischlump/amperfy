//
//  PlayerSettingsView.swift
//  Amperfy
//
//  Created by Maximilian Bauer on 15.09.22.
//  Copyright (c) 2022 Maximilian Bauer. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import SwiftUI
import AmperfyKit

struct PlayerSettingsView: View {
    
    @EnvironmentObject private var settings: Settings
    
    func updateBitrate() {
        appDelegate.player.streamingMaxBitrates = StreamingMaxBitrates(
            wifi: appDelegate.storage.settings.streamingMaxBitrateWifiPreference,
            cellular: appDelegate.storage.settings.streamingMaxBitrateCellularPreference)
    }
    
    func streamingMaxBitrateWifiNoLimit() {
        settings.streamingMaxBitrateWifiPreference = .noLimit
        updateBitrate()
    }
    func streamingMaxBitrateWifi32() {
        settings.streamingMaxBitrateWifiPreference = .limit32
        updateBitrate()
    }
    func streamingMaxBitrateWifi64() {
        settings.streamingMaxBitrateWifiPreference = .limit64
        updateBitrate()
    }
    func streamingMaxBitrateWifi96() {
        settings.streamingMaxBitrateWifiPreference = .limit96
        updateBitrate()
    }
    func streamingMaxBitrateWifi128() {
        settings.streamingMaxBitrateWifiPreference = .limit128
        updateBitrate()
    }
    func streamingMaxBitrateWifi192() {
        settings.streamingMaxBitrateWifiPreference = .limit192
        updateBitrate()
    }
    func streamingMaxBitrateWifi256() {
        settings.streamingMaxBitrateWifiPreference = .limit256
        updateBitrate()
    }
    func streamingMaxBitrateWifi320() {
        settings.streamingMaxBitrateWifiPreference = .limit320
        updateBitrate()
    }
    
    
    func streamingMaxBitrateCellularNoLimit() {
        settings.streamingMaxBitrateCellularPreference = .noLimit
        updateBitrate()
    }
    func streamingMaxBitrateCellular32() {
        settings.streamingMaxBitrateCellularPreference = .limit32
        updateBitrate()
    }
    func streamingMaxBitrateCellular64() {
        settings.streamingMaxBitrateCellularPreference = .limit64
        updateBitrate()
    }
    func streamingMaxBitrateCellular96() {
        settings.streamingMaxBitrateCellularPreference = .limit96
        updateBitrate()
    }
    func streamingMaxBitrateCellular128() {
        settings.streamingMaxBitrateCellularPreference = .limit128
        updateBitrate()
    }
    func streamingMaxBitrateCellular192() {
        settings.streamingMaxBitrateCellularPreference = .limit192
        updateBitrate()
    }
    func streamingMaxBitrateCellular256() {
        settings.streamingMaxBitrateCellularPreference = .limit256
        updateBitrate()
    }
    func streamingMaxBitrateCellular320() {
        settings.streamingMaxBitrateCellularPreference = .limit320
        updateBitrate()
    }
    
    
    func streamingFormatMp3() {
        settings.streamingFormatPreference = .mp3
    }
    func streamingFormatRaw() {
        settings.streamingFormatPreference = .raw
    }
    func streamingFormatServerConfig() {
        settings.streamingFormatPreference = .serverConfig
    }
    
    func cacheFormatMp3() {
        settings.cacheTranscodingFormatPreference = .mp3
    }
    func cacheFormatRaw() {
        settings.cacheTranscodingFormatPreference = .raw
    }
    func cacheFormatServerConfig() {
        settings.cacheTranscodingFormatPreference = .serverConfig
    }
    
    var body: some View {
        ZStack{
            SettingsList {
                SettingsSection {
                    SettingsCheckBoxRow(label: "Auto cache played Songs", isOn: $settings.isPlayerAutoCachePlayedItems)
                }
                
                SettingsSection(content: {
                    SettingsCheckBoxRow(label: "Scrobble streamed Songs", isOn: $settings.isScrobbleStreamedItems)
                }, footer: "Some server count streamed Songs already as played. When enabled, all streamed Songs are consistently scrobbled."
                )

                SettingsSection(content: {
                    SettingsCheckBoxRow(label: "Start audio playback only on explicit press on Play", isOn: $settings.isPlaybackStartOnlyOnPlay)
                }, footer:
                    "When enabled, audio playback starts only when the Play button is actively pressed. Otherwise, audio playback starts automatically."
                )

                SettingsSection(content: {
                    SettingsRow(title: "Max Bitrate for Streaming (WiFi)") {
                        Menu(settings.streamingMaxBitrateWifiPreference.description) {
                            Button(StreamingMaxBitratePreference.noLimit.description, action: streamingMaxBitrateWifiNoLimit)
                            Button(StreamingMaxBitratePreference.limit32.description, action: streamingMaxBitrateWifi32)
                            Button(StreamingMaxBitratePreference.limit64.description, action: streamingMaxBitrateWifi64)
                            Button(StreamingMaxBitratePreference.limit96.description, action: streamingMaxBitrateWifi96)
                            Button(StreamingMaxBitratePreference.limit128.description, action: streamingMaxBitrateWifi128)
                            Button(StreamingMaxBitratePreference.limit192.description, action: streamingMaxBitrateWifi192)
                            Button(StreamingMaxBitratePreference.limit256.description, action: streamingMaxBitrateWifi256)
                            Button(StreamingMaxBitratePreference.limit320.description, action: streamingMaxBitrateWifi320)
                        }
                    }
                }, footer:
                    "Lower bitrate saves bandwidth. This takes only affect when streaming and connected via WiFi."
                )

                SettingsSection(content: {
                    SettingsRow(title: "Max Bitrate for Streaming (Cellular)") {
                        Menu(settings.streamingMaxBitrateCellularPreference.description) {
                            Button(StreamingMaxBitratePreference.noLimit.description, action: streamingMaxBitrateCellularNoLimit)
                            Button(StreamingMaxBitratePreference.limit32.description, action: streamingMaxBitrateCellular32)
                            Button(StreamingMaxBitratePreference.limit64.description, action: streamingMaxBitrateCellular64)
                            Button(StreamingMaxBitratePreference.limit96.description, action: streamingMaxBitrateCellular96)
                            Button(StreamingMaxBitratePreference.limit128.description, action: streamingMaxBitrateCellular128)
                            Button(StreamingMaxBitratePreference.limit192.description, action: streamingMaxBitrateCellular192)
                            Button(StreamingMaxBitratePreference.limit256.description, action: streamingMaxBitrateCellular256)
                            Button(StreamingMaxBitratePreference.limit320.description, action: streamingMaxBitrateCellular320)
                        }
                    }
                }, footer:
                    "Lower bitrate saves bandwidth. This takes only affect when streaming and connected via Cellular."
                )
                
                SettingsSection(content: {
                    SettingsRow(title: "Streaming Format (Transcoding)") {
                        Menu(settings.streamingFormatPreference.description) {
                            Button(StreamingFormatPreference.mp3.description, action: streamingFormatMp3)
                            Button(StreamingFormatPreference.raw.description, action: streamingFormatRaw)
                            Button(StreamingFormatPreference.serverConfig.description, action: streamingFormatServerConfig)
                        }
                    }
                }, footer:
                    "Transcoding is recommended due to incompatibility with some formats. This takes only affect when streaming."
                )
                
                SettingsSection(content: {
                    SettingsRow(title: "Cache Format (Transcoding)") {
                        Menu(settings.cacheTranscodingFormatPreference.description) {
                            Button(CacheTranscodingFormatPreference.mp3.description, action: cacheFormatMp3)
                            Button(CacheTranscodingFormatPreference.raw.description, action: cacheFormatRaw)
                            Button(CacheTranscodingFormatPreference.serverConfig.description, action: cacheFormatServerConfig)
                        }
                    }
                }, footer:
                    "Transcoding is recommended due to incompatibility with some formats. Changes will not effect already downloaded songs, if this is wanted: Clear cache and redownload. \(((appDelegate.storage.loginCredentials?.backendApi ?? .ampache) == .ampache) ? "" : "\nIf cache format 'raw' is selected Amperfy will use the Subsonic API action 'download' for caching. Every other option requires Amperfy to use the Subsonic API action 'stream' for caching. Only 'stream' allows server side transcoding. Please check for correct server configuration regarding the active API action.")"
                )
            }
        }
        .navigationTitle("Player, Stream & Scrobble")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            appDelegate.userStatistics.visited(.settingsPlayer)
        }
    }
}

struct PlayerSettingsView_Previews: PreviewProvider {
    @State static var settings = Settings()
    
    static var previews: some View {
        PlayerSettingsView().environmentObject(settings)
    }
}
