allprojects {
    repositories {
        google()
        mavenCentral()
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
subprojects {
    configurations.all {
        resolutionStrategy {
            force(
                "androidx.core:core-splashscreen:1.2.0",
                "androidx.core:core-ktx:1.15.0",
                "androidx.appcompat:appcompat:1.7.0"
            )
        }
    }
}
subprojects {
    afterEvaluate {
        val androidExtension = extensions.findByName("android")
        if (androidExtension is com.android.build.gradle.BaseExtension) {
            androidExtension.compileSdkVersion(36)
            androidExtension.buildFeatures.buildConfig = true
        }
    }
}
