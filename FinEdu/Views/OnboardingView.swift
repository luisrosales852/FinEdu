//
//  OnboardingView.swift
//  FinEdu
//
//  Onboarding de 3 páginas: propósito, ODS que atiende y cómo funciona la
//  IA on-device. Animación sutil del icono con PhaseAnimator (iOS 17),
//  desactivada automáticamente con Reduce Motion.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("onboardingCompletado") private var onboardingCompletado = false
    @State private var pagina = 0

    var body: some View {
        VStack {
            TabView(selection: $pagina) {
                PaginaOnboarding(
                    icono: "graduationcap.fill",
                    titulo: "Aprende de las crisis reales",
                    texto: "FinEdu es un simulador narrativo: vives crisis económicas históricas (México 1994, el mundo en 2008, una hiperinflación) y decides, con tus propias palabras, qué hacer con tu dinero. Equivocarte aquí es gratis; en la vida real cuesta años."
                )
                .tag(0)

                PaginaOnboarding(
                    icono: "globe.americas.fill",
                    titulo: "Human-Centered AI + ODS",
                    texto: "Atendemos el ODS 4 (Educación de Calidad) y el ODS 8 (Trabajo Decente y Crecimiento Económico): la resiliencia financiera de los jóvenes se construye con educación, no con sermones. La IA te acompaña y explica; las reglas del juego están basadas en datos históricos auditables."
                )
                .tag(1)

                PaginaOnboarding(
                    icono: "lock.shield.fill",
                    titulo: "IA 100% en tu dispositivo",
                    texto: "Tus decisiones se analizan con Apple Intelligence (Foundation Models) y, si tu equipo no lo soporta, con un clasificador de Create ML + NaturalLanguage. Nada de lo que escribas sale de tu iPhone: sin nube, sin servidores, sin internet."
                )
                .tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if pagina < 2 {
                    withAnimation { pagina += 1 }
                } else {
                    onboardingCompletado = true
                }
            } label: {
                Text(pagina < 2 ? "Continuar" : "Comenzar")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .accessibilityHint(pagina < 2 ? "Pasa a la siguiente página de introducción" : "Termina la introducción y va a la selección de escenarios")
        }
    }
}

private struct PaginaOnboarding: View {
    let icono: String
    let titulo: String
    let texto: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // PhaseAnimator (iOS 17): pulso sutil del icono.
            // Con Reduce Motion activo se muestra estático.
            if reduceMotion {
                iconoVista
            } else {
                PhaseAnimator([1.0, 1.08, 1.0]) { escala in
                    iconoVista
                        .scaleEffect(escala)
                } animation: { _ in
                    .easeInOut(duration: 1.6)
                }
            }

            Text(titulo)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(texto)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
        .accessibilityElement(children: .combine)
    }

    private var iconoVista: some View {
        Image(systemName: icono)
            .font(.system(size: 64))
            .foregroundStyle(.tint)
            .frame(width: 120, height: 120)
            .background(.tint.opacity(0.12), in: Circle())
            .accessibilityHidden(true) // decorativo: el título ya lo describe
    }
}

#Preview {
    OnboardingView()
}
