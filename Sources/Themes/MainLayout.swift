import Foundation
import Ignite

struct MainLayout: Layout {
    
    var body: some Document {
        Body {
            NavigationBar(logo: "Lyle Resnick") {
                Link("Blog", target: Blog())
                Link("Resume", target: Resume())
            }
                .navigationBarStyle(.dark)
                .navigationItemAlignment(.trailing)
                .background(.brandColor)
                .position(.fixedTop)
            Spacer(size: 54)
            content
                .frame(width: .percent(Percentage(95)))
                .frame(alignment: .center)
            Footer()
        }
    }
}

public struct Footer: HTML {
    public init() { }

    public var body: some HTML {
        VStack {
            Spacer(size: 30)
            HStack {
                Text("Lyle Resnick")
                    .margin(.none)
                    .foregroundStyle(Color.brandColor)
                Spacer()
                Text {
                    Span("&#128231 ")
                    Link("Email me", target: "mailto:lyle@cellarpoint.com")
                        .foregroundStyle(.brandColor)
                        .textDecoration(.none)
                }
                .hoverEffect { x in
                    x.textDecoration(.underline)
                }
                Spacer()
                Text {
                    Image("/images/github-mark.svg", description: "github mark")
                        .frame(height: 14)
                    Span(" ")
                    Link("Github", target: "https://github.com/lyleresnick")
                        .margin(0)
                        .foregroundStyle(.brandColor)
                        .textDecoration(.none)
                }
                .hoverEffect { x in
                    x.textDecoration(.underline)
                }
                
            }
            .frame(width: .percent(Percentage(90)))
            Spacer(size: 20)
        }
    }
}


extension Color {
    static let brandColor = Color(hex: "#2ccabd")
}
