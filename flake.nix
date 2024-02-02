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
    inherit (nixpkgs.lib) genAttrs;
    forAllSystems = f:
      genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
  in {
    packages = forAllSystems (pkgs:
      with pkgs; {
        default = stdenv.mkDerivation {
          name = "monolisa-nerdfont-patch";
          src = ./.;
          nativeBuildInputs = [makeWrapper];
          buildInputs = [fontforge python3];
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
              --set PATH ${lib.makeBinPath [fontforge]}
          '';
        };
      });

    devShells = forAllSystems (pkgs:
      with pkgs; {
        default = mkShell {buildInputs = [fontforge python3 pre-commit];};
      });

    formatter.x86_64-linux = alejandra.packages.x86_64-linux.default;
  };
}
