//
//  ContentView.swift
//  Scrapbook
//
//  Created by Lachlan Campbell on 6/28/20.
//  Copyright © 2020 Lachlan Campbell. All rights reserved.
//


import SwiftUI
import Combine
import UIKit
import Foundation

struct User: Codable, Identifiable {
    public var id: String
    public var username: String
    public var avatar: String
    public var streakCount: Int
    // css, slack, github, website
}

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

struct Attachment: Codable, Identifiable {
    public var id: String
    public var url: String
    public var type: String
    public var filename: String
    public var thumbnails: ThumbnailCollection?
    public var largeUrl: URL? {
        guard let urlString = thumbnails?.large?.url else {
            return nil
        }
        return URL(string: urlString)
    }
}

struct Post: Codable, Identifiable {
    public var id: String
    public var user: User?
    public var text: String
    public var postedAt: Date?
    public var attachments: Array<Attachment>
}

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private let url: URL
    private var cancellable: AnyCancellable?
    
    init(url: URL) {
        self.url = url
    }
    
    deinit {
        cancellable?.cancel()
    }
    
    func load() {
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .assign(to: \.image, on: self)
    }
    
    func cancel() {
        cancellable?.cancel()
    }
}

struct AsyncImage<Placeholder: View>: View {
    @ObservedObject private var loader: ImageLoader
    private let placeholder: Placeholder?
    
    init(url: URL, placeholder: Placeholder? = nil) {
        loader = ImageLoader(url: url)
        self.placeholder = placeholder
    }
    
    var body: some View {
        image
            .onAppear(perform: loader.load)
            .onDisappear(perform: loader.cancel)
    }
    
    @ViewBuilder
    private var image: some View {
        loader.image.map {
            Image(uiImage: $0)
                .resizable()
        }
        if loader.image == nil {
            placeholder
        }
    }
}

class FetchPosts: ObservableObject {
    @Published var posts = [Post]()
    
    init() {
        let url = URL(string: "https://scrapbook.hackclub.com/api/posts/")!
        URLSession.shared.dataTask(with: url) { (data, res, error) in
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            do {
                if let postsData = data {
                    let decodedData = try decoder.decode([Post].self, from: postsData)
                    DispatchQueue.main.async {
                        self.posts = decodedData
                    }
                } else {
                    print("No data")
                }
            } catch { print("Error") }
        }.resume()
    }
}

/*
 static let postedAtFormat: DateFormatter = {
 let formatter = DateFormatter()
 formatter.dateStyle = .short
 return formatter
 }()
 */
/*
 Text("\(post.postedAt, formatter: Self.postedAtFormat)")
 */

struct Attachments: View {
    let attachments: [Attachment]
    var images: [Attachment] {
        self.attachments.filter {
            $0.type.starts(with: "image/")
        }
    }
    // @Environment(\.imageCache) var cache: ImageCache
    
    @ViewBuilder
    var body: some View {
        HStack(alignment: .top) {
            ForEach(images) { image in
                Group {
                    image.largeUrl.map {
                        AsyncImage(
                            url: $0,
                            placeholder: Text("Loading…").font(.caption)
                        ).aspectRatio(contentMode: .fit)
                    }
                }
            }
        }
    }
}

struct HomeFeed: View {
    @ObservedObject var data = FetchPosts()
    
    var body: some View {
        return NavigationView {
            List(data.posts) { post in
                VStack(alignment: .leading) {
                    Text(post.text)
                    HStack(alignment: .firstTextBaseline) {
                        /*
 if post.postedAt != nil {
 Image(systemName: "calendar")
 Text(post.postedAt ?? "lol")
 }
 */
                        Image(systemName: "paperclip")
                        Text("\(post.attachments.count) attachment\(post.attachments.count != 1 ? "s" : "")")
                    }
                    .font(.caption)
                    .foregroundColor(Color.gray)
                    if (post.attachments.count > 0) {
                        Attachments(attachments: post.attachments)
                    }
                }.fixedSize(horizontal: false, vertical: true)
            }
            .navigationBarTitle(Text("Scrapbook"))
            .listStyle(GroupedListStyle())
            .environment(\.horizontalSizeClass, .regular)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView: View {
    var body: some View {
        HomeFeed()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeFeed()
    }
}
