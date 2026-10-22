{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # One entry per machine; `home-manager switch` picks the one matching
      # $USER, so no machine needs a local edit.
      usernames = [
        "hs293go" # Z690
        "hei-shing-helson-go" # Dell Pro Max 16 Plus
      ];
      mkHome =
        username:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home.nix
            {
              home.username = username;
              home.homeDirectory = "/home/${username}";
            }
          ];
        };
    in
    {
      homeConfigurations = nixpkgs.lib.genAttrs usernames mkHome;

      formatter.${system} = pkgs.nixfmt;
    };
}
