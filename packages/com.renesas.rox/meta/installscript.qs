function Component() {
    component.loaded.connect(this, Component.prototype.installerLoaded);
}

function checkInternetAccess(pageObject) {
    var timeoutSeconds = 5
    var statusLabel = pageObject.infoGroup.statusLabel;
    var spinnerLabel = pageObject.infoGroup.spinnerLabel;
    var retryBtn = pageObject.findChild("retryInternetButton");

    spinnerLabel.visible = true;
    statusLabel.visible = true;

    // Execute ping with timeout
    // var result = installer.execute("@bin/windows/curl.exe", ["-I", "--max-time", "5", "https://www.google.com"]);
    var args = ["-n", "1", "-w", "5000", "www.google.com"];
    var result = installer.execute("ping", args);
    spinnerLabel.visible = true;
    statusLabel.visible = true;
    // Parse exit code: after the last comma
    var parts = result.toString().split(",");
    var exitCode = parseInt(parts[parts.length - 1]);
    console.log("Ping return code: " + exitCode);
    if (exitCode === 0) {
        console.log("✅ [DEBUG] Internet access confirmed.");
        statusLabel.text = "✅ Internet access detected.";
        statusLabel.styleSheet = "color: green;";
        pageObject.complete = true;
        retryBtn.visible = false;
    } else {
        console.log("❌ [DEBUG] Internet access failed.");
        statusLabel.text = "❌ No Internet access";
        statusLabel.styleSheet = "color: red;";
        pageObject.complete = false;
        retryBtn.visible = true;
    }
}

Component.prototype.installerLoaded = function() {
    if (installer.addWizardPage(component, "InstallationMode", QInstaller.TargetDirectory)) {
        var page = gui.pageWidgetByObjectName("DynamicInstallationMode");
        if (!page) {
            console.log("Page not found: DynamicInstallationMode");
            return;
        }
        // check UI
        // var children = gui.findChildren(page, "");
        // for (var i = 0; i < children.length; ++i) {
        //     var children = gui.findChildren(page, "");
        //     console.log(children[i].objectName);
        // }
        page.windowTitle  = "Select Installation Mode";
        page.complete = false;
        var onlineBtn = page.onlineButton;
        var offlineBtn = page.offlineButton;
        var infoLabel = page.infoGroup.infoLabel;
        var retryBtn = page.findChild("retryInternetButton");
        var offlineBinaryPath =  page.findChild("offlineBinaryPath");
        var browseOfflineBinary =  page.findChild("browseOfflineBinary");
        var pathStatus = page.findChild("pathStatus");
        pathStatus.visible = false;
        
        // Default to Online Mode
        onlineBtn.checked = true;
        installer.setValue("InstallMode", "Online");
        checkInternetAccess(page)

        if (!onlineBtn || !offlineBtn || !infoLabel) {
            console.log("Missing widget(s):", onlineBtn, offlineBtn, infoLabel);
            return;
        }
        // Set default text
        infoLabel.text = "Please select an installation mode.";

        // Connect button clicks to update label
        onlineBtn.clicked.connect(function() {
            infoLabel.text = "In this mode, we download from our network.";
            retryBtn.visible = true;
            offlineBinaryPath.visible = false;
            browseOfflineBinary.visible = false;
            installer.setValue("InstallMode", "Online");
            checkInternetAccess(page)
        });

        offlineBtn.clicked.connect(function() {
            infoLabel.text = "ROX uses pre-downloaded files in the local folder.";
            installer.setValue("InstallMode", "Offline");
            // Show spinner and status text
            page.infoGroup.spinnerLabel.visible = false;
            page.infoGroup.statusLabel.visible = false;
            retryBtn.visible = false;
            // offlinePathLayout
            offlineBinaryPath.visible = true;
            browseOfflineBinary.visible = true;
            page.complete = false;
        });
        // Retry
        retryBtn.clicked.connect(function() {
            infoLabel.text = "In this mode, we download from our network.";
            installer.setValue("InstallMode", "Online");
            checkInternetAccess(page)
        });

        // User input logic
        offlineBinaryPath.textChanged.connect(function() {
            var rawPath = offlineBinaryPath.text;
            // Check if folder is empty
            var isEmpty = isFolderNOTEmptyAndExist(rawPath);
            if (!isEmpty) {
                // QMessageBox.critical(
                //     null,
                //     "Folder is Not Empty",
                //     "The selected folder is not empty. Please choose an empty folder.",
                //     QMessageBox.OK
                // );
                page.complete = false;
                pathStatus.text = "The pre-download directory must not empty";
                pathStatus.styleSheet = "color: red;";
                pathStatus.visible = true;
            } else {
                offlineBinaryPath.text = rawPath;
                installer.setValue("offlineDirectory", rawPath);
                pathStatus.visible = false;
                page.complete = true;
                pathStatus.visible = false;
            };
        });

        // Browse button logic
        browseOfflineBinary.clicked.connect(function() {
            var defaultPath = offlineBinaryPath.text;  // Get current value
            var selectedDir = QFileDialog.getExistingDirectory(
                null,
                "Select Folder",
                defaultPath
            );
            if (selectedDir) {
                offlineBinaryPath.text = selectedDir;
            }
            // Check if folder is empty
            var isEmpty = isFolderNOTEmptyAndExist(selectedDir);
            if (!isEmpty) {
                QMessageBox.critical(
                    null,
                    "Folder is Empty",
                    "The selected folder is empty. Please choose another folder.",
                    QMessageBox.OK
                );
                page.complete = false;
                pathStatus.text = "The pre-download directory must not empty";
                pathStatus.styleSheet = "color: red;";
            } else {
                offlineBinaryPath.text = selectedDir;
                installer.setValue("offlineDirectory", selectedDir);
                page.complete = true;
            };
        });
    }
};
function normalizePath(path) {
    // Convert forward slashes to backslashes
    var backslashPath = path.replace(/\//g, "\\");
    return backslashPath.replace(/\\/g, "\\\\");
};

function isFolderNOTEmptyAndExist(path) {
    // Return true if it exist and not empty
    var path = normalizePath(path);
    var command = "Get-ChildItem -Name \"" + path + "\" | Out-String";
    var result = installer.execute("powershell", ["-Command", command]);
    var exitCode = result[1];
    var stdout = result[0];
    console.log("xxxxxxxxx" + result)
    if (exitCode !== 0) {
        console.log("⚠️ Folder may not exist or is inaccessible.");
        return false;
    } else {
        var stdout = stdout.trim();
        if(stdout === "") {
            console.log("⚠️ Folder Empty " + stdout );
            return false;
        } else {
            console.log("⚠️ Folder NOT Empty ");
            return true;
        };
    };
}