C:\src\flutter2\bin\flutter.bat --no-color run --machine --track-widget-creation --device-id=87bf4390 --start-paused --dart-define=flutter.inspector.structuredErrors=true --devtools-server-address=http://127.0.0.1:9101 lib\main.dart
Launching lib\main.dart on CPH2631 in debug mode...
Running Gradle task 'assembleDebug'...
Warning: Flutter support for your project's Gradle version (8.7.0) will soon be dropped. Please upgrade your Gradle version to a version of at least 8.14.0 soon.
Alternatively, use the flag "--android-skip-build-dependency-validation" to bypass this check.

Potential fix: Your project's gradle version is typically defined in the gradle wrapper file. By default, this can be found at C:\Users\ITESA 709\AndroidStudioProjects\aryasenpai_piano_android2\android/gradle/wrapper/gradle-wrapper.properties.
For more information, see https://docs.gradle.org/current/userguide/gradle_wrapper.html.


FAILURE: Build failed with an exception.

* Where:
  Build file 'C:\Users\ITESA 709\AndroidStudioProjects\aryasenpai_piano_android2\android\app\build.gradle.kts' line: 1

* What went wrong:
  An exception occurred applying plugin request [id: 'dev.flutter.flutter-gradle-plugin']
> Failed to apply plugin 'dev.flutter.flutter-gradle-plugin'.
> Error: Your project's Android Gradle Plugin version (Android Gradle Plugin version 8.2.1) is lower than Flutter's minimum supported version of Android Gradle Plugin version 8.6.0. Please upgrade your Android Gradle Plugin version.
Alternatively, use the flag "--android-skip-build-dependency-validation" to bypass this check.

     Potential fix: Your project's AGP version is typically defined in the plugins block of the `settings.gradle` file (C:\Users\ITESA 709\AndroidStudioProjects\aryasenpai_piano_android2\android/settings.gradle), by a plugin with the id of com.android.application. 
     If you don't see a plugins block, your project was likely created with an older template version. In this case it is most likely defined in the top-level build.gradle file (C:\Users\ITESA 709\AndroidStudioProjects\aryasenpai_piano_android2\android/build.gradle) by the following line in the dependencies block of the buildscript: "classpath 'com.android.tools.build:gradle:<version>'".


* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 7m 9s

┌─ Flutter Fix ─────────────────────────────────────────────────────────────────────────────┐
│ [!] Starting AGP 9+, only the new DSL interface will be read.                             │
│ This results in a build failure when applying the Flutter Gradle plugin at C:\Users\ITESA │
│ 709\AndroidStudioProjects\aryasenpai_piano_android2\android\app\build.gradle.kts.         │
│                                                                                           │
│ To resolve this update flutter or opt out of `android.newDsl`.                            │
│ For instructions on how to opt out, see:                                                  │
│ https://developer.android.com/build/releases/agp-9-0-0-release-notes                      │
│                                                                                           │
│ If you are not upgrading to AGP 9+, run `flutter analyze --suggestions` to check for      │
│ incompatible dependencies.                                                                │
└───────────────────────────────────────────────────────────────────────────────────────────┘
Error: Gradle task assembleDebug failed with exit code 1
