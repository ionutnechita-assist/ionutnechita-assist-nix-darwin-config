{
  description = "Nix Darwin Config - Ionut Nechita";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
  let
    username = "assist";

    overlay = final: prev: {
      python313Packages = prev.python313Packages // {
        # Create a new package that includes all the standard extras
        fastapi-standard = prev.python313.withPackages (ps: with ps; [
          fastapi fastapi-cli httpx jinja2 python-multipart
          email-validator uvicorn pyjwt
        ]);
      };
    };

    configuration = { pkgs, ... }: {
      nixpkgs.overlays = [ overlay ];
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = [
        pkgs.btop
        pkgs.colima
        pkgs.curl
        pkgs.docker
        pkgs.docker-compose
        pkgs.file
        pkgs.git
        pkgs.git-repo
        pkgs.htop
        pkgs.man
        pkgs.nano
        pkgs.nix-zsh-completions
        pkgs.nixfmt-classic
        pkgs.nmap
        pkgs.nodejs_22
        pkgs.podman
        pkgs.podman-compose
        pkgs.python313Full
        pkgs.python313Packages.fastapi-standard
        pkgs.python313Packages.flask
        pkgs.python313Packages.pip
        pkgs.tailwindcss_4
        pkgs.tcpdump
        pkgs.vim
        pkgs.wget
        pkgs.yarn
        pkgs.zsh
        pkgs.zsh-autosuggestions
      ];

      # Necessary for using flakes on this system.
      nix.enable = false;
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # Home-manager integration
      users.users.${username} = {
        name = username;
        home = "/Users/${username}";
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${username} = { pkgs, ... }: {
          home.stateVersion = "24.11";

          programs.command-not-found = {
            enable = true;
          };

          programs.zsh = {
            enable = true;
            autosuggestion.enable = true;
            enableCompletion = true;

            oh-my-zsh = {
              enable = true;
              theme = "linuxonly";
              plugins = [
                "git"
                "python"
                "macos"
                "docker"
                "kubectl"
                "npm"
                "pip"
              ];
            };

            initExtra = ''
              export PATH=$HOME/.local/bin:$PATH
            '';

            shellAliases = {
              ll = "ls -la";
              ".." = "cd ..";
              nrs = "darwin-rebuild switch --flake .#${username}";
              nrb = "darwin-rebuild build --flake .#${username}";
            };
          };

          programs.git = {
            enable = true;
            userName = "Ionut Nechita";
            userEmail = "ionut.nechita@assist.ro";
          };

          home.packages = with pkgs; [
            ripgrep
            fd
            bat
            jq
            fzf
          ];
        };
      };
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#username
    darwinConfigurations.${username} = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        home-manager.darwinModules.home-manager
      ];
    };

    darwinPackages = self.darwinConfigurations.${username}.pkgs;
  };
}
