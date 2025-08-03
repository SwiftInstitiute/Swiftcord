//
//  ChannelButton.swift
//  Swiftcord
//
//  Created by Vincent on 4/13/22.
//

import SwiftUI
import DiscordKitCore
import DiscordKit
import CachedAsyncImage

struct ChannelButton: View, Equatable {
	static func == (lhs: ChannelButton, rhs: ChannelButton) -> Bool {
		lhs.selectedCh == rhs.selectedCh && lhs.channel == rhs.channel
	}

    let channel: Channel
    @Binding var selectedCh: Channel?

    var body: some View {
		if channel.type == .dm || channel.type == .groupDM {
			DMButton(dm: channel, selectedCh: $selectedCh)
				.buttonStyle(DiscordChannelButton(isSelected: selectedCh?.id == channel.id))
				.controlSize(.large)
		} else {
			GuildChButton(channel: channel, selectedCh: $selectedCh)
				.buttonStyle(DiscordChannelButton(isSelected: selectedCh?.id == channel.id))
		}
    }
}

struct GuildChButton: View {
	let channel: Channel
	@Binding var selectedCh: Channel?
	@State private var hovered = false

	@EnvironmentObject var state: UIState

	private let chIcons = [
		ChannelType.voice: "speaker.wave.2.fill",
		ChannelType.news: "megaphone.fill"
	]

	var body: some View {
		Button { selectedCh = channel } label: {
			let image = (state.serverCtx.guild?.properties.rules_channel_id != nil && state.serverCtx.guild?.properties.rules_channel_id == channel.id) ? "newspaper.fill" : (chIcons[channel.type] ?? "number")
			Label(channel.label() ?? "nil", systemImage: image)
				.padding(.vertical, 8)
				.padding(.horizontal, 12)
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(
					// Enhanced liquid glass channel button background
					ZStack {
						RoundedRectangle(cornerRadius: 8)
							.fill(Color.clear)
					.background(hovered ? AnyShapeStyle(Material.ultraThinMaterial) : AnyShapeStyle(Color.clear))
							.overlay(
								RoundedRectangle(cornerRadius: 8)
									.stroke(
										LinearGradient(
											colors: [
												Color.white.opacity(hovered ? 0.3 : 0.1),
												Color.white.opacity(hovered ? 0.2 : 0.05),
												Color.clear
											],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										),
										lineWidth: hovered ? 1.5 : 0.5
									)
							)
						
						// Inner glow when hovered
						if hovered {
							RoundedRectangle(cornerRadius: 8)
								.fill(
									RadialGradient(
										colors: [
											Color.white.opacity(0.1),
											Color.clear
										],
										center: .topLeading,
										startRadius: 0,
										endRadius: 40
									)
								)
						}
					}
				)
		}
		.onHover { hover in hovered = hover }
		.animation(.easeInOut(duration: 0.2), value: hovered)
	}
}

struct DMButton: View {
	let dm: Channel // swiftlint:disable:this identifier_name
	@Binding var selectedCh: Channel?

	@EnvironmentObject var gateway: DiscordGateway

	var body: some View {
		Button { selectedCh = dm } label: {
			HStack {
				if dm.type == .dm, let user = gateway.cache.users[dm.recipient_ids![0]] {
					AvatarWithPresence(
						avatarURL: user.avatarURL(size: 64),
						presence: gateway.presences[user.id]?.status ?? .offline,
						animate: false
					).controlSize(.small)
				} else {
					Image(systemName: "person.2.fill")
						.foregroundColor(.white)
						.frame(width: 32, height: 32)
						.background(.red)
						.clipShape(Circle())
				}

				VStack(alignment: .leading, spacing: 2) {
					Text(dm.label(gateway.cache.users) ?? "nil")
					if dm.type == .groupDM {
						Text("\((dm.recipient_ids?.count ?? 2) + 1) dm.group.memberCount")
							.font(.caption)
					}
				}
				Spacer()
			}
			.padding(.horizontal, 12)
			.padding(.vertical, 8)
			.background(
				// Liquid glass DM button background
				ZStack {
					RoundedRectangle(cornerRadius: 8)
						.fill(Color.clear)
						.background(.ultraThinMaterial)
						.overlay(
							RoundedRectangle(cornerRadius: 8)
								.stroke(
									LinearGradient(
										colors: [
											Color.white.opacity(0.2),
											Color.white.opacity(0.1),
											Color.clear
										],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									),
									lineWidth: 1
								)
						)
					
					// Inner glow
					RoundedRectangle(cornerRadius: 8)
						.fill(
							RadialGradient(
								colors: [
									Color.white.opacity(0.05),
									Color.clear
								],
								center: .topLeading,
								startRadius: 0,
								endRadius: 50
							)
						)
				}
			)
			.clipShape(RoundedRectangle(cornerRadius: 8))
		}
	}
}
