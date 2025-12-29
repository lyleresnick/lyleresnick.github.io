import Foundation
import Ignite

@main
struct IgniteWebsite {
    static func main() async {
        var site = LyleRenickSite()

        do {
            try await site.publish()
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct LyleRenickSite: Site {    
    var name = "Hello World"
    var titleSuffix = " – Lyle Resnick"
    var url = URL(static: "https://lyleresnick.com")
    var builtInIconsEnabled = true
    var syntaxHighlighterConfiguration = SyntaxHighlighterConfiguration(languages: [.swift, .dart])
    var author = "Lyle Resnick"

    var homePage = Home()
    var layout = MainLayout()
    var tagPage = Tags()

    var staticPages: [any StaticPage] {
        Blog()
        Resume()
    }
    
    var articlePages: [any ArticlePage] {
        BlogPost()
    }
}


