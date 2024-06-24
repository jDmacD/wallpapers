{
  description = "A flake to handle wallpapers in NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  } @ inputs: let
    inherit (self) outputs;
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    packages = forAllSystems (system: let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      wallpapers = pkgs.stdenv.mkDerivation {
        name = "wallpapers";
        src = ./.;
        buildInputs = [ pkgs.coreutils pkgs.bash ];

        installPhase = ''
          mkdir -p $out/share/wallpapers
          cp -r $src/3440x1440/ $out/share/wallpapers/3440x1440/
        '';
      };

      randomImage = pkgs.writeShellScriptBin "random-image" ''
        find ${self.packages.${system}.wallpapers}/share/wallpapers/ -type f -name '*.jpeg' | shuf -n 1
      '';
    });

    defaultPackage = forAllSystems (system: self.packages.${system}.wallpapers);

  };
}
