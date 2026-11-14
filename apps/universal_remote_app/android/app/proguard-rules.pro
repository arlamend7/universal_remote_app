# Room creates the WorkManager database through its no-argument constructor.
# The bundled Room consumer rules keep the class but omit this constructor.
-keepclassmembers class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}
