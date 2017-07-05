---
layout: post
title: "Solving a Complex iOS TableView with Test Driven VIPER"
date: 2017-07-05
---

## Introduction

In [part 3]({{site.url}}/blog/2017/05/13/Solving-a-Complex-iOS-TableView-with-Test-Driven-VIPER.html) of this article, I showed how the solution of [part 2]({{site.url}}/blog/2017/06/29/Solving-a-Complex-iOS-TableView-Part-2.html) could very easily be refactored into a VIPER framework. In this article, I want to show how the solution would be constructed via Test Driven Development (TDD).

The complete app which demonstrates this refactoring can be found at [**CleanTDDReportTableDemo**](https://github.com/lyleresnick/CleanTDDReportTableDemo). The app which I will be refactoring can be found at [**CleanReportTableDemo**](https://github.com/lyleresnick/CleanReportTableDemo).