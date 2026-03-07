---
layout: BlogPost
date: 2026-03-07 12:00
tags: SwiftUI
---

# Building a Robust Network Layer



design of the networking layer is one the the most important aspects contributing to robust and resilient mobile applications

in many projects,  responsibility for error processing is left to the domain code 

or, worse, are left undiagnosed

it is common to allow mandatory fields in JSON responses to be null even when the API contract states that they should never be null

it is also common that expected "errors" are not determined until data is processed by the domain code, when it is possible to predetermine, to the point of making the expectation compilable

when nulls and errors are processed within the domain code the developer is burdened with processing expected and unexpected null values and errors while coding the domain 

Questions like the following have to be revisited every time code is read or modified:

- do nulls imply its optional  and thats ok or the value is outright missing? 
- what does one do when the value is missing?
- why is it missing ?
- is the error expected? 
- how does the dev determine if an error is expected?
- who in the org should be aware that there is an unexpected error occurring?
- how does the org become aware to the unexpected error issue?
- how should we respond to the user when something unexpected occurs?













diagnose issues at their origin (all in one place)

issues on the client side are are:

- 
- connectivity

issues on the server side are:

- payload formatting



networking only - not business domain







- 









A Robust app must be able to respond correctly to known but unusual data conditions, and that it can determine when data is incorrect 

Here Resilient means the the app can respond correctly unforeseen network conditions











- optionals 
  - must be truly optional in the domain
  - if the spec says it not optional the networking layer must throw an error with the description of the missing data
  -  ensures that the BE will provide what is specified in the contract
  - diagnosis can be sent to analytics