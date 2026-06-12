//
//  ReconocedorVoz.swift
//  FinEdu
//
//  Dictado por voz para escribir decisiones hablando, reforzando el núcleo
//  de la app: aprender contándole al agente. Usa SFSpeechRecognizer con
//  reconocimiento ON-DEVICE cuando el dispositivo lo soporta (coherente con
//  el principio "100% on-device, sin red" de FinEdu) y AVAudioEngine para
//  capturar el micrófono.
//

import Foundation
import Speech
import AVFoundation
import Observation

@MainActor
@Observable
final class ReconocedorVoz {

    /// Texto transcrito en vivo (parciales incluidos).
    private(set) var transcripcion = ""
    /// Si estamos capturando audio ahora mismo.
    private(set) var grabando = false
    /// false si faltan permisos o el dispositivo no puede reconocer voz.
    private(set) var disponible = true

    private let reconocedor = SFSpeechRecognizer(locale: Locale(identifier: "es_MX"))
    private let motorAudio = AVAudioEngine()
    private var solicitud: SFSpeechAudioBufferRecognitionRequest?
    private var tarea: SFSpeechRecognitionTask?

    /// Inicia la captura. Pide permisos la primera vez.
    func iniciar() async {
        guard !grabando else { return }
        guard await pedirPermisos() else { disponible = false; return }
        guard let reconocedor, reconocedor.isAvailable else { disponible = false; return }

        do {
            try configurarSesionAudio()

            let solicitud = SFSpeechAudioBufferRecognitionRequest()
            solicitud.shouldReportPartialResults = true
            // On-device cuando el sistema lo soporta: privacidad y cero red.
            solicitud.requiresOnDeviceRecognition = reconocedor.supportsOnDeviceRecognition
            self.solicitud = solicitud

            let entrada = motorAudio.inputNode
            let formato = entrada.outputFormat(forBus: 0)
            entrada.installTap(onBus: 0, bufferSize: 1024, format: formato) { buffer, _ in
                solicitud.append(buffer)
            }
            motorAudio.prepare()
            try motorAudio.start()

            transcripcion = ""
            grabando = true
            disponible = true

            tarea = reconocedor.recognitionTask(with: solicitud) { [weak self] resultado, error in
                guard let self else { return }
                Task { @MainActor in
                    if let resultado {
                        self.transcripcion = resultado.bestTranscription.formattedString
                    }
                    if error != nil || (resultado?.isFinal ?? false) {
                        self.detener()
                    }
                }
            }
        } catch {
            disponible = false
            detener()
        }
    }

    /// Detiene la captura y libera el micrófono.
    func detener() {
        guard grabando || motorAudio.isRunning else { return }
        motorAudio.stop()
        motorAudio.inputNode.removeTap(onBus: 0)
        solicitud?.endAudio()
        tarea?.cancel()
        solicitud = nil
        tarea = nil
        grabando = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func configurarSesionAudio() throws {
        let sesion = AVAudioSession.sharedInstance()
        try sesion.setCategory(.record, mode: .measurement, options: .duckOthers)
        try sesion.setActive(true, options: .notifyOthersOnDeactivation)
    }

    /// Pide autorización de reconocimiento de voz y de micrófono.
    private func pedirPermisos() async -> Bool {
        let vozAutorizada = await withCheckedContinuation { continuacion in
            SFSpeechRecognizer.requestAuthorization { estado in
                continuacion.resume(returning: estado == .authorized)
            }
        }
        guard vozAutorizada else { return false }

        return await withCheckedContinuation { continuacion in
            AVAudioApplication.requestRecordPermission { concedido in
                continuacion.resume(returning: concedido)
            }
        }
    }
}
