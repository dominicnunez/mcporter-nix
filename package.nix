{
  lib,
  buildNpmPackage,
  fetchzip,
  makeWrapper,
  nodejs_24,
  bash,
}:

let
  versionInfo = lib.importJSON ./version.json;
  version = versionInfo.version;

  # Home Manager detection and symlink management wrapper script
  wrapperScript = ''
    #!@bash@/bin/bash

    # Verbose output (opt-in via MCPORTER_NIX_VERBOSE=1)
    verbose=''${MCPORTER_NIX_VERBOSE:-0}

    # Home Manager detection function
    is_home_manager_active() {
      [[ -n "''${HM_SESSION_VARS:-}" ]] ||
      [[ -d "$HOME/.config/home-manager" ]] ||
      [[ -d "/etc/profiles/per-user/$USER" ]]
    }

    # Symlink management (only when target changes)
    manage_symlink() {
      local target_dir="$HOME/.local/bin"
      local symlink_path="$target_dir/mcporter"
      local binary_path="@out@/bin/.mcporter-unwrapped"

      # If Home Manager is active, clean up our symlink if it exists and skip creation
      if is_home_manager_active; then
        if [[ -L "$symlink_path" ]]; then
          local link_target
          link_target="$(readlink "$symlink_path" 2>/dev/null || echo "")"
          # Match exact current path OR any older version of this package
          if [[ "$link_target" == "$binary_path" ]] || \
             [[ "$link_target" == /nix/store/*-mcporter-* ]]; then
            rm -f "$symlink_path"
            [[ "$verbose" == "1" ]] && echo "[mcporter-nix] Removed symlink (Home Manager now manages mcporter)" >&2
          fi
        fi
        return 0
      fi

      # Check if symlink already points to the correct target
      local current_target
      current_target="$(readlink -f "$symlink_path" 2>/dev/null || echo "")"

      if [[ "$current_target" == "$binary_path" ]]; then
        return 0  # Already correct
      fi

      # Create or update symlink
      mkdir -p "$target_dir"
      ln -sf "$binary_path" "$symlink_path"
      [[ "$verbose" == "1" ]] && echo "[mcporter-nix] Created symlink: $symlink_path -> $binary_path" >&2
    }

    # Run symlink management
    manage_symlink

    # Execute the actual binary
    exec "@out@/bin/.mcporter-unwrapped" "$@"
  '';
in
buildNpmPackage {
  pname = "mcporter";
  inherit version;

  nodejs = nodejs_24;

  src = fetchzip {
    url = "https://registry.npmjs.org/mcporter/-/mcporter-${version}.tgz";
    hash = versionInfo.hash;
  };

  npmDepsHash = versionInfo.npmDepsHash;

  # Required for npm cache permissions
  makeCacheWritable = true;

  # Skip lifecycle scripts - the package tarball already contains pre-built dist/ files
  # Use --legacy-peer-deps to handle peer dependency conflicts in the upstream package
  npmFlags = [
    "--ignore-scripts"
    "--legacy-peer-deps"
  ];

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  # mcporter is pre-built TypeScript, no build step needed
  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
        # Rename the original binary
        mv $out/bin/mcporter $out/bin/.mcporter-unwrapped

        # Install wrapper script
        cat > $out/bin/mcporter << 'WRAPPER_EOF'
    ${wrapperScript}
    WRAPPER_EOF
        chmod +x $out/bin/mcporter

        # Substitute placeholders
        substituteInPlace $out/bin/mcporter \
          --replace-quiet "@out@" "$out" \
          --replace-quiet "@bash@" "${bash}"
  '';

  meta = {
    description = "TypeScript runtime and CLI for the Model Context Protocol";
    homepage = "https://mcporter.dev";
    downloadPage = "https://www.npmjs.com/package/mcporter";
    changelog = "https://github.com/steipete/mcporter/releases";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.all;
    mainProgram = "mcporter";
  };
}
