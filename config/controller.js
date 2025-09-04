function Controller() {
    installer.setDefaultPageVisible(QInstaller.StartMenuSelection, false);
    var page = gui.pageWidgetByObjectName("TargetDirectoryPage");
    if (page) {
        page.entered.connect(this.TargetPageEntered);
    }
};


function normalizePath(path) {
    // Convert forward slashes to backslashes
    var backslashPath = path.replace(/\//g, "\\");
    return backslashPath.replace(/\\/g, "\\\\");
};
function isFolderEmpty(path) {
    var path = normalizePath(path);
    var command = "Get-ChildItem -Name \"" + path + "\" | Out-String";
    var result = installer.execute("powershell", ["-Command", command]);
    var exitCode = result[1];
    var stdout = result[0];

    console.log("xxxxxxxxxxxxxxxxxxxxxxx" + result + command);
    var stdout = stdout.trim();
    if (stdout === "" && exitCode === 0) {
        console.log("⚠️ Folder Empty " + stdout);
        return true;
    }
    else {
        console.log("⚠️ Folder Not exist or not empty" + stdout);
        return false;
    }
}

Controller.prototype.TargetPageEntered = function () {
    var page = gui.pageWidgetByObjectName("TargetDirectoryPage");
    if (!page) return;
    // create a custom label once
    var default_dir = installer.value("TargetDir")
    var isEmpty = isFolderEmpty(default_dir);
    if (!isEmpty) {
        page.MessageLabel.text = "<font color='red'>❌ The selected folder is not empty or contains a previous installer:" + default_dir + "<br/>Please chose a different</font>";
    };
    page.MessageLabel.setText("Available space: " + "0" + " GB");
    if (!page._connected) {
        page.TargetDirectoryLineEdit.textChanged.connect(function (newText) {
            var isEmpty = isFolderEmpty(newText);
            if (!isEmpty) {
                page.MessageLabel.text = "<font color='red'>❌ The selected folder is not empty or contains a previous installer:" + newText + "<br/>Please chose a different</font>";
                // reset to empty or default, so Next won't proceed (do the trick)
                // page.TargetDirectoryLineEdit.text = installer.value("TargetDir");
                // installer.setValue("TargetDir", "");
            } else {
                page.MessageLabel.setText("Available space: " + "0" + " GB");
            }
        });
        page._connected = true;
    }
};


Controller.prototype.IntroductionPageCallback = function () {
    var widget = gui.currentPageWidget();
    if (!widget) return;
    var version = installer.value("Version");

    // Professional HTML styling
    var message = `
        <div style="font-family: 'Segoe UI', sans-serif; text-align: left; padding: 10px;">
            <h2 style="margin-bottom: 5px;">Welcome to ROX Installer</h2>
            <p style="font-size: 14px; margin: 0;">Version <strong>${version}</strong></p>
            <hr style="margin: 10px 0; border: none; border-top: 1px solid #ccc;">
            <p style="font-size: 13px;">
                This setup will guide you through the installation of ROX software. 
                Please follow the steps carefully to ensure a successful installation.
            </p>
        </div>
    `;

    widget.MessageLabel.setText(message);
    widget.title = "Welcome";

};



// ---- helpers ---------------------------------------------------------------
function isComponentSelected(c) {
    try {
        // Preferred: numeric selectionState (2 == Selected)
        if (typeof c.selectionState !== "undefined") {
            // Some builds expose QInstaller.Selected, others just use 2
            if (typeof QInstaller !== "undefined" && typeof QInstaller.Selected !== "undefined")
                return c.selectionState === QInstaller.Selected;
            return c.selectionState === 2; // Qt.Checked / Selected
        }

        // Some builds expose checkState like Qt.Checked (2)
        if (typeof c.checkState !== "undefined") return c.checkState === 2;

        // Older wrappers may still have isSelected()
        if (typeof c.isSelected === "function") return c.isSelected();

        // Maintenance/plan-ready builds sometimes expose installationRequested()
        if (typeof c.installationRequested === "function") return c.installationRequested();

        // Last-ditch: IFW sometimes stores a string "true"/"false" in a value
        var v = c.value && c.value("Selected");
        if (typeof v === "string") return v.toLowerCase() === "true";
    } catch (e) { /* ignore */ }
    return false;
}

function readEstimatedSizeMB(estimateSize) {
    // Prefer your custom metadata (UserData in package.xml)
    var s = estimateSize;
    var n = parseFloat(s);
    if (!isNaN(n)) return n; // already in MB per your plan

    // Fallbacks (if you didn't set EstimatedSize):
    // Some versions expose installedSize() via script; if present it returns bytes
    if (typeof c.installedSize === "function") {
        var bytes = c.installedSize();
        if (bytes > 0) return bytes / (1024 * 1024);
    }
    // If nothing available, treat as 0
    return 0;
}

function fmtMB(x) {
    // One decimal, but show 0 without “-0.0”
    var v = Math.round(x * 10) / 10;
    if (Math.abs(v) < 0.05) return "0 MB";
    return v.toFixed(1) + " MB";
}

// ---- Ready page customization ----------------------------------------------
Controller.prototype.ReadyForInstallationPageCallback = function () {
    var page = gui.pageWidgetByObjectName("ReadyForInstallationPage");
    if (!page) return;

    var browser = page.findChild && page.findChild("TaskDetailsBrowser");
    if (!browser) return;

    // Keep IFW's default dependency summary and append your custom block
    var defaultHtml = "";
    try { defaultHtml = browser.html || ""; } catch (e) { }

    var comps = installer.components ? installer.components() : [];
    var mainLines = [], toolLines = [], utilityLines = [], otherLines = [];
    var totalMB = 0;
    var count = 0;

    for (var i = 0; i < comps.length; ++i) {
        var c = comps[i];
        var category = c.value("Category") || "Others";
        var size = c.value("EstimatedSize") || 0;
        console.log(">>", c.name, category, size);
        if (!isComponentSelected(c)) continue;

        var mb = readEstimatedSizeMB(size);
        var line = (c.displayName || c.name) + ": " + fmtMB(mb);

        if (category === "Main") {
            mainLines.push(line);
            count += 1;
        }
        else if (category === "Tool") {
            toolLines.push(line);
            count += 1;
        } else if (category === "Utilities") {
            utilityLines.push(line);
        }
        else otherLines.push(line);
        totalMB += mb;
    }

    var custom = [];
    // Main packages
    custom.push("<b>Main package(s) selected:</b>");
    if (mainLines.length) {
        custom.push('<ul style="margin:2px 0; padding-left:18px;">');
        custom.push("<li>" + mainLines.join("</li><li>") + "</li>");
        custom.push("</ul>");
    } else {
        custom.push("None");
    }

    // Tool packages
    custom.push("<b>Tool package(s) selected:</b>");
    if (toolLines.length) {
        custom.push('<ul style="margin:2px 0; padding-left:18px;">');
        custom.push("<li>" + toolLines.join("</li><li>") + "</li>");
        custom.push("</ul>");
    } else {
        custom.push("None");
    }

    // Utilities packages
    custom.push("<b>Utility package(s) selected:</b>");
    if (utilityLines.length) {
        custom.push('<ul style="margin:2px 0; padding-left:18px;">');
        custom.push("<li>" + utilityLines.join("</li><li>") + "</li>");
        custom.push("</ul>");
    } else {
        custom.push("None");
    }
    // Total
    custom.push("<b>Total storage required: " + fmtMB(totalMB) + "</b>");
    // // if (otherLines.length) {
    // //     custom.push("<br/><br/><b>Other package(s):</b>");
    // //     custom.push(otherLines.join("<br/>"));
    // // }

    browser.html = custom.join("<br/>") + (defaultHtml ? "<br/><br/><hr/>Check detail dependencies:<br/>" + defaultHtml : "");

    browser.visible = true;
};


// Controller.prototype.PerformInstallationPageCallback = function () {
//     var page = gui.pageWidgetByObjectName("PerformInstallationPage");
//     if (!page) return;

//     // helper: append text into the Details view (works across IFW versions)
//     function appendToDetails(text) {
//         text = text.toString();
//         // Prefer slot if exposed
//         try {
//             if (typeof page.appendProgressDetails === "function") {
//                 page.appendProgressDetails(text);
//                 return;
//             }
//         } catch (e) { }

//         // fallback: find a QTextBrowser and append
//         // var children = page.findChildren("");
//         // for (var i = 0; i < children.length; i++) {
//         //     console.log("Child:", children[i].objectName, children[i].toString());
//         // }
//         var details = page.findChild("QTextEdit", "DetailsBrowser");
//         if (details) {
//             try {
//                 details.append(text);
//                 return;
//             } catch (e) { }
//         }

//         // ultimate fallback: log to console
//         console.log(text);
//     }

//     // listen for installer values (RenesasCustomOperation will set these)
//     installer.valueChanged.connect(function (key, value) {
//         // match the key you used when calling the operation
//         if (!key) return;

//         if (key === "androidExtradownloadLog") {
//             appendToDetails(value);
//         } else if (key === "androidExtradownloadLog:exit") {
//             appendToDetails("RenesasCustom finished with exit code: " + value);
//         }
//     });
// };


