//
//  GetUserAvatarURL.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 25/2/22.
//

import Foundation
import DiscordKitCore

extension User {
    func avatarURL(size: Int = 160) -> URL {
		if let avatar = avatar {
			return avatar.avatarURL(of: id, size: size)
		} else { return HashedAsset.defaultAvatar(of: discriminator) }
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
