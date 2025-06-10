
import Foundation
import Ignite

var formatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
} ()

struct BlogPost: ContentPage {
    func body(content: Content, context: PublishingContext) -> [any BlockElement] {
        Group {
            Text(content.title)
                .font(.title1)
                .fontWeight(.medium)
                .margin(.top, .large)
            if let date = content.metadata["date"] as? Date {
                Text(formatter.string(from: date))
                    .fontWeight(.medium)
            }
            Text("\(content.estimatedWordCount) words; \(content.estimatedReadingMinutes) minutes to read.")
                .fontWeight(.medium)

            content.body
        }
        .frame(width: "90%")
    }
}
