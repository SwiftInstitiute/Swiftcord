//
//  ServerButton.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 22/2/22.
//

import SwiftUI
import DiscordKit
import DiscordKitCore
import CachedAsyncImage

/*
 Font size of text in server button for servers without an icon

 # of chars	 Font size (px)
 1			 18
 2			 18
 3		 	 16
 4			 16
 5		 	 14
 6			 12
 7			 10
 8			 10
 9			 10
 10			 10
 */

struct ServerButton: View {
	let selected: Bool
	var guild: PreloadedGuild?
	let name: String
	var systemIconName: String?
	var assetIconName: String?
	var serverIconURL: String?
	var bgColor: Color?
	var noIndicator = false // Don't show capsule
	var isLoading: Bool = false
	let onSelect: () -> Void
	@State private var hovered = false

	let capsuleAnimation = Animation.interpolatingSpring(stiffness: 500, damping: 30)

	var body: some View {
		HStack {
			Capsule()
				.scale((selected || hovered) && !noIndicator ? 1 : 0)
				.fill(Color(nsColor: .labelColor))
				.frame(width: 8, height: selected ? 40 : (hovered ? 20 : 8))
				.animation(capsuleAnimation, value: selected)
				.animation(capsuleAnimation, value: hovered)

			Button(name, action: onSelect)
				.buttonStyle(
					ServerButtonStyle(
						selected: selected,
						guild: guild,
						name: name,
						bgColor: bgColor,
						systemName: systemIconName,
						assetName: assetIconName,
						serverIconURL: serverIconURL,
						loading: isLoading,
						hovered: $hovered
					)
				)
				.background(.ultraThinMaterial)
				.clipShape(RoundedRectangle(cornerRadius: 12))
				.scaleEffect(hovered ? 1.05 : 1.0)
				.shadow(color: hovered ? .black.opacity(0.2) : .clear, radius: hovered ? 8 : 0, x: 0, y: 2)
				.animation(.easeInOut(duration: 0.2), value: hovered)
				.popover(isPresented: $hovered) {
					VStack(spacing: 8) {
						Text(name)
							.font(.title3)
							.fontWeight(.semibold)
						
						if let guild = guild {
							Text("\(guild.member_count ?? 0) members")
								.font(.caption)
								.foregroundColor(.secondary)
						}
					}
					.padding(12)
					.background(.ultraThinMaterial)
					.clipShape(RoundedRectangle(cornerRadius: 12))
				}
		}
		.padding(.horizontal, 8)
		.padding(.vertical, 4)
	}
}

struct ServerButtonStyle: ButtonStyle {
    let selected: Bool
	var guild: PreloadedGuild?
    let name: String
    let bgColor: Color?
    let systemName: String?
    let assetName: String?
    let serverIconURL: String?
    let loading: Bool
    @Binding var hovered: Bool
	
	@EnvironmentObject var gateway: DiscordGateway

	func makeBody(configuration: Configuration) -> some View {
		ZStack {
			if let assetName {
				Image(assetName)
					.resizable()
					.scaledToFit()
					.frame(width: 26)
			} else if let systemName {
				Image(systemName: systemName)
					.font(.system(size: 24))
			} else if let serverIconURL, let iconURL = URL(string: serverIconURL) {
				if iconURL.isAnimatable {
					SwiftyGifView(
						url: iconURL.modifyingPathExtension("gif"),
						animating: hovered,
						resetWhenNotAnimating: true
					).transition(.customOpacity)
				} else {
					BetterImageView(url: iconURL) {
						configuration.label.font(.system(size: 18))
					}
				}
			} else {
				let iconName = name.split(separator: " ").map({ $0.prefix(1) }).joined(separator: "")
				Text(iconName)
					.font(.system(size: 18))
					.lineLimit(1)
					.minimumScaleFactor(0.5)
					.padding(5)
			}
		}
		.frame(width: 48, height: 48)
		.foregroundColor(hovered || selected ? .white : Color(nsColor: .labelColor))
		.background(
			Group {
				if hovered || selected {
					if let bgColor = bgColor {
						LinearGradient(
							colors: [bgColor.opacity(0.8), bgColor.opacity(0.6)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					} else if serverIconURL != nil {
						Color.gray.opacity(0.2)
					} else {
						LinearGradient(
							colors: [Color.accentColor.opacity(0.8), Color.accentColor.opacity(0.6)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					}
				} else {
					Color.gray.opacity(0.15)
				}
			}
		)
		.overlay(
			RoundedRectangle(cornerRadius: hovered || selected ? 16 : 24, style: .continuous)
				.stroke(
					hovered || selected ? Color.white.opacity(0.2) : Color.clear,
					lineWidth: hovered || selected ? 0.5 : 0
				)
		)
		.mask {
			RoundedRectangle(cornerRadius: hovered || selected ? 16 : 24, style: .continuous)
		}
		.offset(y: configuration.isPressed ? 1 : 0)
		.animation(.none, value: configuration.isPressed)
        .animation(.interpolatingSpring(stiffness: 500, damping: 30), value: hovered)
        .onHover { hover in hovered = hover }
		.contextMenu {
			if guild != nil {
				Text(name)
				
				Divider()
				
				Button(action: { Task { await readAll() } }) {
					Image(systemName: "message.badge")
					Text("Mark as read")
				}
				
				Divider()
				
				Group {
					Button(action: copyLink) {
						Image(systemName: "link")
						Text("Copy Link")
					}
					Button(action: copyId) {
						Image(systemName: "number.circle.fill")
						Text("Copy ID")
					}
				}
			}
		}
	}
}

private extension ServerButtonStyle {
	func readAll() async {
		if let guild = guild {
			for channel in guild.channels {
				do {
					if let unwrappedChannel = try? channel.unwrap() {
						let _ = try await restAPI.ackMessageRead(id: unwrappedChannel.id, msgID: unwrappedChannel.last_message_id ?? "", manual: true, mention_count: 0)
					}
				} catch {}
			}
		}
	}
	
	func copyLink() {
		if let guild = guild {
			let pasteboard = NSPasteboard.general
			pasteboard.clearContents()
			pasteboard.setString(
				"https://canary.discord.com/channels/\(guild.id)",
				forType: .string
			)
		}
	}
	
	func copyId() {
		if let guild = guild {
			let pasteboard = NSPasteboard.general
			pasteboard.clearContents()
			pasteboard.setString(
				guild.id,
				forType: .string
			)
		}
	}
}
