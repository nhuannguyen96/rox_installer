

// function Component() { component.addDependency("componentInvalidscript"); }

function Component() {
    component.setValue("Category", "Utilities");
    component.setValue("EstimatedSize", "8");
}

Component.prototype.createOperations = function () {
    // always call default (licenses, etc.)
    component.createOperations();

    var targetTools = installer.value("TargetDir") + "/tools";
    component.addOperation("Mkdir", targetTools);

    var target = installer.value("TargetDir") + "/tools/curl.exe";
    component.addOperation("Copy", ":/bin/windows/curl.exe", target);
}
