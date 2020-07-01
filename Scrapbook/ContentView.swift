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

protocol ImageCache {
    subscript(_ url: URL) -> UIImage? { get set }
}

struct TemporaryImageCache: ImageCache {
    private let cache = NSCache<NSURL, UIImage>()
    
    subscript(_ key: URL) -> UIImage? {
        get { cache.object(forKey: key as NSURL) }
        set { newValue == nil ? cache.removeObject(forKey: key as NSURL) : cache.setObject(newValue!, forKey: key as NSURL) }
    }
}

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    
    private(set) var isLoading = false
    
    private let url: URL
    private var cache: ImageCache?
    private var cancellable: AnyCancellable?
    
    private static let imageProcessingQueue = DispatchQueue(label: "image-processing")
    
    init(url: URL, cache: ImageCache? = nil) {
        self.url = url
        self.cache = cache
    }
    
    deinit {
        cancellable?.cancel()
    }
    
    func load() {
        guard !isLoading else { return }

        if let image = cache?[url] {
            self.image = image
            return
        }
        
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .handleEvents(receiveSubscription: { [weak self] _ in self?.onStart() },
                          receiveOutput: { [weak self] in self?.cache($0) },
                          receiveCompletion: { [weak self] _ in self?.onFinish() },
                          receiveCancel: { [weak self] in self?.onFinish() })
            .subscribe(on: Self.imageProcessingQueue)
            .receive(on: DispatchQueue.main)
            .assign(to: \.image, on: self)
    }
    
    func cancel() {
        cancellable?.cancel()
    }
    
    private func onStart() {
        isLoading = true
    }
    
    private func onFinish() {
        isLoading = false
    }
    
    private func cache(_ image: UIImage?) {
        image.map { cache?[url] = $0 }
    }
}

struct AsyncImage<Placeholder: View>: View {
    @ObservedObject private var loader: ImageLoader
    private let placeholder: Placeholder?
    private let configuration: (Image) -> Image

    init(url: URL, cache: ImageCache? = nil, placeholder: Placeholder? = nil, configuration: @escaping (Image) -> Image = { $0 }) {
        loader = ImageLoader(url: url, cache: cache)
        self.placeholder = placeholder
        self.configuration = configuration
    }

    var body: some View {
        image
            .onAppear(perform: loader.load)
            .onDisappear(perform: loader.cancel)
    }
    
    @ViewBuilder
    private var image: some View {
        loader.image.map {
            configuration(Image(uiImage: $0).resizable())
//                .aspectRatio(contentMode: .fit)
        }
        if loader.image == nil {
            placeholder
        }
    }
}

struct AttachmentsView: View {
//    @Environment(\.imageCache) var cache: ImageCache

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
        HStack(alignment: .center, spacing: 12) {
            AsyncImage(
                url: user.avatarUrl,
                placeholder: Circle().foregroundColor(Color.gray)
            )
            .frame(width: 48, height: 48, alignment: .center)
            .mask(Circle())
            VStack(alignment: .leading) {
                Text(user.username).fontWeight(.bold)
                HStack(alignment: .firstTextBaseline) {
                    if post.timestamp != nil {
                        Text(post.timestampDate?.scrapbookFormat ?? "")
                    }
                    Image(systemName: "paperclip")
                    Text("\(post.attachments.count)")
                }
                .font(.caption)
                .foregroundColor(Color.gray)
            }
            Spacer()
        }
    }
}

struct PostView: View {
    let post: Post
    
    var body: some View {
        VStack {
            postHeader
            postBody
            postAttachments
        }
    }
    
    @ViewBuilder
    var postHeader: some View {
        PostAuthorshipHeadingView(post: post, user: post.user)
    }
    
//    @ViewBuilder
    var postBody: some View {
        Text(post.text)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    var postAttachments: some View {
        if post.attachments.count > 0 {
            AttachmentsView(attachments: post.attachments)
        }
    }
}

struct HomeFeed: View {
    @ObservedObject var data = ScrapbookDataService()
    
    var body: some View {
        return NavigationView {
            List(data.posts) { post in
                PostView(post: post)
            }
            .navigationBarTitle(Text("Scrapbook"))
//            .listStyle(GroupedListStyle())
//            .environment(\.horizontalSizeClass, .regular)
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
