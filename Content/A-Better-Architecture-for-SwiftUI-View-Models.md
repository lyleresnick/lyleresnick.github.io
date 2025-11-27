# A Better architecture for SwiftUI view models  
  
**An Idea from Flutter**  
  
From experience with flutter blocs  
each vm has a single read only protected (set) @Published property, say called *output*,  
Output is an enum of panel related states like normal, error,  loading, partN, none, etc  
All other properties are protected  
  
**Use an emitter wrapper function**  
  
Use an normal emitter wrapper function to emit the normal state to the output  
  
This function copies the private state to the normal formatted output,   
To output temporary views like message ,  wait indicators, overlays, use optional or Boolean and set them as parameters to the formatted output - do not add them to the state enum   
also can do the same for errors  
(Better yet make the private state be the same enum type and use *copyWith* for changes)  
  
In most cases the main enum state can contain the substates representing the state of Subsections  
The main state determines the overall page state so the main presentation of interest must succeed or an overarching error is shown   
  
**Optimizing for performance or reuse**  
  
If there are performance requirements due to very large screen layouts or other requirements like reusable views that have dedicated sub vms  
Sub view models can be used to represent subsections of the screen; each one implemented like a main vm having one output   
Subviewmodels can be delivered as internal properties of the  main view model   
The main view model instantiates the sub view models  
  
  
**Why this is better **  
  
Using the enum gets rid of bugs caused by undefined state - is using null or having arrays or strings being set to empty really a good idea when you can just remove the uncertainty with an enum?   
  
Handling temporary views is way simpler because the show or no show status for these views is, unless explicitly specified to be shown, always automatically reset to no show at each emit   
  
Way easier to test since in the simplest case all data is in a single enum that changes over time   
It is much simpler to make a protocol for mocking the vm that has one property and reuses the enum from the non-mocked vm  
  
  
  
  
  
  
  
