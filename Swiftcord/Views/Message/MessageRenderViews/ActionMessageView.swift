//
//  ActionMessageView.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 11/8/22.
//

import SwiftUI
import DiscordKit
import DiscordKitCore

/// Action messages: e.g. member leave, join etc.
struct ActionMessageView: View {
	@EnvironmentObject var gateway: DiscordGateway // This is used to get the user for the call messages
	let message: Message
	let mini: Bool

	private struct ActionMessageData {
		let message: LocalizedStringKey
		let icon: String
		let color: Color
	}

	// Trust, this might seem messy but it's more scalable than putting the
	// views themselves in a huge if tree
	private var data: ActionMessageData {
		switch message.type {
		case .guildMemberJoin:
			return ActionMessageData(
				message: "**\(message.author.displayName)** joined this server.",
				icon: "arrow.right",
				color: .green
			)
		case .recipientAdd:
			return ActionMessageData(
				message: "**\(message.author.displayName)** added **\(message.mentions[0].displayName)** to the group.",
				icon: "arrow.right",
				color: .green
			)
		case .recipientRemove:
			return ActionMessageData(
				message: "**\(message.author.displayName)** left the group.",
				icon: "arrow.left",
				color: .red
			)
		case .userPremiumGuildSub:
			return ActionMessageData(
				message: "**\(message.author.displayName)** just boosted the server!",
				icon: "rhombus.fill",
				color: .purple
			)
		case .userPremiumGuildSubTier1:
			return ActionMessageData(
				message: "**\(message.author.displayName)** just boosted the server! This server has achieved **Level 1!**",
				icon: "rhombus.fill",
				color: .purple
			)
		case .userPremiumGuildSubTier2:
			return ActionMessageData(
				message: "**\(message.author.displayName)** just boosted the server! This server has achieved **Level 2!**",
				icon: "rhombus.fill",
				color: .purple
			)
		case .userPremiumGuildSubTier3:
			return ActionMessageData(
				message: "**\(message.author.displayName)** just boosted the server! This server has achieved **Level 3!**",
				icon: "rhombus.fill",
				color: .purple
			)
		case .call:
			if let user = gateway.cache.user {
				let isFromSelf = message.author.id == user.id
				if message.call?.participants.count == 1 && !isFromSelf { // Missed call
					return ActionMessageData(
						message: "You missed a call from **\(message.author.displayName)**.",
						icon: "phone.fill",
						color: .gray
					)
				} else { // Active, missed call from self or non missed call.
					let isActive = message.call?.ended_timestamp == nil
					let difference = message.call?.ended_timestamp?.timeIntervalSince(message.timestamp) ?? 0

					return ActionMessageData(
						message: "**\(message.author.displayName)** started a call\(!isActive ? " that lasted \(HelperInstances.intervalFormatter.string(from: difference)?.lowercased() ?? "an unknown duration")" : "").",
						icon: "phone.fill",
						color: .green
					)
				}
			} else {
				return ActionMessageData(
					message: "An error ocurred when rendering this message!",
					icon: "exclamationmark.circle",
					color: .red
				)
			}
		default:
			return ActionMessageData(
				message: "Oops, rendering `\(String(describing: message.type))` messages aren't supported yet :(",
				icon: "questionmark",
				color: .gray
			)
		}
	}

	var body: some View {
		VStack {
			Image(systemName: data.icon)
				.foregroundColor(data.color)
				.font(.system(size: mini ? 12 : 16, weight: .medium))
				.padding([.leading, .trailing], mini ? 0 : 12)
			
			if mini {
				Text(data.message).font(.body)
					.rotationEffect(.degrees(180))
					.scaleEffect(y: -1)
			} else {
				HStack(spacing: 0) {
					Text(data.message).font(.body)
						.rotationEffect(.degrees(180))
						.scaleEffect(y: -1)
					Text(" ").font(.body)
						.rotationEffect(.degrees(180))
						.scaleEffect(y: -1)
					Text(DateFormatter.messageDateFormatter.string(from: message.timestamp))
						.font(.callout)
						.rotationEffect(.degrees(180))
						.scaleEffect(y: -1)
				}
			}
		}
		.opacity(0.75)
	}
}
