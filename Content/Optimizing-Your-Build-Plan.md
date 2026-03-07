---
layout: BlogPost
date: 2026-01-13 12:00
tags: Complex TableView
---
#  Optimizing Your Build Plan

## Design

### Figma Layouts

Make file layouts small

use many pages within files so that the pages can be referred to directly . nothing is worse that having a link to a a design file that is so large one cannot see what part of the file the link was intended to point to. it should be immediately obvious to the reader once the link is followed what the target is supposed be 

one flow per page or sub flow

### Stories

story descriptions must be prescriptive

development stories are not ux stories 

a developer wants  spec for a vehicle, not a conveyance to go grocery shopping

stories should include references to apis 

see response to 

"why are people writing application development stories like they are use cases and not more like specifications"



## Jira

### Jira Structure

Jira ticket structure should be flat as possible 

you can use initiatives and Epics, but stories and tasks should be at the same level

you can reserve stories for tasks that are known before development - created by the business and tasks for dev initiated tasks 



### One Board for each team 

use of Mira goes down the toilet if more than one team is on the board

the team owns the board

### One set of stories for for each team 

if you have duplication of effort due to iOS and android being the same, duplicate the stories 



### OpenApi

deliver api specifications via Open api

this forces the users and suppliers  into an unambiguous contract

use it to generate the api client and service side interface



