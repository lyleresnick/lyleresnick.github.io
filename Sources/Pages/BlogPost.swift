
import Foundation
import Ignite

var formatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
} ()

struct BlogPost: ArticlePage {
    var body: some HTML {
        Group {
            Text(article.title)
                .font(.title1)
                .fontWeight(.medium)
                .margin(.top, .large)
            if let date = article.metadata["date"] as? Date {
                Text(formatter.string(from: date))
                    .fontWeight(.medium)
            }
            Text("\(article.estimatedWordCount) words; \(article.estimatedReadingMinutes) minutes to read.")
                .fontWeight(.medium)

            Text(article.text)
        }
        .frame(width: .percent(Percentage(90)))
    }
}
