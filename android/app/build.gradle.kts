import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "org.korelium.koralauncher"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.korelium.koralauncher"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (!hasKeystoreProperties) {
                // Allow local --release builds without a release keystore.
                // Proper signing will still happen in CI / on machines with key.properties.
                return@create
            }

            val keyAliasProp = keystoreProperties["keyAlias"] as String?
            val keyPasswordProp = keystoreProperties["keyPassword"] as String?
            val storeFileProp = keystoreProperties["storeFile"] as String?
            val storePasswordProp = keystoreProperties["storePassword"] as String?

            if (keyAliasProp.isNullOrBlank() ||
                keyPasswordProp.isNullOrBlank() ||
                storeFileProp.isNullOrBlank() ||
                storePasswordProp.isNullOrBlank()
            ) {
                // Missing or incomplete config: fall back to debug signing.
                return@create
            }

            val resolvedStoreFile = file(storeFileProp)
            if (!resolvedStoreFile.exists()) {
                // Keystore file missing: fall back to debug signing.
                return@create
            }

            keyAlias = keyAliasProp
            keyPassword = keyPasswordProp
            storeFile = resolvedStoreFile
            storePassword = storePasswordProp
        }
    }

    buildTypes {
        release {
            // Use release keystore when available, otherwise allow local builds with debug signing.
            val releaseStoreFile = signingConfigs.getByName("release").storeFile
            signingConfig = if (releaseStoreFile != null && releaseStoreFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
