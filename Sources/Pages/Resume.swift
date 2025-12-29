import Foundation
import Ignite

struct Job: Decodable {
    var title: String
    var company: String
    var location: String
    var date: String
    var application: String
}

struct Resume: StaticPage {
    @Environment(\.decode) var decode

    var title = "Resume"

    var body: some HTML {
        Text("My Resume")
            .titleStyle()
        
        if let jobs = decode("cv.json", as: [Job].self) {
//            Group {
                for job in jobs {
                    Card {
                        Text(job.title)
                            .margin(0)
                            .fontWeight(.semibold)
                        Text {
                            "\(job.company), \(job.location), "
                            Emphasis {
                                job.date
                            }
                        }
                            .margin(0)
                        Spacer()
                        Text(job.application)
                            .margin(0)

                    }
                    .margin(.top, 20)
                }
//            }
        }
    }
        
}
