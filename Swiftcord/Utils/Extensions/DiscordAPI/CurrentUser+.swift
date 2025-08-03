//
//  CurrentUser+.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 30/5/22.
//

import Foundation
import DiscordKitCore

extension CurrentUser {
	func avatarURL(size: Int = 160) -> URL {
		if let avatar = avatar {
			return URL(string: "\(DiscordKitConfig.default.cdnURL)avatars/\(self.id)/\(avatar).webp?size=\(size)")!
		} else {
			return URL(string: "\(DiscordKitConfig.default.cdnURL)embed/avatars/\((Int(self.discriminator) ?? 0) % 5).png")!
		}
	}
    
    var displayName: String {
        global_name ?? username
    }
    
    /// Returns the username with discriminator only if discriminator is not "0"
    var displayNameWithDiscriminator: String {
        if discriminator == "0" {
            return username
        } else {
            return "\(username)#\(discriminator)"
        }
    }
    
    /// Returns the full username with discriminator for copying purposes
    var fullUsername: String {
        "\(username)#\(discriminator)"
    }
}
