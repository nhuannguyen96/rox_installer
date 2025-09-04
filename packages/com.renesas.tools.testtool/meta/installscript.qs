function Component() {
    component.setValue("Category", "Tool");
    component.setValue("EstimatedSize", "50");
    component.setValue("Version", "v4.0.0");
    component.setValue("Platform", "app_name");
};

Component.prototype.createOperations = function () {
    component.createOperations();
    console.log("Component name xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx: " + component.name);

    // where to put downloads
    var downloadDir = installer.value("TargetDir") + "/downloads";
    var curlExe = installer.value("TargetDir") + "/tools/curl.exe";
    var tarExe = installer.value("TargetDir") + "/tools/tar.exe";
    var outFile = downloadDir + "/cmake-4.1.1-linux-aarch64.tar.gz";
    var sevenZipExe = installer.value("TempPath") + "/tools/7z.exe";

    // Read pre-defined value
    var platform = component.value("Platform") || "Others";
    var version = component.value("Version") || "Others";

    // var url = "https://github.com/Kitware/CMake/releases/download/v4.1.1/cmake-4.1.1-linux-aarch64.tar.gz";
    var url = "https://github.com/nhuannguyen96/installer-framework/releases/download/1.0.1/cmake-4.1.1-linux-aarch64.tar.gz"

    // Create download directory first
    component.addOperation("Mkdir", downloadDir);

    // Run curl -L -o package.tar.gz <url>
    // component.addOperation("Execute", curlExe, "-L", url, "-o", outFile);
    // component.addOperation("ConsumeOutput", ["androidExtradownloadLog", curlExe, "-L", url, "-o", outFile]);
    // component.addOperation("Execute", "echo", "Downloading xxxxx.tar.gz...");
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

    var targetDir = installer.value("TargetDir");
    var expectedPath = `${targetDir}/${platform}/${version}`;
    // Create extract directory first
    component.addOperation("Mkdir", expectedPath);

    // Extract the tar.gz file
    // if (component.name.includes("extra")) {
    component.addOperation("RenesasCustom", [
        `<b>Extracting <u>${outFile}</u></b>`,
        `<b>Extracted <u>${outFile}</u> to <u>${expectedPath}</u> </b>`,
        `CustomExtract`,
        tarExe,
        "-xzvf",
        outFile,
        "-C",
        expectedPath]
    );
    if (component.name.includes("testtool")) {
        var sevenzipExtractPath = `${expectedPath}/cmake-4.1.1-linux-aarch64/bin/`;
        var sevenzipFileWildCard = `${expectedPath}/cmake-4.1.1-linux-aarch64/bin/*.7z`;
        component.addOperation("RenesasCustom", [
            `<b>Extracting <u>${sevenzipFileWildCard}</u></b>`,
            `<b>Extracted <u>${sevenzipFileWildCard}</u> to <u>${sevenzipExtractPath}</u> </b>`,
            `CustomExtract`,
            sevenZipExe,
            "x",
            sevenzipFileWildCard,
            "-aoa",
            "-o" + sevenzipExtractPath
        ]
        );
    };
    // component.addOperation("RenesasCustom", ["androidExtraExtractLog", sevenZipExe,
    //     "x " + outFile + " -so -bsp1" + " | " + sevenZipExe + "x -aoa -si -ttar -bsp1 -o" + extractDir]);
    // }; //7z x "C:\ROX\cmake-4.1.1-linux-aarch64.tar.gz" -so -bsp1 | 7z x -aoa -si -ttar -bsp1 -o"C:\ROX\v4.0.0"
};
