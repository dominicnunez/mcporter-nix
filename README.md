# mcporter-nix

Nix flake for [MCPorter](https://mcporter.dev) - TypeScript runtime and CLI for the Model Context Protocol.

**Features:**
- Direct npm packaging from the official distribution
- Smart Home Manager detection with automatic symlink management
- Pre-built binaries via Garnix for instant installation
- Daily automated updates for new MCPorter versions
- Linux and macOS support (x86_64 and aarch64)

## Quick Start

**Try without installing:**
```bash
nix run github:dominicnunez/mcporter-nix
```

**Install to your profile:**
```bash
nix profile add github:dominicnunez/mcporter-nix
```

## Binary Cache

This flake uses [Garnix](https://garnix.io) for CI and binary caching. The `nixConfig` in `flake.nix` automatically configures the cache, so pre-built binaries are fetched without any manual setup.

If prompted to allow configuration from the flake, answer yes or add `accept-flake-config = true` to your Nix configuration.

## Flake Usage

### As a Flake Input

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    mcporter-nix.url = "github:dominicnunez/mcporter-nix";
  };

  outputs = { self, nixpkgs, mcporter-nix, ... }: {
    # Your configuration here
  };
}
```

### NixOS Configuration

```nix
{ inputs, pkgs, ... }:
{
  environment.systemPackages = [
    inputs.mcporter-nix.packages.${pkgs.system}.default
  ];
}
```

### Home Manager Configuration

```nix
{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.mcporter-nix.packages.${pkgs.system}.default
  ];
}
```

### Using the Overlay

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    mcporter-nix.url = "github:dominicnunez/mcporter-nix";
  };

  outputs = { self, nixpkgs, mcporter-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ mcporter-nix.overlays.default ];
      };
    in {
      # pkgs.mcporter is now available
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.mcporter ];
      };
    };
}
```

## Home Manager Integration

This package includes smart Home Manager detection. When Home Manager is detected, the package skips creating symlinks to respect your declarative configuration.

**Detection methods:**
- `HM_SESSION_VARS` environment variable is set
- `~/.config/home-manager` directory exists
- `/etc/profiles/per-user/$USER` directory exists

**Behavior:**
- **Home Manager detected:** Skips symlink creation and cleans up any orphaned symlinks
- **Home Manager absent:** Creates `~/.local/bin/mcporter` symlink for convenience

**Automatic cleanup:** If you previously installed mcporter standalone (creating a `~/.local/bin/mcporter` symlink) and later enable Home Manager, the package will automatically remove the orphaned symlink on first run to prevent PATH conflicts.

## Environment Variables

| Variable | Description |
|----------|-------------|
| `MCPORTER_NIX_VERBOSE` | Set to `1` to enable Home Manager detection and symlink management messages |

Example:
```bash
export MCPORTER_NIX_VERBOSE=1
```

## Updating

**If using `nix profile add`:**
```bash
nix profile upgrade '.*mcporter.*'
```

**If using as a flake input:**
```bash
nix flake update mcporter-nix
nixos-rebuild switch  # or home-manager switch
```

## Contributing

### Development Setup

```bash
git clone https://github.com/dominicnunez/mcporter-nix
cd mcporter-nix
nix develop  # enters shell with dev tools
nix build
./result/bin/mcporter --version
```

### Update Workflow

The `update.sh` script checks for new MCPorter releases and updates `version.json`:

```bash
# Enter dev shell (provides required tools)
nix develop

# Check for updates (dry run)
./update.sh

# Update to latest version
./update.sh --update
```

The script:
1. Queries npm registry for the latest release
2. Compares against current version in `version.json`
3. With `--update`: fetches hashes and updates `version.json`

### Automated Updates

A GitHub Actions workflow runs daily to check for new releases. When a new version is found, it automatically:
1. Updates `version.json` with new version and hashes
2. Validates with `nix flake check`
3. Pushes directly to main

### Repository Structure

```
.
├── flake.nix           # Flake definition with outputs
├── flake.lock          # Locked dependencies
├── package.nix         # MCPorter package derivation
├── package-lock.json   # npm lockfile for reproducible builds
├── version.json        # Current version and hashes
├── update.sh           # Update detection and hash fetching script
├── README.md           # This file
├── garnix.yaml         # Garnix CI configuration
└── .github/workflows/
    ├── update.yml      # Daily update workflow
    └── ci.yml          # Garnix build validation
```

## License

This packaging is MIT-licensed.

MCPorter is developed by [steipete](https://github.com/steipete). See the [MCPorter repository](https://github.com/steipete/mcporter) for license details.
