//
//  ContentView.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 19/2/22.
//

import SwiftUI
import CoreData
import os
import DiscordKit
import DiscordKitCore

struct ContentView: View {
    @EnvironmentObject var gateway: DiscordGateway
    @EnvironmentObject var state: UIState
    @EnvironmentObject var accountsManager: AccountSwitcher
    
    @State private var presentingAddServer = false
    @StateObject private var sharedServerContext = ServerContext()
    
    // Dynamic server loading
    @State private var isLoadingGuilds = false
    @State private var loadedGuilds: Set<String> = []
    @State private var guildLoadQueue: [String] = []
    @State private var isProcessingGuildQueue = false
    private let maxConcurrentGuildLoads = 3
    private let guildLoadBatchSize = 10

    @StateObject private var audioManager = AudioCenterManager()

    private let log = Logger(category: "ContentView")

    private func makeDMGuild() -> PreloadedGuild {
        PreloadedGuild(
            channels: gateway.cache.dms,
            properties: Guild(
                id: "@me",
                name: "DMs",
                owner_id: "",
                afk_timeout: 0,
                verification_level: .none,
                default_message_notifications: .all,
                explicit_content_filter: .disabled,
                roles: [], emojis: [], features: [],
                mfa_level: .none,
                system_channel_flags: 0,
                channels: gateway.cache.dms,
                premium_tier: .none,
                preferred_locale: .englishUS,
                nsfw_level: .default,
                premium_progress_bar_enabled: false
            )
        )
    }

    private func loadLastSelectedGuild() {
        if let lGID = UserDefaults.standard.string(forKey: "lastSelectedGuild"),
            gateway.cache.guilds[lGID] != nil || lGID == "@me" {
            state.selectedGuildID = lGID
        } else {
            state.selectedGuildID = "@me"
        }
    }

    private var serverListItems: [ServerListItem] {
        let unsortedGuilds = gateway.cache.guilds.values.filter { guild in
            !gateway.guildFolders.contains { folder in
                folder.guild_ids.contains(guild.id)
            }
        }
        .sorted { lhs, rhs in lhs.joined_at > rhs.joined_at }
        .map { ServerListItem.guild($0) }
        
        let folderItems = gateway.guildFolders.compactMap { folder -> ServerListItem? in
            if folder.id != nil {
                let guilds = folder.guild_ids.compactMap {
                    gateway.cache.guilds[$0]
                }
                // Only show folders that have at least one loaded guild
                guard !guilds.isEmpty else { return nil }
                let name = folder.name ?? String(guilds.map { $0.properties.name }.joined(separator: ", "))
                return .guildFolder(ServerFolder.GuildFolder(
                    name: name, guilds: guilds, color: folder.color.flatMap { Color(hex: $0) } ?? Color.accentColor
                ))
            } else {
                guard let guild = gateway.cache.guilds[folder.guild_ids.first ?? ""] else {
                    return nil
                }
                return .guild(guild)
            }
        }
        
        return unsortedGuilds + folderItems
    }
    
