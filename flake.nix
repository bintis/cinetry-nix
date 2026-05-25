{
  description = "Cinetry Player packaged for Nix";

  nixConfig = {
    extra-substituters = [ "https://cinetry-nix.cachix.org" ];
    extra-trusted-public-keys = [
      "cinetry-nix.cachix.org-1:Z4gu19/+YesNHODlAfE9cmPVOa5ckG8GZc0/x7IWm9g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Cinetry's bundled media_kit Flutter plugin is linked against the
    # libmpv 1.x SONAME (libmpv.so.1). Upstream mpv bumped to libmpv.so.2
    # during the 0.35 cycle, and current nixpkgs is on 0.41+. nixos-22.05
    # still ships mpv 0.34.1 with libmpv.so.1, so we pull mpv-unwrapped
    # from there exclusively for this one runtime dep.
    nixpkgs-libmpv1.url = "github:NixOS/nixpkgs/nixos-22.05";
  };

  outputs = { self, nixpkgs, nixpkgs-libmpv1 }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        });
      libmpv1For = forAllSystems (system:
        (import nixpkgs-libmpv1 {
          inherit system;
          config.allowUnfree = true;
        }).mpv-unwrapped);
    in
    {
      packages = forAllSystems (system: rec {
        cinetry = pkgsFor.${system}.callPackage ./cinetry.nix {
          libmpv1 = libmpv1For.${system};
        };
        default = cinetry;
      });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.cinetry}/bin/cinetry";
        };
      });
    };
}
