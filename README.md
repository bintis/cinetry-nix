# cinetry-nix

[Cinetry](https://github.com/gstory0404/Cinetry) packaged as a Nix flake.

The package wraps the official `.deb` from the Cinetry GitHub releases and patches the bundled Flutter + libmdk + media_kit binaries so they run on NixOS.

A GitHub Action checks for new Cinetry releases daily and commits version bumps automatically. Builds can be pushed to [Cachix](https://app.cachix.org/) so consumers don't have to rebuild on every upgrade.

## ⚠️ Disclaimer / 免责声明

**This is an unofficial, third-party Nix packaging.** It is **not affiliated with, endorsed by, or sponsored by** the Cinetry author ([@gstory0404](https://github.com/gstory0404)).

- **Cinetry is closed-source proprietary software.** Only the prebuilt `.deb` is publicly available; the source code is not. This repository contains **only the Nix packaging code** (the `.nix` files, workflow YAML, and `update.sh`) — it does **not** redistribute, mirror, or modify the Cinetry binary itself. At install time, Nix downloads the unmodified `.deb` directly from the upstream GitHub release.
- **No reverse engineering.** This packaging unpacks the upstream `.deb`, patches ELF interpreter / RPATH so the binary can locate Nix-store libraries, and wraps the launcher with environment variables. No proprietary code is decompiled, modified, or redistributed in source form.
- **No warranty.** The packaging code is provided **AS IS, without warranty of any kind**. The packager makes no guarantees that the resulting build behaves identically to the upstream `.deb`, is free of bugs, is secure, or is suitable for any particular purpose. Use at your own risk.
- **Upstream terms apply.** Your use of the Cinetry binary is governed by whatever terms the upstream author imposes — see the [Cinetry repository](https://github.com/gstory0404/Cinetry) for details. This repository grants you **no rights to Cinetry itself**; it only describes how to fetch and run it on Nix.
- **Takedown.** If the upstream author ([@gstory0404](https://github.com/gstory0404)) objects to this packaging for any reason, please open an issue here and the repository will be taken down promptly.
- **No support.** Bug reports about Cinetry itself (UI, playback, server compatibility, etc.) should go to the [upstream repo](https://github.com/gstory0404/Cinetry), **not** here. Issues opened here should be limited to Nix-packaging concerns (build failures, missing libraries, NixOS-specific integration).

简体中文版:

本仓库是 **非官方的第三方 Nix 打包**,与 Cinetry 原作者([@gstory0404](https://github.com/gstory0404))**无任何关联,也未获得其授权或认可**。

- **Cinetry 是闭源软件**,原作者只公开发布 `.deb` 安装包,并未开源代码。本仓库**仅包含 Nix 打包脚本**(`.nix` 文件、CI workflow、`update.sh`),**不分发、不镜像、也不修改 Cinetry 二进制本身**。安装时由 Nix 从原作者的 GitHub Release 直接下载未修改的 `.deb`。
- **无逆向工程。** 打包过程仅解包官方 `.deb`、修改 ELF interpreter 与 RPATH(让二进制能找到 Nix store 中的库)、并通过 wrapper 注入环境变量。**不反编译、不修改专有代码,也不以源码形式重新分发**。
- **不提供任何担保。** 打包代码按"原样"提供,**不保证**构建结果与上游 `.deb` 行为一致、无 bug、安全,或适合任何特定用途。使用风险自负。
- **遵守上游条款。** Cinetry 本体的使用须遵循原作者规定的条款,详见 [Cinetry 仓库](https://github.com/gstory0404/Cinetry)。本仓库**不授予你对 Cinetry 本身的任何权利**,只描述如何在 Nix 上获取并运行它。
- **下架请求。** 若原作者([@gstory0404](https://github.com/gstory0404))出于任何原因不希望此打包存在,请在本仓库提 issue,我会立即将仓库下架。
- **不提供支持。** 关于 Cinetry 本身的 bug(UI、播放、服务端兼容性等)请前往 [上游仓库](https://github.com/gstory0404/Cinetry) 反馈,**不要**在此仓库提。本仓库 issue 仅受理 Nix 打包相关问题(构建失败、缺库、NixOS 集成等)。

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

- **The packaging code** in this repository (`*.nix`, `update.sh`, workflow YAML, this README) is released under the MIT License — see the [Disclaimer](#%EF%B8%8F-disclaimer--免责声明) above.
- **The Cinetry binary** fetched at build time is **not** covered by that license. It belongs to the upstream author and its use is governed solely by whatever terms they set. The Nix derivation marks it as `unfree` for this reason — installing the package requires `allowUnfree = true` in your nixpkgs config, which is your explicit acknowledgement that you accept the upstream terms.
