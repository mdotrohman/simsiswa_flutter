plugins {
    // Firebase / Google Services (google-services.json) untuk FCM push.
    id("com.google.gms.google-services") version "4.4.2" apply false
}

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
subprojects {
    project.evaluationDependsOn(":app")
}

// Plugin pihak-ketiga (mis. flutter_secure_storage) kadang dikompil ke
// compileSdk lebih rendah dari proyek; paksa 36 agar konsisten.
fun forceCompileSdk(p: Project) {
    val ext = p.extensions.findByName("android") ?: return
    try {
        val base = ext as? com.android.build.gradle.BaseExtension ?: return
        val cur = base.compileSdkVersion?.toString()?.replace("android-", "")?.toIntOrNull() ?: 0
        if (cur < 36) base.compileSdkVersion(36)
    } catch (_: Throwable) {
    }
}

subprojects {
    if (state.executed) forceCompileSdk(this) else afterEvaluate { forceCompileSdk(this) }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
