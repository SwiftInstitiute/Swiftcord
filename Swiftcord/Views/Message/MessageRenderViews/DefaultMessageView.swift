//
//  DefaultMessageView.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 11/8/22.
//

import SwiftUI
import DiscordKitCore

struct DefaultMessageView: View {
	let message: Message
	let shrunk: Bool
	
	@EnvironmentObject var gateway: DiscordGateway

    var body: some View {
		// For including additional message components
		VStack(alignment: .leading, spacing: 4) {
			if !message.content.isEmpty {
				// Guard doesn't work in a view :(((
				/*if let msg = attributedMessage(content: message.content) {
				 Text(msg)
				 .font(.system(size: 15))
				 .textSelection(.enabled)
				 // fix this poor implementation later
				 }*/
				let msg = message.content.containsOnlyEmojiAndSpaces
				? message.content.replacingOccurrences(of: " ", with: " ")
				: message.content
				
				// Check if this is the current user's message
				let isCurrentUser = message.author.id == gateway.cache.user?.id
				
				HStack {
					if isCurrentUser {
						Spacer()
					}
					
					Group {
						Text(markdown: msg)
							.font(message.content.containsOnlyEmojiAndSpaces ? .system(size: 48) : .appMessage)
						+ Text(
							message.edited_timestamp != nil && shrunk
							? "message.edited.shrunk"
							: ""
						)
						.font(.footnote)
						.italic()
						.foregroundColor(isCurrentUser ? .white.opacity(0.7) : Color(NSColor.textColor).opacity(0.4))
					}
					.lineSpacing(4)
					.textSelection(.enabled)
					.foregroundColor(isCurrentUser ? .white : .primary)
					.padding(.horizontal, 12)
					.padding(.vertical, 8)
					.background(
						RoundedRectangle(cornerRadius: 18)
							.fill(isCurrentUser ? Color.accentColor : Color.gray.opacity(0.2))
					)
					.frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
					
					if !isCurrentUser {
						Spacer()
					}
				}
			}
			if let stickerItems = message.sticker_items {
				ForEach(stickerItems) { sticker in
					MessageStickerView(sticker: sticker)
				}
			}
			ForEach(message.attachments) { attachment in
				AttachmentView(attachment: attachment)
			}
			ForEach(message.embeds) { embed in
				EmbedView(embed: embed)
			}
		}
    }
}
