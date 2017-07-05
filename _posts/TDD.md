---
layout: post
title: "TDD"
date: 2017-06-29
---

## Introduction 2

Some benefits of TDD are 

- better classes which conform to the SRP, making it easier to change the code in the future
- code that works
- code that is complete - especially when it concerns non-golden paths.

In want to show you how VIPER helps you apply TDD. 

TDD employs unit testing to get the job done. In general, the hardest part of TDD is determining the size of a unit. With respect to iOS, the hardest part of unit testing is determining how to break apart a ViewController into units.  Unit testing also uses the idea of a System Under Test (SUT) - you can also call it a Class Under Test. The units to test are the public methods of the SUT.

When using VIPER, as you saw in part 3, the structure of each View is predetermined: the ViewController, the Presenter, the UseCase, the EntityGateway and the additional Transformer. Each one is an class with a very specific role. These Classes comprise most of the SUTs we need to get the job done.

