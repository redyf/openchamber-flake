{
  description = "OpenChamber — agentic development environment based on the OpenCode AI agent";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      packages = forAllSystems (system: rec {
        openchamber = (pkgsFor system).callPackage ./package.nix { };
        default = openchamber;
      });

      overlays.default = final: _: {
        openchamber = final.callPackage ./package.nix { };
      };

      checks = forAllSystems (system: {
        inherit (self.packages.${system}) openchamber;
      });

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);
    };
}
