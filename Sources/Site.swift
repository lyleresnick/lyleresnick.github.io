import Foundation
import Ignite

@main
struct IgniteWebsite {
    static func main() async {
        let site = ExampleSite()

        do {
            try await site.publish()
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct ExampleSite: Site {    
    var name = "Hello World"
    var titleSuffix = " – Lyle Resnick"
    var url = URL(string: "https://lyleresnick.com")!
    var syntaxHighlighters = [SyntaxHighlighter.swift, .dart]
    var builtInIconsEnabled = true

    var author = "Lyle Resnick"

    var homePage = Home()
    var theme = MyTheme()
    
    var pages: [any StaticPage] {
        Blog()
        Resume()
    }
    
    var layouts: [any ContentPage] {
        BlogPost()
    }
}


