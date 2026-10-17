# artcraft-flake

A Nix flake for the [ArtCraft apps](https://getartcraft.com/apps), a suite of
open-source, native creative apps written in Rust:

| App                                                     | What it's for | Package |
| ------------------------------------------------------- | ------------- | ------- |
| [PhotoCraft](https://github.com/storytold/photocraft)   | Image editing | `photocraft` |
| [LightCraft](https://github.com/storytold/lightcraft)   | Photo library and raw developing | `lightcraft` |
| [VectorCraft](https://github.com/storytold/vectorcraft) | Vector illustration | `vectorcraft` |
| [FigCraft](https://github.com/storytold/figcraft)       | Interface design | `figcraft` |
| [DesignCraft](https://github.com/storytold/designcraft) | Page layout | `designcraft` |
| [FilmCraft](https://github.com/storytold/filmcraft)     | Video editing | `filmcraft` |
| [EffectCraft](https://github.com/storytold/effectcraft) | Motion graphics and VFX | `effectcraft` |
| [SoundCraft](https://github.com/storytold/soundcraft)   | Audio recording and mixing | `soundcraft` |
| [WordCraft](https://github.com/storytold/wordcraft)     | Word processing | `wordcraft` |
| [GridCraft](https://github.com/storytold/gridcraft)     | Spreadsheets | `gridcraft` |
| [DeckCraft](https://github.com/storytold/deckcraft)     | Presentations | `deckcraft` |
| [PdfCraft](https://github.com/storytold/pdfcraft)       | PDFs | `pdfcraft` |
| [CADCraft](https://github.com/storytold/cadcraft)       | CAD and drafting | `cadcraft` |
| [ArtCraft Launcher](https://github.com/storytold/craft-launcher) | Installing and opening the apps | `artcraft-launcher` |
| **Everything**                                          | All of the above | `artcraft` (default) |

Each app comes with its desktop app (e.g. `photocraft`) and a command-line tool
(e.g. `photocraft-cli`). The launcher has no command-line tool.

It works on Linux (Intel/AMD and ARM) and macOS (Intel and Apple Silicon).

Every package is the app's official binary release, pinned in `releases.json`
and updated daily. The default package, `artcraft`, installs every app.

What an app package installs depends on the platform:

- **Linux:** the release tarball, patched to run on Nix, with the desktop
  entry, `MIME` type and icons.
- **macOS:** the universal release (one build for Intel and Apple Silicon).
  `<App>.app` goes in `Applications/` and `<app>-cli` in `bin/`. `bin/<app>`
  launches the app. Upstream's code signature is left intact.

The launcher installs and updates apps itself, outside Nix. You don't need it
to use the apps from this flake.

## Usage

Run commands from this directory, or replace `.` with the flake's path or URL.

Run an app (`nix run .` alone runs PhotoCraft):

```sh
nix run .#photocraft
```

Run an app's CLI:

```sh
nix run .#photocraft-cli -- --help
```

### Home Manager

The flake has a Home Manager module. Import it, then turn on the apps you want:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    artcraft.url = "github:JamyGolden/artcraft-flake";
  };

  outputs = { nixpkgs, home-manager, artcraft, ... }: {
    homeConfigurations.me = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux; # Adjust for your architecture
      modules = [
        artcraft.homeModules.default
        {
          programs.artcraft.photocraft.enable = true;
          programs.artcraft.filmcraft.enable = true;
        }
      ];
    };
  };
}
```

Every app has the same two options:

| Option                           | What it does |
| -------------------------------- | ------------ |
| `programs.artcraft.<app>.enable` | Installs the app (its desktop app and command-line tool) |
| `programs.artcraft.<app>.package` | Which build to install. Defaults to the official release |

**Note**: In MacOS, a config with `home.stateVersion` set to `"25.11"` or later,
Home Manager copies the apps into `~/Applications/Home Manager Apps`, where
Spotlight finds them. With an older `stateVersion` it only symlinks the apps,
and Spotlight ignores symlinks. To get the copy anyway, set:

```nix
targets.darwin.copyApps.enable = true;
```

### NixOS (Linux)

Add the flake as an input and install its packages:

```nix
{
  inputs.artcraft.url = "github:JamyGolden/artcraft-flake";

  outputs = { nixpkgs, artcraft, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = with artcraft.packages.${pkgs.stdenv.hostPlatform.system}; [
            photocraft
            filmcraft
            # or `default` for every app
          ];
        })
      ];
    };
  };
}
```

### macOS

Add the packages to `environment.systemPackages`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    artcraft.url = "github:JamyGolden/artcraft-flake";
  };

  outputs = { nix-darwin, artcraft, ... }: {
    darwinConfigurations.mymac = nix-darwin.lib.darwinSystem {
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.hostPlatform = "aarch64-darwin"; # or "x86_64-darwin" on an Intel Mac
          environment.systemPackages = with artcraft.packages.${pkgs.stdenv.hostPlatform.system}; [
            photocraft
            filmcraft
          ];
        })
      ];
    };
  };
}
```

After `darwin-rebuild switch`, the apps are copied into `/Applications/Nix
Apps/`, where Spotlight and Launchpad pick them up. The CLIs are on your
`PATH`.

The first time, macOS may ask you to give your terminal **App Management**
permission (System Settings > Privacy & Security > App Management). nix-darwin
needs this to update the apps.

### Overlay

This flake also provides an overlay, `overlays.default`, which adds every app
and the `artcraft` bundle to your own nixpkgs (`pkgs.photocraft`,
`pkgs.artcraft`, ...).

#### NixOS or nix-darwin:

```nix
{ pkgs, ... }: {
  nixpkgs.overlays = [ artcraft.overlays.default ];
  environment.systemPackages = [ pkgs.photocraft pkgs.filmcraft ];
}
```

#### Home Manager

```nix
{ pkgs, ... }: {
  nixpkgs.overlays = [ artcraft.overlays.default ];
  home.packages = [ pkgs.photocraft pkgs.filmcraft ];
}
```

#### nixpkgs:

```nix
pkgs = import nixpkgs {
  inherit system;
  overlays = [ artcraft.overlays.default ];
};
```

## Development shells

```sh
nix develop             # for working on any of the apps
nix develop .#filmcraft # for working on one app
```

- `nix develop` puts every app's release binaries on `PATH` (the `artcraft`
  bundle), and has the libraries for every app.
- `nix develop .#<app>` puts that app's release binaries on `PATH`, and has the
  libraries for that app.

## Adding an app

Add an entry to `apps.nix`, then pin its release with `./scripts/update.sh <app>`. See the top of `apps.nix` for
the fields.

## Updating

A daily GitHub Action (`.github/workflows/update.yml`) runs
`nix flake update` and `./scripts/update.sh`, and commits `flake.lock` and
`releases.json` if `nix flake check` passes. Users then get the new releases
with `nix flake update` in their own flake.

Each app's release is pinned in `releases.json`. To move every app to its
latest release:

```sh
./scripts/update.sh
```

or just some of them:

```sh
./scripts/update.sh photocraft filmcraft
```

The script reads each release's `SHA256SUMS.txt` from GitHub.

## Checks

`nix flake check` fetches every app's release, builds the dev shell, and
smoke-tests the result. By default it checks only the system you run it on.

- `<app>-version`: each CLI runs and reports the pinned release
- `photocraft-cli`: converts an image headlessly, including decoding a HEIC
  file (the `heif` feature), and has a commit and build date compiled in
- `<app>-install` (Linux only): the desktop file validates, the MIME type and
  icons are installed, and the libraries the app loads at runtime are on its
  `RPATH`
- `home-manager-module`: the Home Manager module installs exactly the enabled
  apps, and uses the `package` you give it
- `home-manager-generation` (not on Intel Macs): a real Home Manager
  configuration using the module builds, manual included, and contains exactly
  the enabled apps. This is the only check that uses the `home-manager` flake
  input, so Nix doesn't fetch it otherwise

## Notes

- FilmCraft can use NVIDIA's CUDA and NVDEC libraries, which come with the
  graphics driver rather than from Nix. Its binaries also search
  `/run/opengl-driver/lib`, where NixOS puts them.
- Intel Macs use a separate nixpkgs input (`nixpkgs-x86_64-darwin`, the 26.05
  branch), because nixpkgs-unstable dropped `x86_64-darwin` in 26.11. That branch
  gets security fixes until the end of 2026. After that it keeps working, but
  frozen. Everything else uses nixpkgs-unstable.
- Flakes only see files tracked by git, so a new or renamed file must be at
  least `git add -N`'d before `nix` will pick it up.
