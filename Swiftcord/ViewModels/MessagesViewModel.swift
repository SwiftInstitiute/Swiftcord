//
//  MessagesViewModel.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 9/8/22.
//

import SwiftUI
import DiscordKitCore

// TODO: Make this ViewModel follow best practices and actually function as a ViewModel
@MainActor class MessagesViewModel: ObservableObject {
	// For use in the UI - different from MessageReference in DiscordKit
	struct ReplyRef {
		let messageID: Snowflake
		let guildID: Snowflake
		let ping: Bool
		let authorID: Snowflake
		let authorUsername: String
	}

	@Published var reachedTop = false
	@Published var messages: [Message] = []
	@Published var newMessage = " "
	@Published var attachments: [URL] = []
	@Published var showingInfoBar = false
	@Published var loadError = false
	@Published var infoBarData: InfoBarData?
	@Published var fetchMessagesTask: Task<(), Error>?
	@Published var lastSentTyping = Date(timeIntervalSince1970: 0)
	@Published var newAttachmentErr: NewAttachmentError?
	@Published var replying: ReplyRef?
	@Published var dropOver = false
	@Published var highlightMsg: Snowflake?
	
	// Dynamic message loading
	@Published var isLoadingMessages = false
	@Published var loadedMessageIds: Set<Snowflake> = []
	@Published var messageLoadQueue: [Snowflake] = []
	@Published var isProcessingMessageQueue = false
	private let maxConcurrentMessageLoads = 5
	private let messageLoadBatchSize = 20
	var messageCache: [Snowflake: Message] = [:]
	private var lastLoadTime: Date = Date()
	private let minLoadInterval: TimeInterval = 0.1

	func addMessage(_ message: Message) {
		withAnimation {
			// Check if message already exists to prevent duplicates
			if !messages.contains(where: { $0.id == message.id }) {
				messages.append(message)
				messages.sort { $0.timestamp > $1.timestamp }
				messageCache[message.id] = message
			}
		}
	}

	func updateMessage(_ updated: PartialMessage) {
		if let updatedIdx = messages.firstIndex(identifiedBy: updated.id) {
			messages[updatedIdx] = messages[updatedIdx].mergingWithPartialMsg(updated)
			messageCache[updated.id] = messages[updatedIdx]
		}
	}

	func deleteMessage(_ deleted: MessageDelete) {
		withAnimation { 
			messages.removeAll(identifiedBy: deleted.id)
			messageCache.removeValue(forKey: deleted.id)
		}
	}
	
	func deleteMessageBulk(_ bulkDelete: MessageDeleteBulk) {
		withAnimation {
			for msgID in bulkDelete.id {
				messages.removeAll(identifiedBy: msgID)
				messageCache.removeValue(forKey: msgID)
			}
		}
	}
	
	// Dynamic message loading
	func loadMessagesDynamically() {
		guard !isProcessingMessageQueue else { return }
		guard Date().timeIntervalSince(lastLoadTime) >= minLoadInterval else { return }
		
		isProcessingMessageQueue = true
		lastLoadTime = Date()
		
		// Process message queue in batches
		let batch = Array(messageLoadQueue.prefix(messageLoadBatchSize))
		messageLoadQueue.removeFirst(min(messageLoadBatchSize, messageLoadQueue.count))
		
		Task {
			await withTaskGroup(of: Void.self) { group in
				for messageId in batch {
					group.addTask {
						await self.loadMessageDetails(messageId: messageId)
					}
				}
			}
			
			DispatchQueue.main.async {
				self.isProcessingMessageQueue = false
				if !self.messageLoadQueue.isEmpty {
					// Continue processing if there are more messages
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
						self.loadMessagesDynamically()
					}
				}
			}
		}
	}
	
	private func loadMessageDetails(messageId: Snowflake) async {
		// Simulate message loading with a small delay to prevent overwhelming the API
		try? await Task.sleep(nanoseconds: 25_000_000) // 25ms delay
		
		DispatchQueue.main.async {
			self.loadedMessageIds.insert(messageId)
		}
	}
	
	func queueMessageForLoading(_ messageId: Snowflake) {
		if !loadedMessageIds.contains(messageId) && !messageLoadQueue.contains(messageId) {
			messageLoadQueue.append(messageId)
			loadMessagesDynamically()
		}
	}
	
	// Cache management
	func clearCache() {
		messageCache.removeAll()
		loadedMessageIds.removeAll()
		messageLoadQueue.removeAll()
	}
	
	func getCachedMessage(_ messageId: Snowflake) -> Message? {
		return messageCache[messageId]
	}
}
