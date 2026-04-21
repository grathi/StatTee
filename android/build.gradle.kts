allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // Force kotlin-metadata-jvm to a version that understands Kotlin 2.3.x metadata,
    // overriding the older copy bundled with AGP.
    configurations.all {
        resolutionStrategy.force("org.jetbrains.kotlin:kotlin-metadata-jvm:2.3.10")
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
