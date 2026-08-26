import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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

// Keep every plugin module's Kotlin jvmTarget in sync with the Java target
// that the Flutter/AGP tooling gives the matching JavaCompile task. Older
// plugins declare Kotlin 1.8 while tooling upgrades Java, which trips AGP's
// "inconsistent JVM-target" check. Runs after all projects are evaluated so
// the JavaCompile tasks already carry their final targets.
gradle.projectsEvaluated {
    subprojects {
        if (name != "app") {
            val kotlinTasks = tasks.withType(KotlinCompile::class.java).toList()
                .associateBy { it.name }
            for (jc in tasks.withType(JavaCompile::class.java).toList()) {
                val variant = jc.name
                    .removePrefix("compile")
                    .removeSuffix("JavaWithJavac")
                if (variant.isEmpty()) continue
                val kt = kotlinTasks["compile${variant}Kotlin"] ?: continue
                kt.compilerOptions.jvmTarget.set(
                    when (jc.targetCompatibility) {
                        "17" -> JvmTarget.JVM_17
                        "21" -> JvmTarget.JVM_21
                        "11" -> JvmTarget.JVM_11
                        else -> JvmTarget.JVM_1_8
                    }
                )
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
