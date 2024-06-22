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
          cp -r $src/3440x1440/* $out/share/wallpapers/3440x1440/
          mkdir -p $out/bin

          cat > $out/bin/random-wallpaper <<EOF
          #!/usr/bin/env bash
          find $out/share/wallpapers/3440x1440 -type f -name '*.jpg' | shuf -n 1
          EOF
          chmod +x $out/bin/random-wallpaper
        '';

        meta = with pkgs.lib; {
          description = "Wallpapers package with random wallpaper script";
          license = licenses.mit;
        };
      };

      randomImage = pkgs.writeShellScriptBin "random-image" ''
        find ${self.packages.${system}.wallpapers}/share/wallpapers/3440x1440 -type f -name "*.jpeg" | shuf -n 1
      '';
    });

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    nixosModules.wallpapers = { config, lib, pkgs, ... }: {
      options.wallpapers = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable the wallpapers module";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.wallpapers;
          description = "The package that contains the wallpapers";
        };
      };

      config = lib.mkIf config.wallpapers.enable {
        environment.systemPackages = [ config.wallpapers.package ];
        environment.etc."wallpapers".source = "${config.wallpapers.package}/share/wallpapers";
      };
    };

    defaultPackage = forAllSystems (system: self.packages.${system}.wallpapers);

    apps = forAllSystems (system: {
      randomImage = {
        type = "app";
        program = "${self.packages.${system}.randomImage}/bin/random-image";
      };
    });

    defaultApp = forAllSystems (system: self.apps.${system}.randomImage);
  };
}
