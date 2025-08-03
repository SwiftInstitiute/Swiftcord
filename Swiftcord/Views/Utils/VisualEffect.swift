//
//  VisualEffect.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 23/9/23.
//

import SwiftUI
import AppKit

// MARK: - Liquid Glass Effects with Version Compatibility
struct LiquidGlassBackground: View {
    let color: Color
    let opacity: Double
    let blurRadius: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(color)
            .opacity(opacity)
            .background(.ultraThinMaterial)
            .blur(radius: blurRadius)
    }
}

struct GlassmorphismCard: View {
    let backgroundColor: Color
    let borderColor: Color
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    
    init(
        backgroundColor: Color = .white.opacity(0.1),
        borderColor: Color = .white.opacity(0.2),
        cornerRadius: CGFloat = 12,
        borderWidth: CGFloat = 1
    ) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .background(.ultraThinMaterial)
    }
}

struct FrostedGlass: View {
    let blurRadius: CGFloat
    let opacity: Double
    
    init(blurRadius: CGFloat = 10, opacity: Double = 0.3) {
        self.blurRadius = blurRadius
        self.opacity = opacity
    }
    
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .blur(radius: blurRadius)
            .opacity(opacity)
    }
}

// MARK: - Modern Button Styles with Version Compatibility
struct LiquidGlassButtonStyle: ButtonStyle {
    let isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                GlassmorphismCard(
                    backgroundColor: isPressed ? .white.opacity(0.15) : .white.opacity(0.1),
                    borderColor: isPressed ? .white.opacity(0.3) : .white.opacity(0.2),
                    cornerRadius: 8,
                    borderWidth: isPressed ? 1.5 : 1
                )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Modern Text Field with Version Compatibility
struct LiquidGlassTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String?
    
    init(_ text: Binding<String>, placeholder: String, icon: String? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            GlassmorphismCard(
                backgroundColor: .white.opacity(0.08),
                borderColor: .white.opacity(0.15),
                cornerRadius: 8
            )
        )
    }
}

// MARK: - Modern Navigation Bar with Version Compatibility
struct LiquidGlassNavigationBar: View {
    let title: String
    let leftButton: (() -> AnyView)?
    let rightButton: (() -> AnyView)?
    
    init(
        title: String,
        leftButton: (() -> AnyView)? = nil,
        rightButton: (() -> AnyView)? = nil
    ) {
        self.title = title
        self.leftButton = leftButton
        self.rightButton = rightButton
    }
    
    var body: some View {
        HStack {
            if let leftButton = leftButton {
                leftButton()
            }
            
            Spacer()
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let rightButton = rightButton {
                rightButton()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            FrostedGlass(blurRadius: 15, opacity: 0.8)
        )
    }
}

// MARK: - Modern Sidebar with Version Compatibility
struct LiquidGlassSidebar: View {
    let content: AnyView
    
    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }
    
    var body: some View {
        content
            .background(
                FrostedGlass(blurRadius: 20, opacity: 0.9)
            )
            .overlay(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.3)
            )
    }
}

// MARK: - Modern List Style with Version Compatibility
struct LiquidGlassListStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                FrostedGlass(blurRadius: 10, opacity: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Modern Card Style with Version Compatibility
struct LiquidGlassCardStyle: ViewModifier {
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 12) {
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                GlassmorphismCard(
                    backgroundColor: .white.opacity(0.1),
                    borderColor: .white.opacity(0.2),
                    cornerRadius: cornerRadius
                )
            )
    }
}

// MARK: - Modern Divider with Version Compatibility
struct LiquidGlassDivider: View {
    let color: Color
    let thickness: CGFloat
    
    init(color: Color = .white.opacity(0.2), thickness: CGFloat = 1) {
        self.color = color
        self.thickness = thickness
    }
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: thickness)
            .background(.ultraThinMaterial)
            .blur(radius: 0.5)
    }
}

// MARK: - Modern Progress Bar with Version Compatibility
struct LiquidGlassProgressBar: View {
    let progress: Double
    let backgroundColor: Color
    let progressColor: Color
    
    init(
        progress: Double,
        backgroundColor: Color = .white.opacity(0.1),
        progressColor: Color = .blue
    ) {
        self.progress = progress
        self.backgroundColor = backgroundColor
        self.progressColor = progressColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor)
                    .background(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(progressColor)
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Modern Badge with Version Compatibility
struct LiquidGlassBadge: View {
    let text: String
    let color: Color
    
    init(_ text: String, color: Color = .blue) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                GlassmorphismCard(
                    backgroundColor: color.opacity(0.2),
                    borderColor: color.opacity(0.3),
                    cornerRadius: 12
                )
            )
            .foregroundColor(color)
    }
}

// MARK: - View Extensions with Version Compatibility
extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 12) -> some View {
        self.modifier(LiquidGlassCardStyle(cornerRadius: cornerRadius))
    }
    
    func liquidGlassList() -> some View {
        self.modifier(LiquidGlassListStyle())
    }
    
    func liquidGlassButton(isPressed: Bool = false) -> some View {
        self.buttonStyle(LiquidGlassButtonStyle(isPressed: isPressed))
    }
}

// MARK: - Version-Specific Compatibility Helpers
@available(macOS 16.0, *)
struct ModernLiquidGlassEffects {
    static func createAdvancedGlassEffect() -> some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .background(.ultraThinMaterial)
            .blur(radius: 20)
    }
}

// Fallback for older macOS versions
struct LegacyGlassEffects {
    static func createBasicGlassEffect() -> some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .opacity(0.8)
    }
}

// MARK: - Compatibility Check Helper
struct VersionCompatibilityHelper {
    static var isModernGlassAvailable: Bool {
        if #available(macOS 16.0, *) {
            return true
        } else {
            return false
        }
    }
    
    static func createGlassEffect() -> some View {
        if #available(macOS 16.0, *) {
            return ModernLiquidGlassEffects.createAdvancedGlassEffect()
        } else {
            return LegacyGlassEffects.createBasicGlassEffect()
        }
    }
}
