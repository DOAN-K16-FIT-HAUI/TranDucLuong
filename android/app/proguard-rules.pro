# Keep ML Kit Text Recognition classes
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep ML Kit general classes
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Suppress warnings for other dependencies if needed
-dontwarn okio.**
-dontwarn org.apache.**