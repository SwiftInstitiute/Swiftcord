//
//  MessageInputView.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 24/2/22.
//

import SwiftUI
import DiscordKit
import DiscordKitCore

struct MessageInputView: View {
	let placeholder: String
	@Binding var message: String
	@Binding var attachments: [URL]
	@Binding var replying: MessagesViewModel.ReplyRef?
	let onSend: (String, [URL]) -> Void
	let preAttach: (() -> Bool)?
	
	init(
		placeholder: String,
		message: Binding<String>,
		attachments: Binding<[URL]>,
		replying: Binding<MessagesViewModel.ReplyRef?>,
		onSend: @escaping (String, [URL]) -> Void,
		preAttach: (() -> Bool)? = nil
	) {
		self.placeholder = placeholder
		self._message = message
		self._attachments = attachments
		self._replying = replying
		self.onSend = onSend
		self.preAttach = preAttach
	}
	
	var body: some View {
		VStack(spacing: 0) {
			replySection
			inputSection
		}
		.background(.ultraThinMaterial)
	}
	
	@ViewBuilder
	private var replySection: some View {
		if replying != nil {
			MessageInputReplyView(replying: $replying)
				.background(.ultraThinMaterial)
				.clipShape(RoundedRectangle(cornerRadius: 8))
				.padding(.horizontal, 12)
				.padding(.top, 8)
		}
	}
	
	@ViewBuilder
	private var inputSection: some View {
		HStack(alignment: .bottom, spacing: 8) {
			textInputSection
			sendButton
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 8)
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}
	
	@ViewBuilder
	private var textInputSection: some View {
		VStack(spacing: 0) {
			textField
			attachmentsSection
		}
	}
	
	private var textField: some View {
		TextField(placeholder, text: $message)
			.textFieldStyle(PlainTextFieldStyle())
			.padding(.horizontal, 12)
			.padding(.vertical, 8)
			.background(.ultraThinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 8))
	}
	
	@ViewBuilder
	private var attachmentsSection: some View {
		if !attachments.isEmpty {
			ScrollView(.horizontal, showsIndicators: false) {
				HStack(spacing: 8) {
					ForEach(attachments, id: \.self) { attachment in
						Button(action: {
							attachments.removeAll { $0 == attachment }
						}) {
							Text(attachment.lastPathComponent)
								.padding(.horizontal, 8)
								.padding(.vertical, 4)
						}
						.background(.ultraThinMaterial)
						.clipShape(RoundedRectangle(cornerRadius: 8))
					}
				}
				.padding(.horizontal, 12)
				.padding(.vertical, 8)
			}
			.background(.ultraThinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 8))
		}
	}
	
	private var sendButton: some View {
		Button(action: {
			onSend(message, attachments)
			withAnimation { attachments.removeAll() }
		}) {
			Image(systemName: "arrow.up.circle.fill")
				.font(.title2)
				.foregroundColor(.blue)
		}
		.buttonStyle(.plain)
		.disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && attachments.isEmpty)
	}
}