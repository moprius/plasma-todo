import QtQuick
import QtQuick.Controls

Item {    
    id: inputItem                                                                                                                                                                                                                               
    width: parent ? parent.width * 0.9 : 270                                                                                         
    height: inputTextArea.contentHeight + 8                                                                                                                                                                                                                                                                                                                    
    anchors.horizontalCenter: parent.horizontalCenter 

    property var thisModel

    TextArea {                                                                                                                      
        id: inputTextArea                                                                                                               
        anchors.fill: parent                                                                                                        
        font.pixelSize: 18                                                                                                   
        color: "white" 
        horizontalAlignment: TextArea.AlignHCenter                                                                                  
        verticalAlignment: TextArea.AlignVCenter                                                                                    
        wrapMode: TextArea.Wrap 
        
        background: Rectangle {
            anchors.fill: parent   
            height: parent.height + 30                                           
            radius: 10                                                           
            opacity: 0.3                                                         
            color: "black"                                                        
        }                                                                                                                                                                                                                                                                                                                            

        Keys.onReturnPressed: {  
            var input = {}
            input.text = inputTextArea.text
            input.color = "white"
            input.checked = false
            input.pinned = false
            input.sublist = []
            input.markdown = ""

            // New regular tasks are inserted directly below the pinned group.
            var insertIndex = 0
            while (insertIndex < thisModel.count
                    && Boolean(thisModel.get(insertIndex).pinned)) {
                insertIndex++
            }
            thisModel.insert(insertIndex, input)
            saveModelToJson("todoListModel", todoListModel)
            inputTextArea.text = ""                                                                                                                                                                         
        }                                                                                                                                                                                                                                                                                                               
    } 
} 