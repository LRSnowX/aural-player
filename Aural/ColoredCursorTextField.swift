/*
 Customizes the color of the cursor of a text field
 */
import Cocoa

class ColoredCursorTextField: NSTextField {
    
    override func viewDidMoveToWindow() {
        
        // Change the cursor color
        
        let fieldEditor = self.window!.fieldEditor(true, for: self) as! NSTextView
        fieldEditor.insertionPointColor = Colors.textFieldCursorColor
    }
}

/*
 Customizes the color of the cursor of the search modal dialog's text field
 */
class ColoredCursorSearchField: ColoredCursorTextField {
    
    override func textDidChange(_ notification: Notification) {
        
        // Notify the search view that the query text has changed
        SyncMessenger.publishNotification(SearchTextChangedNotification.instance)
    }
}
