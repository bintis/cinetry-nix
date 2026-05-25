# cinetry-nix

[Cinetry](https://github.com/gstory0404/Cinetry) packaged as a Nix flake.

The package wraps the official `.deb` from the Cinetry GitHub releases and patches the bundled Flutter + libmdk + media_kit binaries so they run on NixOS.

A GitHub Action checks for new Cinetry releases daily and commits version bumps automatically. Builds can be pushed to [Cachix](https://app.cachix.org/) so consumers don't have to rebuild on every upgrade.

## Usage

Add as a flake input:

```nix
{
  inputs.cinetry-nix.url = "github:bintis/cinetry-nix";

  outputs = { self, nixpkgs, cinetry-nix, ... }: {
    # ... wherever you build home-manager / NixOS config ...
    home.packages = [
      cinetry-nix.packages.x86_64-linux.cinetry
    ];
  };
}
```

To pick up upstream Cinetry updates:

```
nix flake update cinetry-nix
```

## Notes on the libmpv pin

Cinetry's bundled `media_kit` Flutter plugin (`libmedia_kit_video_plugin.so`) is linked against the libmpv 1.x SONAME (`libmpv.so.1`). Upstream mpv bumped to `libmpv.so.2` during the 0.35 release cycle, and current nixpkgs is on 0.41+. To resolve this without patching the upstream binary, the flake pulls `mpv-unwrapped` from `nixos-22.05` (mpv 0.34.1, last release with `libmpv.so.1`) as a second nixpkgs input. This input is used exclusively for the runtime library — nothing else in the package comes from it.

## Cachix

The flake's `nixConfig` already advertises the Cachix substituter, so `accept-flake-config = true` users get it automatically. Otherwise add to your `/etc/nix/nix.conf`:

```
substituters       = https://cinetry-nix.cachix.org https://cache.nixos.org
trusted-public-keys = cinetry-nix.cachix.org-1:Z4gu19/+YesNHODlAfE9cmPVOa5ckG8GZc0/x7IWm9g= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
```

## Supported systems

- `x86_64-linux`

Upstream Cinetry only ships an x86_64 Linux `.deb`.

## License

The packaging code in this repo is MIT. The Cinetry binary itself is the upstream author's; see the [Cinetry repository](https://github.com/gstory0404/Cinetry) for its terms.
