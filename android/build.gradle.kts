allprojects {
    repositories {
        google()
        mavenCentral()
    }

    subprojects {
        afterEvaluate {
            // check only for "com.android.library" to not modify
            // your "app" subproject. All plugins will have "com.android.library" plugin, and only your app "com.android.application"
            if (plugins.hasPlugin("com.android.library")) {
                val androidExt =
                    extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
                if (androidExt != null && androidExt.namespace == null) {
                    androidExt.namespace = group.toString()
                }
            }
        }
    }

}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
