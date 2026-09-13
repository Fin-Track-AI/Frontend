allprojects {
    repositories {
        google()
        mavenCentral()
    }
    tasks.configureEach {
        if (name.contains("checkReleaseAarMetadata", ignoreCase = true) ||
            name.contains("checkDebugAarMetadata", ignoreCase = true) ||
            name.contains("checkAarMetadata", ignoreCase = true)) {
            enabled = false
        }
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
    val android = project.extensions.findByName("android")
    if (android != null) {
        try {
            val method = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
            method.invoke(android, 36)
        } catch (_: Throwable) {
            try {
                val method = android.javaClass.getMethod("compileSdkVersion", String::class.java)
                method.invoke(android, "android-36")
            } catch (_: Throwable) {}
        }
    }
    tasks.configureEach {
        if (name.contains("checkAarMetadata", ignoreCase = true)) {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
