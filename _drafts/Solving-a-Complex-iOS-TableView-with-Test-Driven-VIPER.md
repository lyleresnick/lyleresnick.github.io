---
layout: post
title: "Solving a Complex iOS TableView with Test Driven VIPER"
date: 2017-07-05
---

## Introduction

In [part 3]({{site.url}}/blog/2017/05/13/Solving-a-Complex-iOS-TableView-with-Test-Driven-VIPER.html) of this article, I showed how the solution of [part 2]({{site.url}}/blog/2017/06/29/Solving-a-Complex-iOS-TableView-Part-2.html) could very easily be refactored into a VIPER framework. In this article, I want to show how the solution would be constructed via Test Driven Development (TDD).

The complete app which demonstrates this refactoring can be found at [**CleanTDDReportTableDemo**](https://github.com/lyleresnick/CleanTDDReportTableDemo). The app which I will be refactoring can be found at [**CleanReportTableDemo**](https://github.com/lyleresnick/CleanReportTableDemo).

Some of the benefits of TDD are 

- a focus on classes which conform to the SRP make it easier to change the code in the future
- bugs are uncovered very early in the process so the code just works
- refactoring is safe because passing tests ensure that refactoring is done correctly 
- code is complete because there is no bias towards testing only the golden path
- for code driven by events from sensors, you do not have to rely on actual data from the sensors

I want to show you how VIPER helps you apply TDD. 

TDD employs unit testing to get the job done. In general, the hardest part of TDD is determining the size of a unit. With respect to iOS, the hardest part of unit testing is determining how to break a ViewController into testable units.  

Unit testing employs the idea of a System Under Test (SUT). You could also refer to it as a Class Under Test. A unit is a public method of a SUT. 

Breaking a ViewController into many coordinated classes is a practice which yields many *seam*s. A seam is a place in the code where one class sends a message to another class.

As you saw in part 3, by using the VIPER architecture, the structure of each View is already broken up in to many classes: the ViewController, the Presenter, the UseCase, the EntityGateway, the Router and the additional Transformer. Each one is an class with a very specific role. These classes comprise most of the SUTs we need to get the job done. It also presents a plethora of predetermined seams - just what we need.

The one thing that you need to know about TDD is that even though you write the tests first, you need to have an overall plan - VIPER starts you off with a macro-plan in which you can fit your own plan. Its kind of  like TDD and VIPER were made for one another.

## So Lets Get Started

The usual question is where do I start.  Once you get used to the TDD process you can start pretty much wherever you like. 

I suggest that you start with the simplest tests you can do.

The first thing Im going to do is create the major  

