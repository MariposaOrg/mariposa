{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
  let 
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in
  {
    devShells.x86_64-linux = {
      default = pkgs.mkShell {
          packages = with pkgs; [
            jdk23
            gradle
            libGL
          ];
          LD_LIBRARY_PATH="${pkgs.libGL}/lib/";
          shellHook = ''
          echo "dev"
          '';
        };
      };
  };
}
