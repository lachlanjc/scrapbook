//
//  Date+TimeBefore.swift
//  Scrapbook
//
//  Created by Nathan Lawrence on 7/1/20.
//  Copyright © 2020 Lachlan Campbell. All rights reserved.
//

import Foundation

extension Date {

    func isBefore(date : Date) -> Bool {
        return self < date
    }

    func isAfter(date : Date) -> Bool {
        return self > date
    }

    var secondsAgo : Double {
        get {
            return -(self.timeIntervalSinceNow)
        }
    }

    var minutesAgo : Double {
        get {
            return (self.secondsAgo / 60)
        }
    }

    var hoursAgo : Double {
        get {
            return (self.minutesAgo / 60)
        }
    }

    var daysAgo : Double {
        get {
            return (self.hoursAgo / 24)
        }
    }

    var weeksAgo : Double {
        get {
            return (self.daysAgo / 7)
        }
    }

}
