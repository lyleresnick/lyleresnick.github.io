import Foundation
import Ignite

struct Blog: StaticPage {
    @Environment(\.articles) var articles
    var title = "Blog"
    
    var body: some HTML {
        Text("Blog")
            .titleStyle()
        
        
        Grid(articles.all
            .sorted(by: {
                $0.date > $1.date
            })
             , alignment: .top/*, spacing: .none*/) { article in
            ArticlePreview(for: article)
                .articlePreviewStyle(MyBlogPreview())
                .width(6)
                .margin(.top, 20)
        }
    }
}

struct MyBlogPreview: @MainActor ArticlePreviewStyle {
    @MainActor
    func body(content: Article) -> any HTML {
        Card(imageName: content.image) {
            Text(content.description)
                .margin(.bottom, .none)
        } header: {
            Text {
                Link(content)
                    .foregroundStyle(.brandColor)
                    .textDecoration(.none)
            }
            .hoverEffect { x in
                x.textDecoration(.underline)
            }
            .font(.title4)
        } footer: {
            let tagLinks = content.tagLinks()

            if let tagLinks {
                Section {
                    ForEach(tagLinks) { link in
                        link
                    }
                }
                .margin(.top, -5)
            }

        }
    }
    
}
