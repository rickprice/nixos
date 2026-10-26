_:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Frederick Price";
        email = "fprice@pricemail.ca";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";
      alias = {
        st = "status";
        co = "checkout";
        lg = "log --oneline --graph --decorate";
      };
    };
  };
}
