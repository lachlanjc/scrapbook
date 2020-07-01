//
//  ScrapbookDataService.swift
//  Scrapbook
//
//  Created by Nathan Lawrence on 7/1/20.
//  Copyright © 2020 Lachlan Campbell. All rights reserved.
//

import Foundation
import Combine

class ScrapbookDataService: ObservableObject {
    @Published var posts = [Post]()

    init() {
        let url = URL(string: "https://scrapbook.hackclub.com/api/posts/")!
        URLSession.shared.dataTask(with: url) { (data, res, error) in
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            do {
                if let postsData = data {
                    let decodedData = try decoder.decode([Post].self, from: postsData)
                    DispatchQueue.main.async {
                        self.posts = decodedData
                    }
                } else {
                    print("No data")
                }
            } catch {
                print("Error \(error)")
            }
        }.resume()
    }
}
