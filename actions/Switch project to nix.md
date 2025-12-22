#action #action #mariposa 
#published 


# Notes
- [GRADLE_OPTS](https://docs.gradle.org/current/userguide/build_environment.html) Specifies #JVM arguments to use when starting the #Gradle client VM. The client #VM only handles command line input/output, so one would rarely need to change its VM options. The actual build is run by the Gradle daemon, which is not affected by this environment variable. 
``` bash
gradle build -Dorg.gradle.project.android.aapt2FromMavenOverride=/nix/store/dph900wz88dlhgyshf28g220crw4mbfd-aapt-8.4.1-11315950/bin/aapt2
```
- the basic gradle command works, as well as gradlew with above
- android-studio package used to install androidsdk but no longer seems to. 
	-  You can get androidsdk via androidEnv.composeAndroidPackages
- aapt2 comes from maven not android studio, thats the issue. SO what we need to do is create a GRADLE_OPTS variable which we use when running grade build $GRADLE_OPTS. Which sets the -Dorg command from above
- Looks like there is a packagins task. run `gradle tasks` to see
- There is a way to export properties which are added as [gradle.properties](https://docs.gradle.org/current/userguide/build_environment.html#sec:project_properties)
- gradle2nix has been super promisign. Only issue has been getting the outputted package to run. Its linking against libGL.so.1 from one of the libraries
- gradle2nix has been super promisign. Only issue has been getting the outputted package to run. Its linking against libGL.so.1 from one of the libraries
	- using a "uber jar " instead of distributable seems much easier will probably take this route for now. Still needs to have libgl linked though, just add path to wrapper
- use seperate package section for apk 
- currently doesn't build for msi? gradle java version might be too high? MSI also can only be built on windows :(
- There is a xcode build wrapper for nix, but it looks like it only works on nixos https://nixos.org/manual/nixpkgs/unstable/#ios

# Questions
- [v] How to build APK. 
	- A : gradle build task seems to produce all targets (except ios ofc)
# Statement of action
Switch the packing / build system to nixos so you can use your helix editor instead of android studio.

# Statement of specifications
- can build for #android and #linux using #nixfor windows and iOS?
- first class supported derivation to install
- second class system for producing apk
- ability to run apk in emulated android and install using nix apps outputs
- all versioning specified decoratively
# statement of design
Create a new nix flake using gradle2nix for the project. Using Android compose set the android home and SDK location and make it available to all derivations. 

This flake should have four packages: one uber jar, a wrapped version packaged for linux which sets the LD_path for any dependencies like libgl (this should be the default package), an output to build the APK, and a output to create the emulator script for the APK. Additionally it should have 2 apps. One for running the emulator script, and another for installing the apk.

Create a $GRADLE_OPTS parameter set which contains android home and gradle operations

use the androidenv package in nix for generating the android sdk compose, and for creating the emulator script.

We are pretty much only using libraries for doing all this, so no need to create any wrappers yourself. You won't be making new apps very often and can revise later if need be.







