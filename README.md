Dry questions: 
1. The SnappingSheetController class is used. Now, the developer can control the sheet in multiple ways: 
 - Snap to a given snapping position
 - Stop the current snapping 
 - Set the position of the snapping sheet 
 - Extract information from the sheet such as the current position and the current snaping position 
 - To know if the snapping sheet is currently trying to snap to a position

2. To snap to a given position we use the method snapToPosition that receives a parameter of type SnappingPosition. This parameter controls the behavior of the animation such as the duration, animation curve, and the snapping position alignment. 

3. Advantage of InkWell over GestureDetector: the first one includes a visual effect when tapping the component, call by the documentation “clip splashes”. The animation adds a grey shadow to the widget which let the user know that he pressed the widget. 
Advantage of GestureDetector over InkWell: GestureDetector provides more gestures, it is possible to detect every type of interaction that the user has with the screen while using it, including pinch, swipe and touch.
