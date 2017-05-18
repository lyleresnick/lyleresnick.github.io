---
layout: post
title: "Solving a Complex iOS TableView Part 2"
date: 2017-05-13
---

## Introduction

In part 1, I introduced a solution to solve A Complex tableView.

In part 2, I want to improve the Complex iOS TableView solution to simplify the code in three ways:

- remove more responsibilities from the ViewController,
- take advantage of a few key Swift features, and
- redistribute the conversion of both the input and output data.



## Responsibilities of the ViewController 

The main responsibility of a viewController is to configure the layout and content of the views contained in its view hierarchy and respond  to user interaction with those views. Pretty straightforward.

In reality, the view controller normally ends up being a repository of all of the code that the view controller is dependent on, including aspects such as:

data access, local or remote

data conversion, from source or to display

data transformation, such as grouping, summarizing or other more complex tasks

