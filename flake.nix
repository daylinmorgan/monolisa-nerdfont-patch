{
  description = "A script to patch the MonoLisa font with Nerd Fonts glyphs.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = {
    self,
    nixpkgs,
    systems,
  }: let
    inherit (nixpkgs.lib) genAttrs makeBinPath;
    eachSystem = fn:
      genAttrs (import systems)
      (system:
        fn system
        (import nixpkgs {
          inherit system;
          overlays = [self.overlays.default];
        }));
  in {
    overlays = {
      default = final: _prev: let
        pkgs = final;
      in {
        monolisa-nerdfont-patch = pkgs.stdenv.mkDerivation {
          name = "monolisa-nerdfont-patch";
          src = ./.;
          nativeBuildInputs = with pkgs; [makeWrapper];
          buildInputs = with pkgs; [fontforge python3];
          buildPhase = ":";
          installPhase = ''
            mkdir -p $out/bin
            install -m755 -D ${./patch-monolisa} $out/bin/monolisa-nerdfont-patch
            install -m755 -D ${./font-patcher} $out/bin/font-patcher
            cp -r ${./bin} $out/bin/bin
            cp -r ${./src} $out/bin/src
          '';
          postFixup = ''
            wrapProgram $out/bin/monolisa-nerdfont-patch \
              --set PATH ${makeBinPath (with final; [fontforge])}
          '';
        };
      };
    };

    packages = eachSystem (system: pkgs: {
      default = self.packages.${system}.monolisa-nerdfont-patch;
      monolisa-nerdfont-patch = pkgs.monolisa-nerdfont-patch;
    });

    devShells = eachSystem (_: pkgs: {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [fontforge python3 pre-commit];
      };
    });
  };
}
