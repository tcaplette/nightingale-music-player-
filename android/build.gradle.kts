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

// AGP 8.x requires a namespace in every library module's build file.
// Older pub.dev plugins pre-date this requirement. This block reads the
// package attribute from each plugin's AndroidManifest.xml and injects it
// as the namespace so the build doesn't fail without patching the pub cache.
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    afterEvaluate {
        val androidExtension = extensions.findByName("android")
        if (androidExtension is com.android.build.gradle.LibraryExtension) {
            // Inject namespace for older plugins that don't have one (AGP 8.x requirement)
            if (androidExtension.namespace == null) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifest = groovy.xml.XmlSlurper().parse(manifestFile)
                    val pkg = manifest.getProperty("@package")?.toString().orEmpty()
                    if (pkg.isNotEmpty()) {
                        androidExtension.namespace = pkg
                    }
                }
            }
            // Force Java 17 compatibility for all subprojects to avoid JVM target mismatches
            androidExtension.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }

    // Force Kotlin JVM target for all compilation tasks in this subproject
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
