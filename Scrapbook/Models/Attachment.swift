//
//  Attachment.swift
//  Scrapbook
//
//  Created by Nathan Lawrence on 7/1/20.
//  Copyright © 2020 Lachlan Campbell. All rights reserved.
//

import Foundation
import Combine

struct Attachment: Codable, Identifiable {
    public var id: String
    public var url: String
    public var type: String
    public var filename: String
    public var thumbnails: ThumbnailCollection?
    public var largeUrl: URL? {
        guard let urlString = thumbnails?.large?.url else { return nil }
        return URL(string: urlString)
    }
}
