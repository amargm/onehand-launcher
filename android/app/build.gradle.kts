plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystorePath = System.getenv("ANDROID_UPLOAD_KEYSTORE_PATH")
val releaseKeystorePassword = System.getenv("ANDROID_UPLOAD_KEYSTORE_PASSWORD")
val releaseKeyAlias = System.getenv("ANDROID_UPLOAD_KEY_ALIAS")
val releaseKeyPassword = System.getenv("ANDROID_UPLOAD_KEY_PASSWORD")
val releaseBuildRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (releaseBuildRequested) {
    val signingValues = mapOf(
        "ANDROID_UPLOAD_KEYSTORE_PATH" to releaseKeystorePath,
        "ANDROID_UPLOAD_KEYSTORE_PASSWORD" to releaseKeystorePassword,
        "ANDROID_UPLOAD_KEY_ALIAS" to releaseKeyAlias,
        "ANDROID_UPLOAD_KEY_PASSWORD" to releaseKeyPassword,
    )
    val missingSigningValues = signingValues.filterValues { it.isNullOrBlank() }.keys
    check(missingSigningValues.isEmpty()) {
        "Release builds require these environment variables: ${missingSigningValues.joinToString()}"
    }
    check(file(requireNotNull(releaseKeystorePath)).isFile) {
        "Release upload keystore does not exist at ANDROID_UPLOAD_KEYSTORE_PATH."
    }
}

android {
    namespace = "com.onehand.onehand_launcher"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = releaseKeyAlias.orEmpty()
            keyPassword = releaseKeyPassword.orEmpty()
            storeFile = releaseKeystorePath?.let { file(it) }
            storePassword = releaseKeystorePassword.orEmpty()
        }
    }

    defaultConfig {
        applicationId = "com.onehand.onehand_launcher"
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
