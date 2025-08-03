//
//  MiniUserProfileView.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 28/5/22.
//

import SwiftUI
import DiscordKit
import DiscordKitCore
import CachedAsyncImage

struct MiniUserProfileView<RichContentSlot: View>: View {
	let user: User
	let pasteboard = NSPasteboard.general
	let member: Member?
	var guildRoles: [Role]?
	var isWebhook: Bool = false
	var loadError: Bool = false
	@ViewBuilder var contentSlot: RichContentSlot

	@State private var note = ""

	@EnvironmentObject var gateway: DiscordGateway
	@Environment(\.colorScheme) var colorScheme

    var body: some View {
		let avatarURL = user.avatarURL(size: 160)
		let presence = gateway.presences[user.id]

		VStack(alignment: .leading, spacing: 0) {
			if let banner = user.banner {
				let url = banner.bannerURL(of: user.id, size: 600)
				Group {
					if url.isAnimatable {
						SwiftyGifView(url: url.modifyingPathExtension("gif"))
					} else {
						CachedAsyncImage(url: url) { image in
							image.resizable().scaledToFill()
						} placeholder: { Rectangle().fill(Color(hex: user.accent_color ?? 0)) }
					}
				}
				.frame(width: 300, height: 120)
				.clipShape(ProfileAccentMask(insetStart: 14, insetWidth: 92))
			} else if let accentColor = user.accent_color {
				Rectangle().fill(Color(hex: accentColor))
					.frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
					.clipShape(ProfileAccentMask(insetStart: 14, insetWidth: 92))
			} else {
				CachedAsyncImage(url: avatarURL) { image in
					image.resizable().scaledToFill()
				} placeholder: { EmptyView() }
					.frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
					.blur(radius: 4)
					.clipShape(ProfileAccentMask(insetStart: 14, insetWidth: 92))
			}
			HStack(alignment: .bottom, spacing: 4) {
				AvatarWithPresence(
					avatarURL: avatarURL,
					presence: presence?.status ?? .offline,
					animate: true
				)
				.padding(6)

				ProfileBadges(user: user, premiumType: user.premium_type)
					.frame(minHeight: 40, alignment: .topTrailing)
				Spacer()
				if loadError {
					Image(systemName: "exclamationmark.triangle.fill")
						.font(.system(size: 20))
						.foregroundColor(.orange)
						.help("Failed to get full user profile")
						.padding(.trailing, 14)
				}
			}
			.padding(.leading, 14)
			.padding(.top, -46) // 92/2 = 46
			.padding(.bottom, -8)

			VStack(alignment: .leading, spacing: 6) {
				VStack(alignment: .leading, spacing: 0) {
					HStack(alignment: .center, spacing: 6) {
						Text(user.global_name ?? user.username).font(.title2).fontWeight(.bold).lineLimit(1)
						if user.bot == true || isWebhook {
							NonUserBadge(flags: user.public_flags, isWebhook: isWebhook)
						}
						Spacer()
						Button {
							pasteboard.declareTypes([.string], owner: nil)
							pasteboard.setString(user.fullUsername, forType: .string)
						} label: {
							Image(systemName: "square.on.square")
						}
						.buttonStyle(.plain)
						.frame(width: 20, height: 20)
					}
					// Webhooks don't have discriminators
					Text(user.displayNameWithDiscriminator)
				}

				// Custom status
				if let status = presence?.activities.first(where: { $0.type == .custom })?.state {
					Text(status)
						.fixedSize(horizontal: false, vertical: true)
						.padding(.top, 6)
				}

				Divider().padding(.vertical, 6)

				if isWebhook {
					Text("This user is a webhook")
					Button {

					} label: {
						Label("Manage Server Webhooks", systemImage: "link")
							.frame(maxWidth: .infinity)
					}
					.buttonStyle(FlatButtonStyle())
					.controlSize(.small)
				} else {
					if let bio = user.bio, !bio.isEmpty {
						Text("user.bio").font(.headline).textCase(.uppercase)
						Text(markdown: bio)
							.fixedSize(horizontal: false, vertical: true)
							.padding(.bottom, 6)
					}

					contentSlot
				}
			}
			.padding(12)
			.background(
				RoundedRectangle(cornerRadius: 4, style: .continuous)
					.fill(colorScheme == .dark ? .black.opacity(0.45) : .white.opacity(0.45))
			)
			.padding(14)
		}
		.frame(width: 300)
	}
}

struct MiniUserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        /*MiniUserProfileView()*/
		EmptyView()
    }
}
