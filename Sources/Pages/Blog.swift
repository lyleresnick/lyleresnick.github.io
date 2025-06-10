import Foundation
import Ignite

struct Blog: StaticPage {
    var title = "Blog"
    
    func body(context: PublishingContext) -> [BlockElement] {
        Text("Blog")
            .titleStyle()
        
        Section {
            for content in context.allContent
                .sorted(by: {
                    $0.date > $1.date
                }) {
                ContentPreview(for: content)
                    .contentPreviewStyle(MyBlogPreview())
                    .margin(.top, 20)
            }
        }
        .columns(2)
    
    }
    
}

struct MyBlogPreview: ContentPreviewStyle {
    func body(content: Content, context: PublishingContext) -> any BlockElement {
        Card(imageName: content.image) {
            Text(content.description)
                .margin(.bottom, .none)
        } header: {
            Text {
                Link(content)
                .foregroundStyle(MyTheme.brandColor)
                .textDecoration(.none)
                .hoverEffect { x in
                    x.textDecoration(.underline)
                }

            }
            .font(.title2)
        } footer: {
            let tagLinks = content.tagLinks(in: context)

            if tagLinks.isEmpty == false {
                Group {
                    tagLinks
                }
                .style("margin-top: -5px")
            }
        }
    }
    
}
