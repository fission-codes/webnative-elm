let

  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {};

in

  pkgs.mkShell {
    buildInputs = [

      pkgs.elmPackages.elm

      pkgs.nodejs-14_x
      pkgs.nodePackages.pnpm

    ];
  }
