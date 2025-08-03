//
//  User+displayName.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 5/10/23.
//

import Foundation
import DiscordKitCore

extension User {
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
