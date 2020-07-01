//
//  Date+scrapbookFormat.swift
//  Scrapbook
//
//  Created by Nathan Lawrence on 7/1/20.
//  Copyright © 2020 Lachlan Campbell. All rights reserved.
//

import Foundation

extension Date {

    /**
     Date format for use on the Scrapbook timeline. Relative when the date is in the last 24 hours, absolute otherwise.
     */
    var scrapbookFormat: String {
        return Date.scrapbookFormatDate(self)
    }

    fileprivate static func scrapbookFormatDate(_ dt: Date) -> String {
        if dt.hoursAgo >= 24 {
            let absoluteFormatter = DateFormatter()
            absoluteFormatter.dateFormat = "MMM d"
            return absoluteFormatter.string(from: Date().addingTimeInterval(-1000000))
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return formatter.localizedString(for: dt, relativeTo: Date())
        }
    }

}
