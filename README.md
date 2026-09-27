# openchamber-flake

Nix flake for [OpenChamber](https://openchamber.dev/) — the agentic development
environment built on the [OpenCode](https://opencode.ai) AI agent.

OpenChamber only ships the Linux desktop app as an AppImage, so this flake
repackages the official AppImage with
[`appimageTools`](https://nixos.org/manual/nixpkgs/stable/#ssec-pkgs-appimageTools).
Both upstream Linux architectures are supported: `x86_64-linux` and
`aarch64-linux`. The desktop AppImage bundles the matching OpenCode CLI, so it
works without a separate OpenCode installation.

## Usage

Try it:

```sh
nix run github:redyf/openchamber-flake
```

Install it into a profile:

```sh
nix profile install github:redyf/openchamber-flake
```

### Flake input

```nix
{
  inputs.openchamber.url = "github:redyf/openchamber-flake";
  inputs.openchamber.inputs.nixpkgs.follows = "nixpkgs";
}
```

Use the package directly:

```nix
{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    inputs.openchamber.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

Or through the overlay:

```nix
{ pkgs, inputs, ... }:
{
  nixpkgs.overlays = [ inputs.openchamber.overlays.default ];

  environment.systemPackages = [ pkgs.openchamber ];
}
```

Home Manager uses the same package set:

```nix
{ pkgs, inputs, ... }:
{
  home.packages = [
    inputs.openchamber.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

## Updating

```sh
./update.sh
```

The script reads the latest release from the GitHub API, converts the release
asset digests to SRI hashes and rewrites `sources.nix`. Nothing is downloaded
beyond the release metadata.

## Notes

- This repackages a binary distribution (`meta.sourceProvenance =
  binaryNativeCode`).
- In-app updates are unavailable: OpenChamber's updater refuses to run outside
  the original AppImage. Update through the flake instead.
- The desktop entry is normalized to run without `--no-sandbox`; Chromium's
  namespace sandbox is used instead, which works on systems with unprivileged
  user namespaces (required by `appimageTools` anyway).
- Wayland flags (`--ozone-platform-hint=auto`, etc.) are only passed when both
  `NIXOS_OZONE_WL` and `WAYLAND_DISPLAY` are set, following the common nixpkgs
  Electron convention.
- OpenChamber itself is MIT-licensed; so is this flake.

## Development

```sh
nix build          # build the package
nix flake check    # build the package as a check
nix fmt            # format flake.nix, package.nix and sources.nix
```
