import Foundation
import Ignite

struct MyTheme: Theme {
    static let brandColor = "#2ccabd"
    
    func render(page: Page, context: PublishingContext) -> HTML {
        HTML {
            Head(for: page, in: context)

            Body {
                NavigationBar(logo: "Lyle Resnick") {
                    Link("Blog", target: Blog())
                    Link("Resume", target: Resume())
                }
                .background(MyTheme.brandColor)
                    .navigationBarStyle(.dark)
                    .navigationItemAlignment(.trailing)
                    .position(.fixedTop)
                Spacer(size: 54)
                page.body

                Footer()
            }
        }
    }
}

public struct Footer: Component {
    public init() { }

    public func body(context: PublishingContext) -> [any PageElement] {
        Spacer(size: 30)
        Section {
            Text("Lyle Resnick")
                .margin(0)
                .style("color: \(MyTheme.brandColor)")

            Text {
                Span("&#128231 ")
                Link("Email me", target: "mailto:lyle@cellarpoint.com")
                    .foregroundStyle(MyTheme.brandColor)
                    .textDecoration(.none)
                    .hoverEffect { x in
                        x.textDecoration(.underline)
                    }

            }
            .horizontalAlignment(.center)

            Text {
                Image("/images/github-mark.svg", description: "github mark")
                    .frame(height: 14)
                Span(" ")
                Link("Github", target: "https://github.com/lyleresnick")
                    .margin(0)
                    .foregroundStyle(MyTheme.brandColor)
                    .textDecoration(.none)
                    .hoverEffect { x in
                        x.textDecoration(.underline)
                    }

            }
            .horizontalAlignment(.trailing)

        }
    }
}
