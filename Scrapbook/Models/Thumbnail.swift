//
//  Thumbnail.swift
//  Scrapbook
//
//  Created by Nathan Lawrence on 7/1/20.
//  Copyright © 2020 Lachlan Campbell. All rights reserved.
//

import Foundation
import Combine

struct Thumbnail: Codable, Identifiable {
    public var id: String {
        return url
    }
    public var url: String
    public var width: Int
    public var height: Int
}

struct ThumbnailCollection: Codable, Identifiable {
    public var id: String {
        return "thumbnails-\(full?.url ?? UUID().uuidString)"
    }
    public var small: Thumbnail?
    public var large: Thumbnail?
    public var full: Thumbnail?
}
