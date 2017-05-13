---
layout: post
title: "Towards Better iOS App Architecture"
date: 2016-11-19
---

Have you noticed that your less than one year old iOS project has become hard to maintain? There are 40 to 50 ViewControllers. The controllers are a thousand lines long. Every time you have to change a feature and it takes more than 2 hours just to figure out it's scope - or maybe it takes 2 days, because the feature's state has leaked into some other controller - or view!

In an agile team culture, your app goes through a ton of changes. Due to time constraints, it is easy to accumulate a lot of technical debt. 

Apps I've worked on contain 6 to 12 major stories, each containing 4 or more scenes. Some of the stories can even start other stories with contextual data. It gets pretty complicated, pretty fast. 

My current area of interest is exploring solutions that help reduce the complexity caused by the constant effects of change on iOS software. 

My blog is about some of the solutions I have found that help to reduce this complexity. All of these solutions are structural, meaning that they make use of Classes and Patterns.  

Some of the topics I plan to talk about are:

- Reducing the the size of a Massive View Controller  
- Planning a Story Navigation Architecture
- Transforming Data Streams to UITableViews
- Working at the Highest Level of Abstraction
- Using Interface Builder Effectively
- Using Swift in all of this













