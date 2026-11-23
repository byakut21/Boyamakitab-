import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.boyama.boyama_kitabi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.boyama.boyama_kitabi"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Her derleme aynı anahtarla imzalanır; böylece yeni sürüm eskisinin üstüne kurulur
    // ve boyamalar silinmez. Anahtar bu özel depoda durur (android/imza.properties).
    val imza = Properties().apply {
        val f = rootProject.file("imza.properties")
        if (f.exists()) f.inputStream().use { load(it) }
    }

    signingConfigs {
        create("sabit") {
            storeFile = file(imza.getProperty("storeFile", "boyama-imza.jks"))
            storePassword = imza.getProperty("storePassword")
            keyAlias = imza.getProperty("keyAlias")
            keyPassword = imza.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = if (imza.isEmpty) {
                signingConfigs.getByName("debug")
            } else {
                signingConfigs.getByName("sabit")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
