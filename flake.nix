{ inputs =
    { nixpkgs.url = "github:NixOS/nixpkgs/fb0c047e30b69696acc42e669d02452ca1b55755";
      utils.url = "github:ursi/flake-utils/8";
      shelpers.url = "gitlab:platonic/shelpers";
    };

  outputs = { utils, ... }@inputs:
    with builtins;
    utils.apply-systems { inherit inputs; }
      ({ pkgs, ... }:
         let
           l = p.lib; p = pkgs;
           inherit (inputs.shelpers.lib p) eval-shelpers shelp;
           shelpers = eval-shelpers
             [ ({ config, ... }:
                  { shelpers.".".General =
                      { build =
                          { description = "build the js file";
                            make-app = true;
                            script = "${l.getExe p.elmPackages.elm} make src/Main.elm --optimize --output elm.js";
                          };

                        watch =
                          { description = "build on changes";
                            script = "find -name '*.elm' | entr ${build}";
                          };

                        play =
                          { description = "launch the game";
                            cache = false;
                            script = "build && ${l.getExe p.firefox} index.html";
                          };

                        shelp = shelp config;
                      };
                  }
               )
             ];
         in
         { devShells.default =
             p.mkShell
               { packages =
                   [ p.entr ]
                   ++ (with p.elmPackages;
                       [ elm
                         elm-format
                         elm-language-server
                       ]);

                 shellHook =
                   ''
                   ${shelpers.functions}
                   shelp
                   '';
               };

           inherit (shelpers) apps;
           shelpers = shelpers.files;
         });
}
