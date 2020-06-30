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

func formatDate(_ dt: Date) -> String {
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
        guard let urlString = thumbnails?.large?.url else { return nil }
        return URL(string: urlString)
    }
}

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
                // .aspectRatio(contentMode: .fit)
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

struct Attachments: View {
    let attachments: [Attachment]
    var images: [Attachment] {
        self.attachments.filter {
            $0.type.starts(with: "image/")
        }
    }
    // @Environment(\.imageCache) var cache: ImageCache
    
    // @ViewBuilder
    var body: some View {
        HStack(alignment: .top) {
            ForEach(images) { image in
                Group {
                    image.largeUrl.map {
                        AsyncImage(
                            url: $0,
                            placeholder: Text("Loading…").font(.caption)
                        )
                        /*
                        .frame(width: UIScreen.main.bounds.width,
                               height: UIScreen.main.bounds.height * 0.5,
                               alignment: .center) */
                    }
                }
            }
        }
    }
}

struct PostAuthorshipHeadingView: View {
    let post: Post
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(
                url: user.avatarUrl,
                placeholder: Text("…") // Circle().foregroundColor(Color.gray)
            )
            // .frame(width: 48, height: 48)
            VStack(alignment: .leading) {
                Text($0.username).fontWeight(.bold)
                HStack(alignment: .firstTextBaseline) {
                    if post.timestamp != nil {
                        Text(formatDate(post.timestampDate ?? Date()))
                    }
                    Image(systemName: "paperclip")
                    Text("\(post.attachments.count)")
                }
                .font(.caption)
                .foregroundColor(Color.gray)
            }
        }
    }
}

struct PostView: View {
    let post: Post
    
    var body: some View {
        VStack {
            postHeader
            Text(post.text)
            postAttachments
        }.fixedSize(horizontal: false, vertical: true)
    }
    
    @ViewBuilder
    var postHeader: some View {
        PostAuthorshipHeadingView(post: post, user: post.user)
    }
    
//    @ViewBuilder
//    var postBody: some View {
//
//    }
    
    @ViewBuilder
    var postAttachments: some View {
        if post.attachments.count > 0 {
            Attachments(attachments: post.attachments)
        }
    }
}

struct HomeFeed: View {
    @ObservedObject var data = FetchPosts()
    
    var body: some View {
        return NavigationView {
            List(data.posts) { post in
                PostView(post: post)
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
