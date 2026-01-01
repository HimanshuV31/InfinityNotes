

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
//plugins {
//    id("com.android.application") version "8.7.3" apply false
//    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
//    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
//
//    // Google Services Gradle Plugin
//    id("com.google.gms.google-services") version "4.4.4" apply false
//}
rootProject.layout.buildDirectory = rootProject.layout.buildDirectory.dir("../../build").get()

subprojects {
    project.layout.buildDirectory = rootProject.layout.buildDirectory.dir(project.name).get()
    project.evaluationDependsOn(":app")
}

tasks.register("clean") {
    delete(rootProject.layout.buildDirectory)
}
