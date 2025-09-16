{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    gradle2nix.url = "github:tadfisher/gradle2nix/v2";
  };

  outputs = { self, nixpkgs, gradle2nix }: 
  let 
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.android_sdk.accept_license = true;
    };
    platformVersion = "34";
    buildToolVersion = "34.0.0";
    systemImageType = "default";
    androidEnv = pkgs.androidenv.override { licenseAccepted = true; };
    androidComp = (
      androidEnv.composeAndroidPackages {
        cmdLineToolsVersion = "8.0";
        includeNDK = true;
        # we need some platforms
        platformVersions = [
          platformVersion
        ];
        buildToolsVersions = [ buildToolVersion ]; 
        # we need an emulator
        includeEmulator = true;
        includeSystemImages = true;
        systemImageTypes = [
          systemImageType
          # "google_apis"
        ];
        abiVersions = [
          "x86"
          "x86_64"
          "armeabi-v7a"
          "arm64-v8a"
        ];
        cmakeVersions = [ "3.10.2" ];
      }
    );
  in
  {

    packages.x86_64-linux.default = gradle2nix.builders.x86_64-linux.buildGradlePackage rec {
      pname = "mariposa";
      version = "1.0";
      lockFile = ./gradle.lock;
      src = ./.;
      gradleFlags = ["-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_HOME}/build-tools/${buildToolVersion}/aapt2"];
      gradleBuildFlags = [
        "createDistributable"
      ];

      installPhase = ''
        mkdir -p $out/bin
        mkdir -p $out/lib
        mv composeApp/build/compose/binaries/main/app/org.mariposa.mariposa/bin/org.mariposa.mariposa $out/bin/${pname}
        mv composeApp/build/compose/binaries/main/app/org.mariposa.mariposa/lib/* $out/lib/
      '';
      
      ANDROID_HOME = "${androidComp.androidsdk}/libexec/android-sdk";
      ANDROID_SDK_ROOT = "${androidComp.androidsdk}/libexec/android-sdk";
      ANDROID_NDK_ROOT = "${androidComp.androidsdk}/libexec/android-sdk/ndk-bundle";
    };

  
    devShells.x86_64-linux = {
     default = pkgs.mkShell rec {
      packages = [
        pkgs.jdk23
        pkgs.libGL
        pkgs.gradle
      ];
      LD_LIBRARY_PATH="${pkgs.libGL}/lib/";
      ANDROID_HOME = "${androidComp.androidsdk}/libexec/android-sdk";
      ANDROID_SDK_ROOT = "${androidComp.androidsdk}/libexec/android-sdk";
      ANDROID_NDK_ROOT = "${androidComp.androidsdk}/libexec/android-sdk/ndk-bundle";
      GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_HOME}/build-tools/${buildToolVersion}/aapt2";
      shellHook = ''
      echo "dev"
      '';
       };
     };
  };
}