    private func loadGuildsDynamically() {
        guard !isProcessingGuildQueue else { return }
        isProcessingGuildQueue = true
        
        // Process guild queue in batches
        let batch = Array(guildLoadQueue.prefix(guildLoadBatchSize))
        guildLoadQueue.removeFirst(min(guildLoadBatchSize, guildLoadQueue.count))
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                for guildId in batch {
                    group.addTask {
                        await self.loadGuildDetails(guildId: guildId)
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.isProcessingGuildQueue = false
                if !self.guildLoadQueue.isEmpty {
                    // Continue processing if there are more guilds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.loadGuildsDynamically()
                    }
                }
            }
        }
    }
    
    private func loadGuildDetails(guildId: String) async {
        // Simulate guild loading with a small delay to prevent overwhelming the API
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
        
        DispatchQueue.main.async {
            self.loadedGuilds.insert(guildId)
        }
    }
    
    private func queueGuildForLoading(_ guildId: String) {
        if !loadedGuilds.contains(guildId) && !guildLoadQueue.contains(guildId) {
            guildLoadQueue.append(guildId)
            loadGuildsDynamically()
        }
    }
    
    private func getSelectedGuild() -> PreloadedGuild? {
        guard let selectedGuildID = state.selectedGuildID else { return nil }
        if selectedGuildID == "@me" {
            return makeDMGuild()
        } else {
            return gateway.cache.guilds[selectedGuildID]
        }
    }
    
    private var serverListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 8) {
                ServerButton(
                    selected: state.selectedGuildID == "@me",
                    name: "Home",
                    assetIconName: "DiscordIcon"
                ) {
                    state.selectedGuildID = "@me"
                }
                .padding(.top, 4)

                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.2))
                    .frame(width: 32)
                    .padding(.vertical, 8)

				LazyVStack(spacing: 8) {
                    ForEach(self.serverListItems) { item in
                        switch item {
                        case .guild(let guild):
                            ServerButton(
                                selected: state.selectedGuildID == guild.id,
                                guild: guild,
                                name: guild.properties.name,
                                serverIconURL: guild.properties.iconURL(),
                                isLoading: !loadedGuilds.contains(guild.id)
                            ) {
                                state.selectedGuildID = guild.id
                                queueGuildForLoading(guild.id)
                            }
                            .onAppear {
                                queueGuildForLoading(guild.id)
                            }
                        case .guildFolder(let folder):
                            ServerFolder(
                                folder: folder,
                                selectedGuildID: $state.selectedGuildID,
                                loadingGuildID: nil
                            )
                        }
                    }
                }

									ServerButton(
                    selected: false,
                    name: "Add a Server",
                    systemIconName: "plus",
                    bgColor: .green,
                    noIndicator: true
                ) {
                    presentingAddServer = true
                }.padding(.bottom, 4)
            }
									.padding(.horizontal, 8)
								}
        .frame(width: 72, height: .infinity, alignment: .top)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(width: 0.5)
                .foregroundColor(Color.gray.opacity(0.15))
                .offset(x: 35.75)
        )
    }
    
    private var channelListView: some View {
        VStack(spacing: 0) {
            if let guild = getSelectedGuild() {
                // Header with guild name and search
                HStack {
                    Text(guild.properties.name == "DMs" ? "Direct Messages" : guild.properties.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                                
                // Channel list
                ChannelList(
                    channels: guild.properties.name == "DMs" ? gateway.cache.dms : guild.channels.compactMap { try? $0.unwrap() },
                    selCh: $sharedServerContext.channel
                )
                .environmentObject(sharedServerContext)
                
                Spacer()
                
                // User footer at the bottom
                if let user = gateway.cache.user {
                    CurrentUserFooter(user: user)
                }
            } else {
                // Loading state
                VStack {
                    Spacer()
                    ProgressView("Loading...")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 280)
        .background(Color.clear)
    }
    
    var body: some View {
        ZStack {
            // Show loading view during initial states
            if state.loadingState == .initial || state.loadingState == .gatewayConn {
                LoadingView()
            } else {
                // Main content when loaded - three panel layout
                HStack(spacing: 0) {
                    // Server list (left panel)
                    serverListView
                    
                    // Channel list (middle panel)
                    channelListView
                    
                    // Content area (right panel)
                    if let selectedGuildID = state.selectedGuildID {
                        ServerView(
                            guild: Binding(
                                get: { selectedGuildID == "@me" ? makeDMGuild() : gateway.cache.guilds[selectedGuildID] },
                                set: { _ in }
                            )
                        )
                        .environmentObject(sharedServerContext)
					} else {
                        // Welcome screen when no server is selected
                        VStack(spacing: 24) {
                            Image(systemName: "server.rack")
                                .font(.system(size: 64))
                                .foregroundColor(.secondary)
								.background(.ultraThinMaterial)
								.clipShape(Circle())
							
                            VStack(spacing: 8) {
								Text("Welcome to Swiftcord")
                                    .font(.title2)
                                    .fontWeight(.semibold)
									.foregroundColor(.primary)
								
                                Text("Select a server from the left to get started")
                                    .font(.body)
									.foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
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
            }
        }
        .environmentObject(audioManager)
        .background(Color.clear)
        .onChange(of: state.selectedGuildID) { id in
            guard let id = id else { return }
            UserDefaults.standard.set(id.description, forKey: "lastSelectedGuild")
        }
        		.onChange(of: state.loadingState) { state in
			if state == .gatewayConn { loadLastSelectedGuild() }
		}
        .onAppear {
            if state.loadingState == .messageLoad { loadLastSelectedGuild() }

            _ = gateway.onEvent.addHandler { evt in
                switch evt {
                case .userReady(let payload):
                    state.loadingState = .gatewayConn
                    accountsManager.onSignedIn(with: payload.user)
                    // Set loading state for guilds
                    isLoadingGuilds = true
                    // Clear loading state after 10 seconds if no guilds are loaded
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        if isLoadingGuilds {
                            isLoadingGuilds = false
                        }
                    }
                    fallthrough
                case .resumed:
                    gateway.send(.voiceStateUpdate, data: GatewayVoiceStateUpdate(
                        guild_id: nil,
                        channel_id: nil,
                        self_mute: state.selfMute,
                        self_deaf: state.selfDeaf,
                        self_video: false
                    ))
                case .guildCreate(_):
                    // Handle guilds that are created after the initial READY event
                    // This is important for Nitro users with more than 100 servers
                    // The DiscordKit should handle this automatically
                    // Clear loading state after first guild is loaded
                    if isLoadingGuilds {
                        isLoadingGuilds = false
                    }
                case .guildDelete(_):
                    // Handle guild removal
                    // The DiscordKit should handle this automatically
                    break
                case .guildUpdate(_):
                    // Handle guild updates
                    // The DiscordKit should handle this automatically
                    break
                default: break
                }
            }
            _ = gateway.socket?.onSessionInvalid.addHandler { state.loadingState = .initial }
        }
        
        .sheet(isPresented: $presentingAddServer) {
            ServerJoinView(presented: $presentingAddServer)
        }
    }

    private enum ServerListItem: Identifiable {
        case guild(PreloadedGuild), guildFolder(ServerFolder.GuildFolder)

        var id: String {
            switch self {
            case .guild(let guild):
                return guild.id
            case .guildFolder(let folder):
                return folder.id
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView() // .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
