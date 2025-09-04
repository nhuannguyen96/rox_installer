

// function Component() { component.addDependency("componentInvalidscript"); }

function Component() {
    // component.setValue("Category", "Utilities");
    // component.setValue("EstimatedSize", "7");
}

Component.prototype.createOperations = function () {
    // always call default (licenses, etc.)
    // component.createOperations();

    // var targetTools = installer.value("TargetDir") + "/tools";
    // component.addOperation("Mkdir", targetTools);

    // var target = installer.value("TargetDir") + "/tools/tar.exe";
    // component.addOperation("Copy", ":/bin/windows/tar.exe", target);
    var tempTools = installer.value("TempPath") + "/tools";
    component.addOperation("Mkdir", tempTools);
    component.addOperation("Copy", ":/bin/windows/7z.exe", tempTools + "/7z.exe");
    component.addOperation("Copy", ":/bin/windows/7z.dll", tempTools + "/7z.dll");
}
