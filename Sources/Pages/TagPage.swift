//
// TagPage.swift
import Foundation
import Ignite

struct Tags: TagPage {
    var body: some HTML {
        Spacer(size: 30)
        Text(tag.name)
            .font(.title1)

        List {
            ForEach(tag.articles) { article in
                Text {
                    Link(article)
                        .foregroundStyle(.brandColor)
                }
            }
        }
    }
}
