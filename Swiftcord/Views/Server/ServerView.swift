//
//  ServerView.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 23/2/22.
//

import SwiftUI
import DiscordKit
import DiscordKitCore

class ServerContext: ObservableObject {
  @Published public var channel: Channel?
  @Published public var guild: PreloadedGuild?
  @Published public var typingStarted: [Snowflake: [TypingStart]] = [:]
  @Published public var roles: [Role] = []
  @Published public var member: Member?
  @Published public var basePermissions: Permissions = []
}

struct ServerView: View {
  @Binding var guild: PreloadedGuild?
  @State private var evtID: EventDispatch.HandlerIdentifier?
  @State private var mediaCenterOpen: Bool = false
  
  @EnvironmentObject var serverCtx: ServerContext
  
  @EnvironmentObject var state: UIState
  @EnvironmentObject var gateway: DiscordGateway
  @EnvironmentObject var audioManager: AudioCenterManager
  
  private func loadChannels() {
    guard state.loadingState != .initial else { return } // Ensure gateway is connected before loading anything
    guard let guild = serverCtx.guild else { return }
    // Unwrap DecodeThrowable<Channel> to Channel
    let channels = guild.channels.compactMap { try? $0.unwrap() }.discordSorted()
    
    if let lastChannel = UserDefaults.standard.string(forKey: "lastCh.\(serverCtx.guild!.id)"),
       let lastChObj = channels.first(where: { $0.id == lastChannel }) { // swiftlint:disable:this indentation_width
      serverCtx.channel = lastChObj
      return
    }
    let selectableChs = channels.filter { $0.type != .category }
    serverCtx.channel = selectableChs.first
    
    // Prevent deadlocking if there are no DMs/channels
    if serverCtx.channel == nil { state.loadingState = .messageLoad }
  }
  
  private func bootstrapGuild(with existingGuild: PreloadedGuild) {
    serverCtx.guild = existingGuild
    serverCtx.roles = []
    loadChannels()
    // Sending malformed IDs causes an instant Gateway session termination
    guard !existingGuild.properties.isDMChannel else {
      AnalyticsWrapper.event(type: .DMListViewed, properties: [
        "channel_id": serverCtx.channel?.id ?? "",
        "channel_type": serverCtx.channel?.type.rawValue ?? 1
      ])
      return
    }
    
    AnalyticsWrapper.event(type: .guildViewed, properties: [
      "guild_id": existingGuild.id,
      "guild_is_vip": existingGuild.properties.premium_tier != PremiumLevel.none,
      "guild_num_channels": existingGuild.channels.count
    ])
    
    // Subscribe to typing events
    gateway.subscribeGuildEvents(id: existingGuild.id)
    serverCtx.roles = existingGuild.roles.compactMap { try? $0.unwrap() }
    // Retrieve guild roles to update context
    Task {
      do {
        let newRoles = try await restAPI.getGuildRoles(id: existingGuild.id)
        //print(newRoles)
        serverCtx.roles = newRoles
      } catch {
        print("Could not retrieve guild roles due to: \(error.localizedDescription)")
      }
    }
  }
  
  private func toggleSidebar()
  {
    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
  }
  
  private var sidebarContent: some View {
    VStack(spacing: 0) {
      if let guildCtx = guild {
        // Modern channel list with glass effect
        ChannelList(channels: guildCtx.properties.name == "DMs" ? gateway.cache.dms : guildCtx.channels.compactMap { try? $0.unwrap() }, selCh: $serverCtx.channel)
          .environmentObject(serverCtx)
          .background(.ultraThinMaterial)
          .toolbar {
            ToolbarItem {
              HStack {
                Text(guildCtx.properties.name == "DMs" ? "dm" : "\(guildCtx.properties.name)")
                  .font(.title3)
                  .fontWeight(.semibold)
                  .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: toggleSidebar) {
                  Image(systemName: "sidebar.left")
                    .font(.title2)
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        // Show loading state when no guild is selected
        VStack {
          Spacer()
          ProgressView("Loading...")
            .foregroundColor(.secondary)
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      
      Spacer()
      
      // User footer at the bottom
      if let user = gateway.cache.user {
        CurrentUserFooter(user: user)
          .background(.ultraThinMaterial)
      }
    }
    .frame(minWidth: 240, maxWidth: .infinity)
     .background(.ultraThinMaterial)
  }
  
  var body: some View {
    Group {
      // Content area only - sidebar is now handled in ContentView
      if let channel = serverCtx.channel {
        MessagesView()
          .environmentObject(serverCtx)
          .background(
            LinearGradient(
              colors: [
                Color(red: 0.08, green: 0.08, blue: 0.12),
                Color(red: 0.05, green: 0.05, blue: 0.08)
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          )
      } else {
        // Modern empty state
        VStack(spacing: 24) {
          Image(systemName: "message.circle")
            .font(.system(size: 64))
            .foregroundColor(.secondary)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
          
          VStack(spacing: 8) {
            Text("No Channel Selected")
              .font(.title2)
              .fontWeight(.semibold)
              .foregroundColor(.primary)
            
            Text("Choose a channel from the sidebar to start chatting")
              .font(.body)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
          }
          
          Text("Select a channel")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.blue.opacity(0.2))
            .foregroundColor(.blue)
            .clipShape(Capsule())
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
          LinearGradient(
            colors: [
              Color(red: 0.08, green: 0.08, blue: 0.12),
              Color(red: 0.05, green: 0.05, blue: 0.08)
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
      }
    }
    .onChange(of: guild) { newGuild in
      if let newGuild = newGuild {
        bootstrapGuild(with: newGuild)
      }
    }
    .onAppear {
      if let existingGuild = guild {
        bootstrapGuild(with: existingGuild)
      }
    }
    .onDisappear {
      if let evtID = evtID {
        gateway.onEvent.removeHandler(handler: evtID)
      }
    }
  }
}
