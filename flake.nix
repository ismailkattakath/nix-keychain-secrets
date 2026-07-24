{
  description = "macOS login-Keychain secret store as a noun-verb CLI (secret set/get/rm/ls) + a home-manager loader that exports your secrets into EVERY shell, including non-login / AI-agent bash via $BASH_ENV. Nothing in the Nix store or git.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-substituters = [ "https://ismailkattakath.cachix.org" ];
    extra-trusted-public-keys = [
      "ismailkattakath.cachix.org-1:7BbEvLpASY7aNUZfpzRMWir1zjU3nqmllBTl8p7gr2I="
    ];
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
    }:
    let
      inherit (nixpkgs) lib;
      darwinSystems = [
        "aarch64-darwin"
      ];
      allSystems = darwinSystems ++ [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAll = systems: f: lib.genAttrs systems (system: f system nixpkgs.legacyPackages.${system});
    in
    {
      # The reusable home-manager module (system-agnostic; no-op off macOS).
      homeManagerModules.keychainSecrets = ./modules/keychain-secrets.nix;
      homeManagerModules.default = self.homeManagerModules.keychainSecrets;

      # The CLIs, also runnable directly (macOS-only).
      packages = forAll darwinSystems (
        _: pkgs:
        let
          set-secret = pkgs.callPackage ./packages/set-secret.nix { };
        in
        {
          inherit set-secret;
          secret = pkgs.callPackage ./packages/secret.nix { inherit set-secret; };
          remove-secret = pkgs.callPackage ./packages/remove-secret.nix { inherit set-secret; };
          default = pkgs.callPackage ./packages/secret.nix { inherit set-secret; };
        }
      );
      apps = forAll darwinSystems (
        system: _:
        lib.genAttrs [ "secret" "set-secret" "remove-secret" ] (name: {
          type = "app";
          program = "${self.packages.${system}.${name}}/bin/${name}";
        })
        // {
          default = {
            type = "app";
            program = "${self.packages.${system}.secret}/bin/secret";
          };
        }
      );

      # Eval check: the module wires BASH_ENV + emits a loader carrying the
      # one-time-per-tree sentinel (macOS home-manager config).
      checks = forAll darwinSystems (
        system: pkgs:
        let
          hm = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              self.homeManagerModules.default
              {
                home.username = "tester";
                home.homeDirectory = "/Users/tester";
                home.stateVersion = "24.05";
                programs.keychainSecrets.enable = true;
              }
            ];
          };
          loader = hm.config.home.file.".config/secrets/loader.sh".source;
        in
        {
          module-evaluates = pkgs.runCommand "keychain-secrets-eval" { } ''
            test "${hm.config.home.sessionVariables.BASH_ENV}" = "/Users/tester/.config/secrets/loader.sh"
            grep -q "__SECRETS_KEYCHAIN_LOADED" ${loader}
            grep -q "secret()" ${loader}
            echo ok > "$out"
          '';
          inherit (self.packages.${system}) secret set-secret remove-secret;
        }
      );

      formatter = forAll allSystems (_: pkgs: pkgs.nixfmt-rfc-style);
    };
}
