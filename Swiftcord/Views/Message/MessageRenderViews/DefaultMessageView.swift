//
//  DefaultMessageView.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 11/8/22.
//

import SwiftUI
import DiscordKitCore
import DiscordKit

struct EnhancedMarkdownView: View {
    let text: String
    let message: Message
    let font: Font
    
    @EnvironmentObject var gateway: DiscordGateway
    @EnvironmentObject var serverCtx: ServerContext
    
    var body: some View {
        let parsedText = parseMentions(in: text, message: message)
        
        Text(parsedText)
            .font(font)
            .textSelection(.enabled)
            .onTapGesture {
                // Extract URLs from the text and open them
                if let url = extractFirstURL(from: text) {
                    NSWorkspace.shared.open(url)
                }
            }
    }
    
    private func parseMentions(in text: String, message: Message) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // Parse user mentions (<@123456789>)
        let userMentionPattern = #"<@(\d+)>"#
        attributedString = parseUserMentions(attributedString, pattern: userMentionPattern, mentions: message.mentions)
        
        // Parse role mentions (<@&123456789>)
        let roleMentionPattern = #"<@&(\d+)>"#
        attributedString = parseRoleMentions(attributedString, pattern: roleMentionPattern, mentionRoles: message.mention_roles)
        
        // Parse channel mentions (<#123456789>)
        let channelMentionPattern = #"<#(\d+)>"#
        attributedString = parseChannelMentions(attributedString, pattern: channelMentionPattern, mentionChannels: message.mention_channels)
        
        // Parse @everyone and @here
        attributedString = parseEveryoneMentions(attributedString, mentionEveryone: message.mention_everyone)
        
