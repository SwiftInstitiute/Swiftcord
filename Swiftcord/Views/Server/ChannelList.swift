//
//  ChannelList.swift
//  Swiftcord
//
//  Created by Vincent on 4/12/22.
//

import SwiftUI
import Introspect
import DiscordKitCore
import DiscordKit

/// Renders the channel list on the sidebar
struct ChannelList: View, Equatable {
	let channels: [Channel]
	@Binding var selCh: Channel?
	@AppStorage("nsfwShown") var nsfwShown: Bool = true
	@EnvironmentObject var serverCtx: ServerContext
	@EnvironmentObject var gateway: DiscordGateway

	@_transparent @_optimize(speed) @ViewBuilder
	private func item(for channel: Channel) -> some View {
		ChannelButton(channel: channel, selectedCh: $selCh)
			.equatable()
			.listRowInsets(.init(top: 1, leading: 0, bottom: 1, trailing: 0))
			.listRowBackground(
				Group {
					if selCh?.id == channel.id {
						// No background for selected items - clean liquid glass effect
						Color.clear
					} else {
						Spacer().overlay(alignment: .leading) {
							// Check if we should show unread indicator
							if let lastID = gateway.readState[channel.id]?.last_message_id, let _chLastID = channel.last_message_id, let chLastID = Int(_chLastID), lastID.intValue < chLastID {
								Circle().fill(.primary).frame(width: 8, height: 8).offset(x: 2)
							}
						}
					}
				}
			)
			.contextMenu {
				let isRead = gateway.readState[channel.id]?.id == channel.last_message_id
				Button(action: { Task { await readChannel(channel) } }) {
					Image(systemName: isRead ? "message" : "message.badge")
					Text("Mark as read")
				}.disabled(isRead)
				
				Divider()
				
				Group {
					Button(action: { copyLink(channel) }) {
						Image(systemName: "link")
						Text("Copy Link")
					}
					Button(action: { copyId(channel) }) {
						Image(systemName: "number.circle.fill")
						Text("Copy ID")
					}
				}
			}
	}

	private static func computeOverwrites(
		channel: Channel, guildID: Snowflake,
		member: Member, basePerms: Permissions
	) -> Permissions {
		if basePerms.contains(.administrator) {
			return .all
		}
		var permission = basePerms
		// Apply the overwrite for the @everyone permission
		if let everyoneOverwrite = channel.permission_overwrites?.first(where: { $0.id == guildID }) {
			permission.applyOverwrite(everyoneOverwrite)
		}
		// Next, apply role-specific overwrites
		channel.permission_overwrites?.forEach { overwrite in
			if member.roles.contains(overwrite.id) {
				permission.applyOverwrite(overwrite)
			}
		}
		// Finally, apply member-specific overwrites - must be done after all roles
		channel.permission_overwrites?.forEach { overwrite in
			if member.user_id == overwrite.id {
				permission.applyOverwrite(overwrite)
			}
		}
		return permission
	}

	var body: some View {
		let availableChs = channels.filter { channel in
			guard let guildID = serverCtx.guild?.id, let member = serverCtx.member else {
				// print("no guild or member!")
				return true
			}
			guard channel.type != .category else {
				return true
			}
			return channel.computedPermissions(
				guildID: guildID,
				member: member,
				basePerms: serverCtx.basePermissions
			)
			.contains(.viewChannel)
		}
		ScrollView {
			LazyVStack(spacing: 0) {
				// Spacer(minLength: 4).listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0)) // 38 (header) - 16 (unremovable section top padding) + 4 (spacing)

				let filteredChannels = availableChs.filter {
					$0.parent_id == nil && $0.type != .category && (nsfwShown || ($0.nsfw == false || $0.nsfw == nil))
				}
				if !filteredChannels.isEmpty {
					VStack(alignment: .leading, spacing: 0) {
						// Enhanced liquid glass section header
						HStack {
							Text(serverCtx.guild?.properties.isDMChannel == true
								? "dm"
								: "server.channel.noCategory"
							).textCase(.uppercase)
								.foregroundColor(.secondary)
								.font(.caption.weight(.medium))
								.padding(.horizontal, 12)
								.padding(.vertical, 6)
								.background(
									RoundedRectangle(cornerRadius: 4)
										.fill(Color.secondary.opacity(0.1))
								)
								.clipShape(RoundedRectangle(cornerRadius: 6))
						}
						.padding(.leading, 8)
						.padding(.top, 8)
						.padding(.bottom, 4)
						
						let channels = filteredChannels.discordSorted()
						ForEach(channels, id: \.id) { channel in 
							item(for: channel)
								.clipShape(RoundedRectangle(cornerRadius: 8))
								.padding(.vertical, 2)
						}
					}
				}

				let categoryChannels = availableChs
					.filter { $0.parent_id == nil && $0.type == .category }
					.discordSorted()
				ForEach(categoryChannels, id: \.id) { channel in
					// Channels in this section
					let channels = availableChs.filter {
						$0.parent_id == channel.id && (nsfwShown || ($0.nsfw == false || $0.nsfw == nil))
					}.discordSorted()
					if !channels.isEmpty {
						VStack(alignment: .leading, spacing: 0) {
							// Enhanced liquid glass category header
							HStack {
								Text(channel.name ?? "").textCase(.uppercase)
									.foregroundColor(.secondary)
									.font(.caption.weight(.medium))
									.padding(.horizontal, 12)
									.padding(.vertical, 6)
									.background(
										RoundedRectangle(cornerRadius: 4)
											.fill(Color.secondary.opacity(0.1))
									)
									.clipShape(RoundedRectangle(cornerRadius: 6))
							}
							.padding(.leading, 8)
							.padding(.top, 8)
							.padding(.bottom, 4)
							
							ForEach(channels, id: \.id) { channel in 
								item(for: channel)
									.clipShape(RoundedRectangle(cornerRadius: 8))
									.padding(.vertical, 2)
							}
						}
						.contextMenu {
							Button(action: { Task { await readChannels(channels) } }) {
								Image(systemName: "message.badge")
								Text("Mark as read")
							}
							
							Divider()
							
							Button(action: { copyId(channel) }) {
								Image(systemName: "number.circle.fill")
								Text("Copy ID")
							}
						}
					}
				}
			}
		}
		.environment(\.defaultMinListRowHeight, 1)
		.padding(.horizontal, 6)
		.frame(minWidth: 240, maxHeight: .infinity)
		.background(
			RoundedRectangle(cornerRadius: 8)
				.fill(Color.secondary.opacity(0.05))
		)
		.clipShape(RoundedRectangle(cornerRadius: 12))

		.environment(\.defaultMinListRowHeight, 1)
	}

	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.channels == rhs.channels && lhs.selCh == rhs.selCh
	}
}

private extension ChannelList {
	func readChannels(_ channels: [Channel]) async {
		for channel in channels {
			await readChannel(channel)
		}
	}
	
	func readChannel(_ channel: Channel) async {
		do {
			let _ = try await restAPI.ackMessageRead(id: channel.id, msgID: channel.last_message_id ?? "", manual: true, mention_count: 0)
		} catch {}
	}
	
	func copyLink(_ channel: Channel) {
		let pasteboard = NSPasteboard.general
		pasteboard.clearContents()
		pasteboard.setString(
			"https://canary.discord.com/channels/\(channel.guild_id ?? "@me")/\(channel.id)",
			forType: .string
		)
	}
	
	func copyId(_ channel: Channel) {
		let pasteboard = NSPasteboard.general
		pasteboard.clearContents()
		pasteboard.setString(
			channel.id,
			forType: .string
		)
	}
}
