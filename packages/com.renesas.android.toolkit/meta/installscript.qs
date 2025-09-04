function Component() {
    component.setValue("Category", "Main");
    component.setValue("EstimatedSize", "10.8437");
    component.setValue("Version", "v4.0.0");
    component.setValue("Platform", "app_name");
}

Component.prototype.createOperations = function () {
    console.log("Component name xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx: " + component.name);
    // var deps = component.dependencies;
    // console.log("deps name xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx: " + deps);
    // for (var i = 0; i < deps.length; ++i) {
    //     var depComp = installer.componentByName(deps[i]);
    //     console.log("depcompxxxxxxxxxx" + depComp);
    //     if (depComp && depComp.installationRequested()) {
    //         depComp.createOperations();
    //     }
    // }
    component.createOperations();
    // where to put downloads
    var downloadDir = installer.value("TargetDir") + "/downloads";
    var curlExe = installer.value("TargetDir") + "/tools/curl.exe";
    var tarExe = installer.value("TargetDir") + "/tools/tar.exe";
    var outFile = downloadDir + "/main_package.tar.gz";
    var extractDir = installer.value("TargetDir")
    var sevenZipExe = installer.value("TempPath") + "/tools/7z.exe";

    // Read pre-defined value
    var platform = component.value("Platform") || "Others";
    var version = component.value("Version") || "Others";


    var url = "https://github.com/nhuannguyen96/installer-framework/releases/download/1.0.1/main_package.tar.gz"

    // Create download directory first
    component.addOperation("Mkdir", downloadDir);

    component.addOperation("RenesasCustom", [
        `<b>Downloading <u>${url}</u></b>`,
        `<b>Download <u>${outFile}</u> succesfully.</b>`,
        `CustomDownload`,
        curlExe,
        "--progress-bar",
        "-L",
        url,
        "-o",
        outFile]
    );
    // Ensure the target directory exists
    component.addOperation("Mkdir", extractDir);
    // Extract the tar.gz file
    component.addOperation("RenesasCustom", [
        `<b>Extracting <u>${outFile}</u></b>`,
        `<b>Extracted <u>${outFile}</u> to <u>${extractDir}</u> </b>`,
        `CustomExtract`,
        tarExe,
        "-xzvf",
        outFile,
        "-C",
        extractDir]
    );

    var targetDir = installer.value("TargetDir");
    var expectedPath = `${targetDir}/${platform}/${version}`;
    var powershellCmd = `'$result = Test-Path "${expectedPath}"; Write-Output $result; if (-not $result) { exit 1 }'`;


    component.addOperation("RenesasCustom", [
        `<b>Perform Extraction check: Directory <u>${expectedPath}</u> is expected</b>`,
        ``,
        `CustomCmdCheck`,
        "powershell",
        "powershell -Command",
        powershellCmd
    ]
    );
    // listen for installer values (RenesasCustomOperation will set these)
    installer.valueChanged.connect(function (key, value) {
        // match the key you used when calling the operation
        if (!key) return;
        if (key === "CustomCmdCheck:exit") {
            console.log("RenesasCustom finished with exit code: " + value);
            if (value !== "0") {
                // Show message to user
                QMessageBox.information(
                    null,
                    "Folder Structure is not match",
                    `${component.name} extracted does not match expected location: ${expectedPath}`,
                    QMessageBox.OK
                );
                // Force exit
                // gui.clickButton(buttons.CancelButton);
                // gui.rejectWithoutPrompt();
            }
        }
    });

    // var result = installer.execute("cmd", ["/c", "if exist \"" + expectedPath + "\" (echo FOUND) else (echo NOT FOUND)"]);

    // console.log("Component installed: " + result);
    // component.addOperation("RenesasCustom", ["androidExtraExtractLog", sevenZipExe,
    //     "x " + outFile + " -so -bsp1" + " | " + sevenZipExe + "x -aoa -si -ttar -bsp1 -o" + extractDir]);
    //7z x "C:\ROX\cmake-4.1.1-linux-aarch64.tar.gz" -so -bsp1 | 7z x -aoa -si -ttar -bsp1 -o"C:\ROX\v4.0.0"

};

Component.prototype.finished = function () {
    console.log("✅ finished() was triggered");
    QInstaller.setInstallerValue("LogText", "✅ finished() was triggered");
};