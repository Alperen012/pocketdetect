# TensorFlow Lite: the Java side is reached from native code and from
# tflite_flutter via JNI/FFI, so R8 must not strip or rename it.
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options$GpuBackend
