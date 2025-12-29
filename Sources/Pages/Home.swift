import Foundation
import Ignite

struct Home: StaticPage {
    var title = "Home"

    var body: some HTML {
        Text("I'm Lyle Resnick")
            .titleStyle()
        
        Group {
            Text(markdown:
"""
I develop iOS and Flutter mobile applications. I think software code quality is very important.
<br><br>
Currently, my primary interests are *Clean Mobile Architecture* and *Test Driven Development*. My experience has shown me that these two techniques work well together to produce software that is easy to change and free of bugs.
 <br><br>
I have over thirty years of software experience.  Some of my major technical accomplishments include the development of commercial compilers, window systems, and forms frameworks for both desktop & mobile.
  <br><br>
I have written a lot of software. In Mobile development, I have acted as lead and developer of apps for:
 
- Social Networking
- Banking
- Insurance
- Retail, and
- Restaurant

In web and desktop development, I have acted as development lead and developer of applications for:
  <br>
- Restaurant
- Commercial Foreign Exchange
- Securities, and
- Banking
"""
            )
            .font(.body)
        }
//        .frame(maxWidth: "90%")
    }
}


extension Text {
    func titleStyle() -> some HTML {
        self
            .font(.title2)
            .fontWeight(.light)
            .margin(.top, .large)
    }
}
