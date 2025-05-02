allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Configuração segura para diretório de build personalizado
    afterEvaluate {
        val customBuildDir = rootProject.layout.projectDirectory.dir("../../build/${project.name}")
        project.layout.buildDirectory.set(customBuildDir)
    }
}

// Configuração de clean task de forma mais robusta
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
    delete(file("../../build")) // Limpa também o diretório customizado
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    evaluationDependsOn(":app")
}
subprojects {
    project.evaluationDependsOn(":app")
}

