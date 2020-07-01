//
//  Post.swift
//  Scrapbook
//
//  Created by Nathan Lawrence on 7/1/20.
//  Copyright © 2020 Lachlan Campbell. All rights reserved.
//

import Foundation
import Combine

struct Post: Codable, Identifiable {
    public var id: String
    public var user: User
    public var text: String
    public var attachments: Array<Attachment>

    public var timestamp: String?
    public var timestampDate: Date? {
        return Date(timeIntervalSince1970: Double(self.timestamp ?? "0") ?? 0)
    }
}
