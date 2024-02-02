{
  description = "A script to patch the MonoLisa font with Nerd Fonts glyphs.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    alejandra.url = "github:kamadorueda/alejandra";
  };

  outputs = {
    self,
    nixpkgs,
    systems,
    alejandra,
  }: let
    inherit (nixpkgs) lib;
    eachSystem = fn:
      lib.genAttrs (import systems) (system: let
        pkgs = import nixpkgs {
          localSystem.system = system;
          overlays = [self.overlays.default];
        };
      in
        fn system pkgs);
  in {
    overlays = {
      default = final: prev: {
        monolisa-nerdfont-patch = final.stdenv.mkDerivation {
          name = "monolisa-nerdfont-patch";
          src = ./.;
          nativeBuildInputs = with final; [makeWrapper];
          buildInputs = with final; [fontforge python3];
          unpackPhase = ":";
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
              --set PATH ${lib.makeBinPath (with final; [fontforge])}
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

    formatter = eachSystem (system: _: alejandra.packages.${system}.default);
  };
}
