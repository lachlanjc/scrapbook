//
//  User.swift
//  Scrapbook
//
//  Created by Nathan Lawrence on 7/1/20.
//  Copyright © 2020 Lachlan Campbell. All rights reserved.
//

import Foundation
import Combine

struct User: Codable, Identifiable {
    public var id: String
    public var username: String
    public var streakCount: Int
    // css, slack, github, website

    public var avatar: String?
    public var avatarUrl: URL {
        guard let urlString = avatar,
              let urlParsed = URL(string: urlString) else {
            return URL(string: "https://hackclub.com/team/orpheus.jpg")!
        }
        return urlParsed
    }
}
