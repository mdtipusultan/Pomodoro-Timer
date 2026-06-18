import AudioToolbox
import AVFoundation
import Foundation
import Observation

@Observable
@MainActor
final class SoundService {
    private var players: [String: AVAudioPlayer] = [:]

    var timerEndSoundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "timerEndSound") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "timerEndSound") }
    }

    var breakSoundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "breakSound") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "breakSound") }
    }

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func playSessionStart() {
        playSystemSound(1053)
    }

    func playSessionComplete() {
        guard timerEndSoundEnabled else { return }
        playSystemSound(1057)
    }

    func playSessionFailed() {
        guard timerEndSoundEnabled else { return }
        playSystemSound(1073)
    }

    func playBreakStart() {
        guard breakSoundEnabled else { return }
        playSystemSound(1054)
    }

    func playPurr() {
        playSystemSound(1104)
    }

    func playTick() {
        playSystemSound(1103)
    }

    private func playSystemSound(_ soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }

    private func playBundledSound(named name: String, ext: String = "mp3") {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources/Sounds") else {
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            players[name] = player
        } catch {}
    }
}
