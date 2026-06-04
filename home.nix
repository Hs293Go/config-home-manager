{ config, pkgs, ... }:

let
  tl-pinned = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/63dacb46bf939521bdc93981b4cbb7ecb58427a0.tar.gz";
    sha256 = "1lr1h35prqkd1mkmzriwlpvxcb34kmhc9dnr48gkm8hh089hifmx";
  }) { };
  tl = tl-pinned.texlive;
  tex = tl.combine {
    inherit (tl)
      scheme-medium
      latexmk
      collection-latex
      collection-latexextra
      collection-latexrecommended
      collection-bibtexextra
      collection-luatex
      collection-langcjk
      collection-publishers
      collection-fontsrecommended
      collection-fontsextra
      ut-thesis
      ;
  };
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "hs293go";
  home.homeDirectory = "/home/hs293go";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    curl
    git
    zip
    unzip
    rsync
    dtach

    # Build and dev tools: general
    act

    # Build and dev tools: C++
    ninja
    clang-tools
    gdb
    ccache

    # Build and dev tools: python
    pipx

    # Editors
    neovim
    tree-sitter
    nixfmt

    # Shell QOL
    fd
    ripgrep
    bat
    fzf
    tldr
    zoxide

    # Fonts
    pkgs.zsh-powerlevel10k
    nerd-fonts.fira-code

    xclip
    direnv

    nodejs_22

    lazygit

    tex

    minicom
    htop
    nmap
    kdePackages.okular
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme;
      if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
        . ~/.nix-profile/etc/profile.d/nix.sh
      fi

      source ~/.p10k.zsh

      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh

      autoload edit-command-line;
      zle -N edit-command-line
      bindkey -M vicmd vv edit-command-line

      if [ $TERM = "xterm-kitty" ] ; then
        alias ssh='kitty +kitten ssh'
      fi

      # ROS env: setup.zsh sources ros2-argcomplete.zsh (which defines the
      # generic _python_argcomplete function and compdef's it to ros2) and
      # later rosidl-argcomplete.zsh (which calls a bare `compinit` and wipes
      # _comps, losing the ros2 registration). Re-register ros2 -- and reuse
      # the same generic function for colcon (it dispatches on ''${words[1]}
      # at runtime, so one function serves both).
      #
      # Note: argcomplete's _python-argcomplete "global" completer is not
      # useful in zsh; see lines 141-146 of that file -- it early-returns
      # to _default unless $service == -default-, which never happens for a
      # direct command via _postpatcomps.
      if [ -d /opt/ros ] ; then
        ros_setup_scripts=(/opt/ros/*/setup.zsh)
        if [ "''${#ros_setup_scripts[@]}" -eq 1 ] ; then
          source "''${ros_setup_scripts[@]:0:1}"
          if typeset -f _python_argcomplete >/dev/null; then
            compdef _python_argcomplete ros2 colcon
          fi
        fi
      fi

    '';
    envExtra = ''
      # Bootstrap logic managed by you
      [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ] && source "$HOME/.nix-profile/etc/profile.d/nix.sh"
      [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
    '';
    plugins = [
      {
        name = "zsh-vi-mode";
        src = pkgs.zsh-vi-mode;
      }
      {
        name = "omz-debian";
        src = pkgs.fetchgit {
          url = "https://github.com/ohmyzsh/ohmyzsh.git";
          rev = "18d0a63"; # commit hash
          sha256 = "sha256-cgGgWW6WNUIHKOEV7jfHQuClD2WRwSSFOQ76GG8ixrA=";
        };
        file = "plugins/debian/debian.plugin.zsh";
      }
    ];

  };

  programs.fzf = {
    enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true; # or enableBashIntegration / enableFishIntegration
    silent = true;
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".p10k.zsh".source = ./dotfiles/p10k.zsh;
    ".prettierrc".source = ./dotfiles/prettierrc;
    ".gitignore".source = ./dotfiles/gitignore;
    ".gitconfig".source = ./dotfiles/gitconfig;
    ".vimrc".source = ./dotfiles/vimrc;
    ".config/kitty/kitty.conf".source = ./dotfiles/kitty.conf;
    ".ipython/profile_default/ipython_config.py".source =
      ./dotfiles/ipython/profile_default/ipython_config.py;
    ".config/lazygit/config.yml".source = ./dotfiles/lazygit_config.yml;
    ".config/just/justfile".source = ./dotfiles/justfile;
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/hs293go/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
    PATH = "$HOME/.local/bin:/usr/local/cuda/bin:$PATH";
    LD_LIBRARY_PATH = "/usr/local/cuda/lib64:$LD_LIBRARY_PATH";
  };

  home.shellAliases = {
    so = "source";
    sc = "exec $SHELL";
    cls = "clear";
    ll = "ls -l";
    la = "ls -la";
    l = "ls -CF";
    md = "mkdir -p";
    da = "dtach -A ~/.dtach/default.sock bash";
    hm = "home-manager";
    hmb = "home-manager build";
    hms = "home-manager switch";
    fdf = "fd -t f";
    fdd = "fd -t d";
    fdr = "fda -uI --follow";
    ffd = "fd -F";
    xc = "xclip -selection clipboard";
    ga = "git add";
    gaa = "git add --all";
    gap = "git apply";
    gapa = "git add --patch";
    gapt = "git apply --3way";
    gau = "git add --update";
    gav = "git add --verbose";
    gb = "git branch";
    gbD = "git branch --delete --force";
    gba = "git branch --all";
    gbd = "git branch --delete";
    gbl = "git blame -w";
    gbm = "git branch --move";
    gbnm = "git branch --no-merged";
    gbr = "git branch --remote";
    gbs = "git bisect";
    gbsb = "git bisect bad";
    gbsg = "git bisect good";
    gbsn = "git bisect new";
    gbso = "git bisect old";
    gbsr = "git bisect reset";
    gbss = "git bisect start";
    gc = "git commit --verbose";
    gcm = "git checkout main";
    gcd = "git checkout develop";
    "gc!" = "git commit --verbose --amend";
    "gcn!" = "git commit --verbose --no-edit --amend";
    gcB = "git checkout -B";
    gca = "git commit --verbose --all";
    gcam = "git commit --all --message";
    gcb = "git checkout -b";
    gcf = "git config --list";
    gcfu = "git commit --fixup";
    gcl = "git clone --recurse-submodules";
    gcn = "git commit --verbose --no-edit";
    gco = "git checkout";
    gcor = "git checkout --recurse-submodules";
    gcp = "git cherry-pick";
    gcpa = "git cherry-pick --abort";
    gcpc = "git cherry-pick --continue";
    gcs = "git commit --gpg-sign";
    gd = "git diff";
    gdca = "git diff --cached";
    gdcw = "git diff --cached --word-diff";
    gds = "git diff --staged";
    gdt = "git diff-tree --no-commit-id --name-only -r";
    gdw = "git diff --color-words";
    gf = "git fetch";
    gfo = "git fetch origin";
    ghh = "git help";
    gl = "git pull";
    glg = "git log --stat";
    glgp = "git log --stat --patch";
    glo = "git log --oneline --decorate";
    gm = "git merge";
    gma = "git merge --abort";
    gmc = "git merge --continue";
    gmff = "git merge --ff-only";
    gms = "git merge --squash";
    gp = "git push";
    gpd = "git push --dry-run";
    gpf = "git push --force-with-lease --force-if-includes";
    "gpf!" = "git push --force";
    gpod = "git push origin --delete";
    gpr = "git pull --rebase";
    gpra = "git pull --rebase --autostash";
    gprv = "git pull --rebase -v";
    gpu = "git push upstream";
    gpv = "git push --verbose";
    gr = "git remote";
    gra = "git remote add";
    grb = "git rebase";
    grba = "git rebase --abort";
    grbc = "git rebase --continue";
    grbi = "git rebase --interactive";
    grbo = "git rebase --onto";
    grbs = "git rebase --skip";
    grev = "git revert";
    grf = "git reflog";
    grh = "git reset";
    grhh = "git reset --hard";
    grhk = "git reset --keep";
    grhs = "git reset --soft";
    grm = "git rm";
    grmc = "git rm --cached";
    grmv = "git remote rename";
    grrm = "git remote remove";
    grs = "git restore";
    grss = "git restore --source";
    grst = "git restore --staged";
    gru = "git reset --";
    grup = "git remote update";
    grv = "git remote --verbose";
    gsb = "git status --short --branch";
    gsh = "git show";
    gsi = "git submodule init";
    gss = "git status --short";
    gst = "git status";
    gsta = "git stash push";
    gstc = "git stash clear";
    gstd = "git stash drop";
    gstl = "git stash list";
    gstp = "git stash pop";
    gsts = "git stash show --patch";
    gsu = "git submodule update";
    gsw = "git switch";
    gswc = "git switch --create";
    gta = "git tag --annotate";
    gts = "git tag --sign";
    gwt = "git worktree";
    gwta = "git worktree add";
    dils = "docker image ls";
    dila = "docker image ls -a";
    dcls = "docker container ls";
    dcla = "docker container ls -a";
    drm = "docker rm";
    "drm!" = "docker rm -f";
    dirm = "docker image rm";
    "dirm!" = "docker image rm -f";
    dps = "docker ps";
    dpa = "docker ps -a";
    dlogs = "docker logs";
    dexec = "docker exec -it";
    dcu = "docker compose up";
    dcud = "docker compose up -d";
    dcd = "docker compose down";
    rcp = "rsync -avzhP --exclude=.git --exclude=build";
    icat = "kitten icat"; # display images inline
    icc = "kitten icat --clear"; # clear displayed images

    # Clipboard (works over SSH via kitty protocol)
    clip = "kitten clipboard"; # pipe stdin to clipboard
    paste = "kitten clipboard --get-clipboard";
    # Diff (syntax-highlighted, side-by-side)
    kdiff = "kitten diff";
    d = "kitten diff";

    # Hints (grab paths/URLs/hashes from screen)
    hint = "kitten hints";

    # Themes
    theme = "kitten themes"; # interactive theme picker

    # Unicode / emoji input
    uni = "kitten unicode_input";

    # Transfer files over the terminal (no SSH config needed)
    kt = "kitten transfer";

    # Show key/escape codes for debugging
    keys = "kitten show_key";

    # Notify when a long command finishes (kitty 0.36+)
    notify = "kitten notify";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
