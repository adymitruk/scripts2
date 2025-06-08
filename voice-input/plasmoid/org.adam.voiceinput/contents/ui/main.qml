import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras

Item {
    id: root
    
    property bool isRunning: false
    property var statusTimer: Timer {}
    
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    
    // Timer to check status periodically
    Timer {
        id: statusChecker
        interval: 2000  // Check every 2 seconds
        running: true
        repeat: true
        onTriggered: checkStatus()
    }
    
    // Check status on startup
    Component.onCompleted: {
        checkStatus()
    }
    
    Plasmoid.compactRepresentation: PlasmaComponents3.Button {
        id: toggleButton
        
        Layout.minimumWidth: PlasmaCore.Units.iconSizes.medium
        Layout.minimumHeight: PlasmaCore.Units.iconSizes.medium
        
        icon.name: root.isRunning ? "audio-input-microphone" : "audio-input-microphone-muted"
        text: root.isRunning ? "Stop" : "Start"
        
        // Visual indication of running state
        highlighted: root.isRunning
        
        onClicked: {
            if (root.isRunning) {
                stopVoiceInput()
            } else {
                startVoiceInput()
            }
            // Check status shortly after action
            statusDelayTimer.start()
        }
        
        PlasmaComponents3.ToolTip {
            text: root.isRunning ? "Voice input is running - Click to stop" : "Voice input is stopped - Click to start"
        }
    }
    
    // Delayed status check after actions
    Timer {
        id: statusDelayTimer
        interval: 500
        onTriggered: checkStatus()
    }
    
    function checkStatus() {
        var executable = PlasmaCore.DataEngine("executable")
        executable.connectSource("bash " + plasmoid.file("", "../code/toggle_voice_input.sh") + " status", root, "statusResult")
    }
    
    function startVoiceInput() {
        var executable = PlasmaCore.DataEngine("executable")
        executable.connectSource("bash " + plasmoid.file("", "../code/toggle_voice_input.sh") + " start", root, "startResult")
    }
    
    function stopVoiceInput() {
        var executable = PlasmaCore.DataEngine("executable")
        executable.connectSource("bash " + plasmoid.file("", "../code/toggle_voice_input.sh") + " stop", root, "stopResult")
    }
    
    // Handle status check result
    function statusResult(exitCode, exitStatus, stdout, stderr) {
        var output = stdout.trim()
        root.isRunning = (output === "running")
        console.log("Voice input status:", output, "isRunning:", root.isRunning)
    }
    
    // Handle start result
    function startResult(exitCode, exitStatus, stdout, stderr) {
        console.log("Start result:", stdout, stderr)
        statusDelayTimer.start()
    }
    
    // Handle stop result  
    function stopResult(exitCode, exitStatus, stdout, stderr) {
        console.log("Stop result:", stdout, stderr)
        statusDelayTimer.start()
    }
} 