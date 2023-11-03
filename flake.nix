{
  description = "Loïc Reynier's CV";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    yaac = {
      url = "github:darwiin/yaac-another-awesome-cv";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    flake-utils,
    nixpkgs,
    pre-commit-hooks,
    ...
  }: let
    supportedSystems = ["x86_64-linux"];
  in
    flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = import nixpkgs {inherit system;};
      pkgName = "cv";
      pkgVersion = "0.0";
      yaac = pkgs.stdenv.mkDerivation rec {
        name = "yaac";
        pname = name;
        src = ./.;
        dontConfigure = true;
        installPhase = ''
          mkdir -p $out/tex/latex
          cp "${inputs.yaac}/yaac-another-awesome-cv.cls" $out/tex/latex
        '';
        tlType = "run";
      };
      texlive-yaac = with pkgs;
        texlive.combine {
          inherit (texlive) scheme-full;
          pkgFilter = pkg:
            lib.elem pkg.tlType [
              "run"
              "bin"
            ];
          yaac = {
            pkgs = [yaac];
          };
        };
      buildPackages = with pkgs; [
        coreutils
        texlive-yaac
      ];
      lastModified = builtins.toString self.lastModified;
    in rec {
      packages.default = pkgs.stdenvNoCC.mkDerivation rec {
        pname = pkgName;
        version = pkgVersion;
        src = self;
        buildInputs = buildPackages;
        phases = ["unpackPhase" "buildPhase" "installPhase"];
        buildPhase = ''
          export PATH="${pkgs.lib.makeBinPath buildInputs}"
          export SOURCE_DATE_EPOCH="${lastModified}";
          TMPDIR=$(mktemp -d)
          mkdir -p "$TMPDIR/texmf-var"
          env TEXMFHOME="$TMPDIR" \
              TEXMFVAR="$TMPDIR/texmf-var" \
            latexmk
          rm -rf "$TMPDIR"
        '';
        installPhase = ''
          mkdir -p $out
          cp *.pdf $out/
          rm -rf build
        '';
      };

      checks = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = with pkgs; {
            alejandra.enable = true;
            commitizen.enable = true;
            deadnix.enable = true;
            editorconfig-checker.enable = true;
            statix.enable = true;
            typos.enable = true;
          };
        };
      };

      devShells.default = pkgs.mkShell {
        propagatedBuildInputs = with pkgs; [
          just
          texlive-yaac
        ];
        inherit (self.checks.${system}.pre-commit-check) shellHook;
      };
    });
}
