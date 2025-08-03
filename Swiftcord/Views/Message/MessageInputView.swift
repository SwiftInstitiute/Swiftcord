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
	let isDisabled: Bool
	
	init(
		placeholder: String,
		message: Binding<String>,
		attachments: Binding<[URL]>,
		replying: Binding<MessagesViewModel.ReplyRef?>,
		onSend: @escaping (String, [URL]) -> Void,
		preAttach: (() -> Bool)? = nil,
		isDisabled: Bool = false
	) {
		self.placeholder = placeholder
		self._message = message
		self._attachments = attachments
		self._replying = replying
		self.onSend = onSend
		self.preAttach = preAttach
		self.isDisabled = isDisabled
	}
	
	var body: some View {
		VStack(spacing: 0) {
			replySection
			inputSection
		}
		.background(
			RoundedRectangle(cornerRadius: 12)
				.fill(Color.secondary.opacity(0.1))
		)


	}
	
	@ViewBuilder
	private var replySection: some View {
		if replying != nil {
			MessageInputReplyView(replying: $replying)
				.background(Color.secondary.opacity(0.1))
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
		.background(
			// Enhanced liquid glass input container
			ZStack {
				// Base glass layer with enhanced blur
				RoundedRectangle(cornerRadius: 16)
					.fill(Color.clear)
					.background(.ultraThinMaterial)
					.overlay(
						// Sophisticated border with multiple gradients
						RoundedRectangle(cornerRadius: 16)
							.stroke(
								LinearGradient(
									colors: [
										Color.white.opacity(0.4),
										Color.white.opacity(0.2),
										Color.white.opacity(0.1),
										Color.clear
									],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								),
								lineWidth: 1.5
							)
					)
				
				// Inner glow effect
				RoundedRectangle(cornerRadius: 16)
					.fill(
						RadialGradient(
							colors: [
								Color.white.opacity(0.1),
								Color.clear
							],
							center: .topLeading,
							startRadius: 0,
							endRadius: 100
						)
					)
			}
		)
		.shadow(
			color: Color.black.opacity(0.15),
			radius: 12,
			x: 0,
			y: 4
		)
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
			.padding(.horizontal, 16)
			.padding(.vertical, 12)
			.disabled(isDisabled)
			.opacity(isDisabled ? 0.5 : 1.0)
			.background(
				// Enhanced liquid glass text field
				ZStack {
					// Base glass layer with enhanced blur
					RoundedRectangle(cornerRadius: 12)
						.fill(isDisabled ? Color.gray.opacity(0.1) : Color.clear)
						.overlay(
							// Sophisticated border with multiple gradients
							RoundedRectangle(cornerRadius: 12)
								.stroke(
									LinearGradient(
										colors: [
											Color.white.opacity(0.5),
											Color.white.opacity(0.3),
											Color.white.opacity(0.1),
											Color.clear
										],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									),
									lineWidth: 1.5
								)
						)
					
					// Inner glow effect for depth
					RoundedRectangle(cornerRadius: 12)
						.fill(
							RadialGradient(
								colors: [
									Color.white.opacity(0.15),
									Color.clear
								],
								center: .topLeading,
								startRadius: 0,
								endRadius: 80
							)
						)
					
					// Subtle inner shadow for depth
					RoundedRectangle(cornerRadius: 12)
						.stroke(
							Color.black.opacity(0.1),
							lineWidth: 0.5
						)
						.blur(radius: 1)
						.offset(x: 0, y: 1)
				}
			)
			.shadow(
				color: Color.black.opacity(0.1),
				radius: 4,
				x: 0,
				y: 2
			)
			.onSubmit {
				if !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
					onSend(message, attachments)
					message = ""
					attachments = []
				}
			}
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
							HStack(spacing: 4) {
								Text(attachment.lastPathComponent)
									.font(.caption)
								Image(systemName: "xmark.circle.fill")
									.font(.caption)
									.foregroundColor(.red)
							}
							.padding(.horizontal, 10)
							.padding(.vertical, 6)
						}
						.background(
							// Liquid glass attachment tag
							ZStack {
								RoundedRectangle(cornerRadius: 8)
									.fill(Color.clear)
									.background(.ultraThinMaterial)
									.overlay(
										RoundedRectangle(cornerRadius: 8)
											.stroke(
												LinearGradient(
													colors: [
														Color.white.opacity(0.3),
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
												Color.white.opacity(0.1),
												Color.clear
											],
											center: .topLeading,
											startRadius: 0,
											endRadius: 30
										)
									)
							}
						)
						.clipShape(RoundedRectangle(cornerRadius: 8))
					}
				}
				.padding(.horizontal, 12)
				.padding(.vertical, 8)
			}
			.background(
				// Liquid glass attachments container
				ZStack {
					RoundedRectangle(cornerRadius: 10)
						.fill(Color.clear)
						.background(.ultraThinMaterial)
						.overlay(
							RoundedRectangle(cornerRadius: 10)
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
				}
			)
			.clipShape(RoundedRectangle(cornerRadius: 10))
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
				.padding(8)
				.background(
					// Liquid glass send button
					ZStack {
						Circle()
							.fill(Color.clear)
							.background(.ultraThinMaterial)
							.overlay(
								Circle()
									.stroke(
										LinearGradient(
											colors: [
												Color.white.opacity(0.4),
												Color.white.opacity(0.2),
												Color.clear
											],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										),
										lineWidth: 1
									)
							)
						
						// Inner glow
						Circle()
							.fill(
								RadialGradient(
									colors: [
										Color.white.opacity(0.1),
										Color.clear
									],
									center: .topLeading,
									startRadius: 0,
									endRadius: 20
								)
							)
					}
				)
				.clipShape(Circle())
		}
		.buttonStyle(.plain)
		.disabled(isDisabled || (message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && attachments.isEmpty))
	}
}