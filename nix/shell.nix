{ pkgs ? import <nixpkgs> {} }: with pkgs; mkShell {

  buildInputs = [
    elmPackages.elm
    elmPackages.elm-format
    elmPackages.elm-test
    nodejs-18_x
  ];

}