        return attributedString
    }
    
    private func parseUserMentions(_ attributedString: AttributedString, pattern: String, mentions: [User]) -> AttributedString {
        var result = attributedString
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
            
            // Process matches in reverse order to avoid index shifting
            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: text) {
                    let userId = Snowflake(text[range])
                    
                    // Find the user in mentions array
                    if let user = mentions.first(where: { $0.id == userId }) {
                        let displayName = user.displayName.isEmpty ? (user.global_name ?? user.username) : user.displayName
                        let replacement = "@\(displayName)"
                        
                        if let matchRange = Range(match.range, in: text) {
                            let attributedReplacement = AttributedString(replacement)
                            var replacementWithAttributes = attributedReplacement
                            
                            // Apply mention styling
                            replacementWithAttributes.foregroundColor = .blue
                            replacementWithAttributes.font = font
                            
                            // Convert String.Index to AttributedString.Index
                            let startIndex = result.index(result.startIndex, offsetByCharacters: matchRange.lowerBound.utf16Offset(in: text))
                            let endIndex = result.index(result.startIndex, offsetByCharacters: matchRange.upperBound.utf16Offset(in: text))
                            result.replaceSubrange(startIndex..<endIndex, with: replacementWithAttributes)
                        }
                    }
                }
            }
        } catch {
            print("Error parsing user mentions: \(error)")
        }
        
        return result
    }
    
    private func parseRoleMentions(_ attributedString: AttributedString, pattern: String, mentionRoles: [Snowflake]) -> AttributedString {
        var result = attributedString
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
            
            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: text) {
                    let roleId = Snowflake(text[range])
                    
                    // Find the role in the guild
                    if let guild = serverCtx.guild,
                       let role = guild.roles.first(where: { (try? $0.unwrap().id) == roleId }).flatMap({ try? $0.unwrap() }) {
                        let replacement = "@\(role.name)"
                        
                        if let matchRange = Range(match.range, in: text) {
                            let attributedReplacement = AttributedString(replacement)
                            var replacementWithAttributes = attributedReplacement
                            
                            // Apply role mention styling with role color
                            replacementWithAttributes.foregroundColor = Color(hex: role.color)
                            replacementWithAttributes.font = font
                            
                            // Convert String.Index to AttributedString.Index
                            let startIndex = result.index(result.startIndex, offsetByCharacters: matchRange.lowerBound.utf16Offset(in: text))
                            let endIndex = result.index(result.startIndex, offsetByCharacters: matchRange.upperBound.utf16Offset(in: text))
                            result.replaceSubrange(startIndex..<endIndex, with: replacementWithAttributes)
                        }
                    }
                }
            }
        } catch {
            print("Error parsing role mentions: \(error)")
        }
        
        return result
    }
    
    private func parseChannelMentions(_ attributedString: AttributedString, pattern: String, mentionChannels: [ChannelMention]?) -> AttributedString {
        var result = attributedString
        
        guard let mentionChannels = mentionChannels else { return result }
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
            
            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: text) {
                    let channelId = Snowflake(text[range])
                    
                    // Find the channel in mentionChannels
                    if let channelMention = mentionChannels.first(where: { $0.id == channelId }) {
                        let replacement = "#\(channelMention.name)"
                        
                        if let matchRange = Range(match.range, in: text) {
                            let attributedReplacement = AttributedString(replacement)
                            var replacementWithAttributes = attributedReplacement
                            
                            // Apply channel mention styling
                            replacementWithAttributes.foregroundColor = .blue
                            replacementWithAttributes.font = font
                            
                            // Convert String.Index to AttributedString.Index
                            let startIndex = result.index(result.startIndex, offsetByCharacters: matchRange.lowerBound.utf16Offset(in: text))
                            let endIndex = result.index(result.startIndex, offsetByCharacters: matchRange.upperBound.utf16Offset(in: text))
                            result.replaceSubrange(startIndex..<endIndex, with: replacementWithAttributes)
                        }
                    }
                }
            }
        } catch {
            print("Error parsing channel mentions: \(error)")
        }
        
        return result
    }
    
    private func parseEveryoneMentions(_ attributedString: AttributedString, mentionEveryone: Bool) -> AttributedString {
        var result = attributedString
        
        if mentionEveryone {
            // Replace @everyone and @here with styled versions
            let everyonePattern = #"@everyone"#
            let herePattern = #"@here"#
            
            do {
                let everyoneRegex = try NSRegularExpression(pattern: everyonePattern)
                let hereRegex = try NSRegularExpression(pattern: herePattern)
                
                let everyoneMatches = everyoneRegex.matches(in: text, range: NSRange(location: 0, length: text.count))
                let hereMatches = hereRegex.matches(in: text, range: NSRange(location: 0, length: text.count))
                
                // Process @everyone matches
                for match in everyoneMatches.reversed() {
                    if let matchRange = Range(match.range, in: text) {
                        let attributedReplacement = AttributedString("@everyone")
                        var replacementWithAttributes = attributedReplacement
                        
                        replacementWithAttributes.foregroundColor = .orange
                        replacementWithAttributes.font = font
                        
                        // Convert String.Index to AttributedString.Index
                        let startIndex = result.index(result.startIndex, offsetByCharacters: matchRange.lowerBound.utf16Offset(in: text))
                        let endIndex = result.index(result.startIndex, offsetByCharacters: matchRange.upperBound.utf16Offset(in: text))
                        result.replaceSubrange(startIndex..<endIndex, with: replacementWithAttributes)
                    }
                }
                
                // Process @here matches
                for match in hereMatches.reversed() {
                    if let matchRange = Range(match.range, in: text) {
                        let attributedReplacement = AttributedString("@here")
                        var replacementWithAttributes = attributedReplacement
                        
                        replacementWithAttributes.foregroundColor = .orange
                        replacementWithAttributes.font = font
                        
                        // Convert String.Index to AttributedString.Index
                        let startIndex = result.index(result.startIndex, offsetByCharacters: matchRange.lowerBound.utf16Offset(in: text))
                        let endIndex = result.index(result.startIndex, offsetByCharacters: matchRange.upperBound.utf16Offset(in: text))
                        result.replaceSubrange(startIndex..<endIndex, with: replacementWithAttributes)
                    }
                }
            } catch {
                print("Error parsing everyone mentions: \(error)")
            }
        }
        
        return result
    }
    
    private func extractFirstURL(from text: String) -> URL? {
        let urlPattern = #"https?://[^\s]+"#
        if let range = text.range(of: urlPattern, options: .regularExpression),
           let url = URL(string: String(text[range])) {
            return url
        }
        return nil
    }
}

// Helper extension for Color
extension Color {
    init(hex: Int) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

struct DefaultMessageView: View {
	let message: Message
	let shrunk: Bool

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
				
				VStack(alignment: .leading, spacing: 2) {
					EnhancedMarkdownView(
						text: msg,
						message: message,
						font: message.content.containsOnlyEmojiAndSpaces ? .system(size: 48) : .appMessage
					)
					
					if message.edited_timestamp != nil && shrunk {
						Text("message.edited.shrunk")
							.font(.footnote)
							.italic()
							.foregroundColor(Color(NSColor.textColor).opacity(0.4))
					}
				}
				.lineSpacing(4)
				.frame(maxWidth: .infinity, alignment: .leading)
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
