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

    buildInputList = [
        pkgs.jdk
        pkgs.libGL
    ];

    nativeBuildInputList = with pkgs; [
      makeWrapper
      jdk
    ];


    android_gradle_envs = rec {
      ANDROID_HOME = "${androidComp.androidsdk}/libexec/android-sdk";
      ANDROID_SDK_ROOT = "${androidComp.androidsdk}/libexec/android-sdk";
      ANDROID_NDK_ROOT = "${androidComp.androidsdk}/libexec/android-sdk/ndk-bundle";
      LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath buildInputList}";
      GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_HOME}/build-tools/${buildToolVersion}/aapt2";
    };
  in
  {

    packages.x86_64-linux.uberJar = gradle2nix.builders.x86_64-linux.buildGradlePackage (rec {
      pname = "mariposa";
      version = "1.0";
      lockFile = ./gradle.lock;
      src = ./.;
      gradleFlags = ["${android_gradle_envs.GRADLE_OPTS}"];
      gradleBuildFlags = [
        "packageUberJarForCurrentOS"
      ];

      nativeBuildInputs = nativeBuildInputList;
      buildInputs = buildInputList;
  
      installPhase = ''
        mkdir -p $out
        mv composeApp/build/compose/jars/* $out/${pname}.jar
      '';    
    } // android_gradle_envs);

    packages.x86_64-linux.default = pkgs.stdenv.mkDerivation (rec {
      name = "mariposa";
      src = self.packages.x86_64-linux.uberJar;
      buildInputs = buildInputList;
      nativeBuildInputs = nativeBuildInputList;

      installPhase = ''
        mkdir -p $out

        cp ${name}.jar $out/${name}.jar
        
        makeWrapper ${pkgs.jdk}/bin/java $out/bin/${name} \
          --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath buildInputs}" \
          --add-flags "-jar $out/${name}.jar"
      '';
    });
    
    packages.x86_64-linux.apk = gradle2nix.builders.x86_64-linux.buildGradlePackage (rec {
      pname = "mariposa";
      version = "1.0";
      lockFile = ./gradle.lock;
      src = ./.;
      gradleFlags = ["${android_gradle_envs.GRADLE_OPTS}"];
      gradleBuildFlags = [
        "build"
      ];

      nativeBuildInputs = nativeBuildInputList;
      buildInputs = buildInputList;
  
      installPhase = ''
        mkdir -p $out
        mv ./composeApp/build/outputs/apk/debug/composeApp-debug.apk $out/${pname}.apk

      '';    
    } // android_gradle_envs);

    packages.x86_64-linux.apkRunnerScript = androidEnv.emulateApp {
      name = "emulate-MyAndroidApp";
      platformVersion = "24";
      abiVersion = "x86_64"; # mips, x86, x86_64
      systemImageType = "default";
      app = "${self.packages.x86_64-linux.apk}/mariposa.apk";
      package = "org.mariposa.mariposa";
      androidEmulatorFlags = "-gpu swiftshader_indirect";
    };

    apps.x86_64-linux.apk = {
      type="app";
      program="${self.packages.x86_64-linux.apkRunnerScript}/bin/run-test-emulator";
    };

    apps.x86_64-linux.installApk = {
      type="app";
      program= toString (pkgs.writeShellScript "install-apk" ''
        ${pkgs.android-tools}/bin/adb install -d ${self.packages.x86_64-linux.apk}/mariposa.apk
      '');
    };
  
    devShells.x86_64-linux = {
     default = pkgs.mkShell ({
      packages = buildInputList ++ nativeBuildInputList ++ [
        pkgs.gradle
      ];
      shellHook = ''
      echo "dev"
      '';
       } // android_gradle_envs );
     };
  };
}
