//
//  TarjetasMensaje.swift
//  FinEdu
//
//  Tarjetas de la conversación del juego (estilo interactive fiction).
//  Accesibilidad: cada tarjeta agrupa sus elementos (.combine) para que
//  VoiceOver la lea como una sola unidad coherente, y todos los textos usan
//  fuentes dinámicas (Dynamic Type) — nunca tamaños fijos.
//

import SwiftUI

/// Despachador: dibuja el tipo de mensaje que corresponda.
struct MensajeView: View {
    let mensaje: MensajeJuego
    let simboloMoneda: String
    /// Callback para cuando el jugador elige una opción. Solo se pasa al
    /// ÚLTIMO mensaje de tipo .opciones (los anteriores quedan desactivados).
    var onSeleccionarOpcion: ((String) -> Void)? = nil

    var body: some View {
        switch mensaje.contenido {
        case .sistema(let texto):
            TarjetaSistema(texto: texto)
        case .contexto(let texto):
            TarjetaContexto(texto: texto)
        case .evento(let turno):
            TarjetaEvento(turno: turno)
        case .decisionUsuario(let texto):
            BurbujaDecision(texto: texto)
        case .resultado(let resultado):
            TarjetaResultado(resultado: resultado)
        case .pedirReintento(let mensaje):
            TarjetaPedirReintento(mensaje: mensaje)
        case .opciones(let opciones):
            TarjetaOpciones(opciones: opciones, onSeleccionar: onSeleccionarOpcion)
        }
    }
}

/// Texto narrativo del sistema (contexto inicial, cierre).
struct TarjetaSistema: View {
    let texto: String

    var body: some View {
        Text(texto)
            .font(.callout)
            .italic()
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
            .accessibilityLabel("Narrador: \(texto)")
    }
}

/// Contexto histórico de la crisis, oculto tras un botón "Más información"
/// para no saturar de texto el inicio del juego: el foco es aprender
/// decidiendo, no leyendo. El texto completo se abre en una hoja a demanda.
struct TarjetaContexto: View {
    let texto: String
    @State private var mostrarContexto = false

    var body: some View {
        Button {
            mostrarContexto = true
        } label: {
            Label("Más información", systemImage: "info.circle")
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.tint.opacity(0.3)))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
        .accessibilityLabel("Más información sobre esta crisis")
        .accessibilityHint("Abre el contexto histórico de la crisis")
        .sheet(isPresented: $mostrarContexto) {
            NavigationStack {
                ScrollView {
                    Text(texto)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .navigationTitle("Contexto de la crisis")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Listo") { mostrarContexto = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

/// Tarjeta de evento económico con su dato histórico real.
struct TarjetaEvento: View {
    let turno: Turno

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Turno \(turno.id) · \(turno.titulo)", systemImage: "newspaper.fill")
                .font(.headline)
                .foregroundStyle(.tint)

            Text(turno.evento)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            // Dato histórico real: refuerza el criterio de la rúbrica sobre
            // datos que justifican la propuesta.
            Label {
                Text(turno.datoHistorico)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.tint.opacity(0.3)))
        // VoiceOver lee la tarjeta completa como una unidad.
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Evento del turno \(turno.id): \(turno.titulo). \(turno.evento) Dato histórico: \(turno.datoHistorico)")
    }
}

/// Burbuja con la decisión escrita por el jugador (alineada a la derecha,
/// como un chat).
struct BurbujaDecision: View {
    let texto: String

    var body: some View {
        HStack {
            Spacer(minLength: 40)
            Text(texto)
                .font(.body)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.tint, in: RoundedRectangle(cornerRadius: 18))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tu decisión: \(texto)")
    }
}

/// Tarjeta de consecuencias: riesgo + impacto + narrativa + lección.
struct TarjetaResultado: View {
    let resultado: ResultadoTurno

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                MedidorRiesgo(nivel: resultado.nivelRiesgo)
                Spacer()
                Text(resultado.cambioPatrimonioPorcentaje.comoPorcentajeConSigno)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(resultado.cambioPatrimonioPorcentaje >= 0 ? .green : .red)
                    .accessibilityLabel("Cambio en tu patrimonio: \(resultado.cambioPatrimonioPorcentaje.comoPorcentajeConSigno)")
            }

            Text(resultado.narrativa)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            // Lección educativa: el corazón pedagógico de la app.
            Label {
                Text(resultado.leccion)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "graduationcap.fill")
                    .foregroundStyle(.tint)
            }

            HStack(spacing: 6) {
                Image(systemName: resultado.concepto.icono)
                Text(resultado.concepto.nombre)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.tint.opacity(0.15), in: Capsule())
            .accessibilityLabel("Concepto desbloqueado en el glosario: \(resultado.concepto.nombre)")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

/// Mensaje del motor de IA pidiendo al jugador que reformule su decisión
/// porque el input anterior no se entendió como una intención financiera.
struct TarjetaPedirReintento: View {
    let mensaje: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "bubble.left.fill")
                .foregroundStyle(.tint)
                .font(.body)
            Text(mensaje)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.tint.opacity(0.25)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("El simulador te dice: \(mensaje)")
    }
}

/// Tres opciones de decisión financiera generadas por el motor cuando el
/// jugador no logró formular su decisión tras dos intentos.
/// Las opciones son interactivas solo si se pasa el callback `onSeleccionar`.
struct TarjetaOpciones: View {
    let opciones: [String]
    var onSeleccionar: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Elige una opción", systemImage: "hand.tap.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)

            ForEach(Array(opciones.enumerated()), id: \.offset) { _, opcion in
                Button {
                    onSeleccionar?(opcion)
                } label: {
                    Text(opcion)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.tint.opacity(onSeleccionar != nil ? 0.1 : 0.05),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.tint.opacity(onSeleccionar != nil ? 0.35 : 0.15)))
                }
                .buttonStyle(.plain)
                .disabled(onSeleccionar == nil)
                .accessibilityLabel("Opción: \(opcion)")
                .accessibilityHint(onSeleccionar != nil ? "Toca para elegir esta decisión" : "")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.tint.opacity(0.3)))
        .accessibilityElement(children: .contain)
    }
}

/// Medidor visual del nivel de riesgo: 4 segmentos + icono + texto.
/// El color nunca es el único canal: hay texto e icono (daltonismo).
struct MedidorRiesgo: View {
    let nivel: NivelRiesgo

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(nivel.titulo, systemImage: nivel.icono)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(nivel.color)
            HStack(spacing: 3) {
                ForEach(NivelRiesgo.allCases) { caso in
                    Capsule()
                        .fill(caso.indice <= nivel.indice ? nivel.color : Color(.systemFill))
                        .frame(width: 26, height: 6)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Nivel de riesgo de tu decisión: \(nivel.titulo), \(nivel.indice + 1) de 4")
    }
}
