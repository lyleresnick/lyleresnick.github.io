---
layout: post
title: "Solving a Complex iOS TableView with Test Driven VIPER"
date: 2017-07-05
---

## Introduction

In [part 3]({{site.url}}/blog/2017/05/13/Solving-a-Complex-iOS-TableView-with-Test-Driven-VIPER.html) of this article, I showed how the solution of [part 2]({{site.url}}/blog/2017/06/29/Solving-a-Complex-iOS-TableView-Part-2.html) could very easily be refactored into a VIPER framework. In this article, I want to show how the solution would be constructed via Test Driven Development (TDD).

The complete app which demonstrates this refactoring can be found at [**CleanTDDReportTableDemo**](https://github.com/lyleresnick/CleanTDDReportTableDemo). The app which I will be refactoring can be found at [**CleanReportTableDemo**](https://github.com/lyleresnick/CleanReportTableDemo).

## Benefits of TDD

Some benefits of TDD are 

- better classes which conform to the SRP, making it easier to change the code in the future
- code that works
- code that is complete - especially when it concerns non-golden paths.

In want to show you how VIPER helps you apply TDD. 

TDD employs unit testing to get the job done. In general, the hardest part of TDD is determining the size of a unit. With respect to iOS, the hardest part of unit testing is determining how to break apart a ViewController into units.  Unit testing also uses the idea of a System Under Test (SUT) - you can also call it a Class Under Test. The units to test are the public methods of the SUT.

When using VIPER, as you saw in part 3, the structure of each View is predetermined: the ViewController, the Presenter, the UseCase, the EntityGateway and the additional Transformer. Each one is an class with a very specific role. These Classes comprise most of the SUTs we need to get the job done.

