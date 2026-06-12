//
//  Estilos.swift
//  FinEdu
//
//  Estilos compartidos. Accesibilidad: los colores de riesgo se eligieron
//  con contraste AA sobre fondos del sistema, y NUNCA son el único canal de
//  información (siempre van acompañados de icono + texto, pensando en
//  usuarios con daltonismo).
//

import SwiftUI

extension View {
    /// Mantiene el cursor de flecha (en vez de la mano de "enlace") sobre
    /// controles grandes como las tarjetas. `pointerStyle` solo existe en el
    /// SDK de macOS, así que en iOS/"Designed for iPad" es un no-op.
    @ViewBuilder
    func cursorFlecha() -> some View {
        #if os(macOS)
        if #available(macOS 15.0, *) {
            self.pointerStyle(.default)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

extension NivelRiesgo {
    var color: Color {
        switch self {
        case .conservadora: return .teal
        case .moderada: return .blue
        case .arriesgada: return .orange
        case .muyArriesgada: return .red
        }
    }
}

extension Double {
    /// Formato de dinero localizado: "$12,346" (sin centavos, el juego maneja
    /// magnitudes grandes y los centavos solo estorban).
    func comoMoneda(simbolo: String) -> String {
        let formateador = NumberFormatter()
        formateador.numberStyle = .decimal
        formateador.maximumFractionDigits = 0
        formateador.locale = Locale(identifier: "es_MX")
        let numero = formateador.string(from: NSNumber(value: self)) ?? "\(Int(self))"
        return "\(simbolo)\(numero)"
    }

    /// Dinero con signo: "+$1,234" / "−$1,234". Útil para mostrar ganancias.
    func comoMonedaConSigno(simbolo: String) -> String {
        let signo = self >= 0 ? "+" : "−"
        return "\(signo)\(abs(self).comoMoneda(simbolo: simbolo))"
    }

    /// Porcentaje con signo: "+12.5%" / "−8.0%".
    var comoPorcentajeConSigno: String {
        String(format: "%@%.1f%%", self >= 0 ? "+" : "", self)
    }
}
