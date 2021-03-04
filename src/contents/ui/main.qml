/*
    SPDX-FileCopyrightText: %{CURRENT_YEAR} %{AUTHOR} <%{EMAIL}>
    SPDX-License-Identifier: LGPL-2.1-or-later
*/

import QtQuick 2.1
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 2.0 as PlasmaComponents

Item {
    id: root
    
    property string track: ""
    property string artist: ""
    property string playerIcon: ""

    property bool noPlayer: true
    
    Plasmoid.backgroundHints: "NoBackground"

    opacity: plasmoid.configuration.opacity/100

    state: "playing"
    
    PlasmaCore.DataSource {
        id: mpris2Source
        engine: "mpris2"
        connectedSources: sources

        property string last
        onSourceAdded: {
            //print("XXX source added: " + source);
            last = source;
        }

        onSourcesChanged: {
            updateData();
        }

        onDataChanged: {
            updateData();
        }

        function updateData() {
            //print("XXX Showing data: " + last);
            var d = data[last];

            var isActive = mpris2Source.sources.length > 1;
            root.noPlayer = !isActive;
            if (d == undefined) {
                plasmoid.status = PlasmaCore.Types.PassiveStatus;
                return;
            }

            var _state = d["PlaybackStatus"];
            if (_state == "Paused") {
                root.state = "paused";
            } else if (_state == "Playing") {
                root.state = "playing";
            } else {
                root.state = "off";
            }
            plasmoid.status = root.state != "off" && isActive ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus
            var metadata = d["Metadata"]

            var track = metadata["xesam:title"];
            var artist = metadata["xesam:artist"];

            root.track = track ? track : "";
            root.artist = artist ? artist : "";

            // other metadata
            var k;
            for (k in metadata) {
                //print(" -- " + k + " " + metadata[k]);
            }
        }
    }
    function play() {
        serviceOp(mpris2Source.last, "Play");
    }

    function pause() {
        serviceOp(mpris2Source.last, "Pause");
    }

    function previous() {
        serviceOp(mpris2Source.last, "Previous");
    }

    function next() {
        serviceOp(mpris2Source.last, "Next");
    }

    function serviceOp(src, op) {
        print(" serviceOp: " + src + " Op: " + op);
        var service = mpris2Source.serviceForSource(src);
        var operation = service.operationDescription(op);
        return service.startOperationCall(operation);
    }

    states: [
        State {
            name: "off"
        },
        State {
            name: "playing"
        },
        State {
            name: "paused"
        }
    ]
    Plasmoid.fullRepresentation: ColumnLayout {
        anchors.fill: parent
        Image {
            Layout.fillHeight: true
            Layout.fillWidth: true
            fillMode: Image.PreserveAspectFit
            source: mpris2Source.data[mpris2Source.last].Metadata["mpris:artUrl"]
        }
    }
}
