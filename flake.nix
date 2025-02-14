{
  description = "Nix based dev-env";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = nixpkgs.legacyPackages.${system};
      });

      scriptDrvs = forEachSupportedSystem ({ pkgs }:
        let
          getSystem = "SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem')";
          forEachDir = exec: ''
            for dir in */; do
              (
                cd "''${dir}"

                ${exec}
              )
            done
          '';
        in
        {
          format = pkgs.writeShellApplication {
            name = "format";
            runtimeInputs = with pkgs; [ nixpkgs-fmt ];
            text = ''
              shopt -s globstar

              nixpkgs-fmt -- **/*.nix
            '';
          };

          # only run this locally, as Actions will run out of disk space
          build = pkgs.writeShellApplication {
            name = "build";
            text = ''
              ${getSystem}

              ${forEachDir ''
                echo "building ''${dir}"
                nix build ".#devShells.''${SYSTEM}.default"
              ''}
            '';
          };

          check = pkgs.writeShellApplication {
            name = "check";
            text = forEachDir ''
              echo "checking ''${dir}"
              nix flake check --all-systems --no-build
            '';
          };

          update = pkgs.writeShellApplication {
            name = "update";
            text = forEachDir ''
              echo "updating ''${dir}"
              nix flake update
            '';
          };
        });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages =
            with scriptDrvs.${pkgs.system}; [
              build
              check
              format
              update
            ] ++ [ pkgs.nixpkgs-fmt ];
        };
      });

      packages = forEachSupportedSystem ({ pkgs }:
        rec {
          default = dvt;
          dvt = pkgs.writeShellApplication {
            name = "dvt";
            bashOptions = [ "errexit" "pipefail" ];
            text = ''
              if [ -z "''${1}" ]; then
                echo "no template specified"
                exit 1
              fi

              TEMPLATE=$1

              nix \
                --experimental-features 'nix-command flakes' \
                flake init \
                --template \
                "github:the-nix-way/dev-templates#''${TEMPLATE}"
            '';
          };
        }
      );
    }

    //

    {
      templates = rec {
        default = empty;

        bun = {
          path = ./bun;
          description = "Bun development environment";
        };

        c-cpp = {
          path = ./c-cpp;
          description = "C/C++ development environment";
        };

        empty = {
          path = ./empty;
          description = "Empty dev template that you can customize at will";
        };

        go = {
          path = ./go;
          description = "Go (Golang) development environment";
        };

        java = {
          path = ./java;
          description = "Java development environment";
        };

        lua = {
          path = ./lua;
          description = "Lua development environment";
        };

        nix = {
          path = ./nix;
          description = "Nix development environment";
        };

        node = {
          path = ./node;
          description = "Node.js development environment";
        };

        ocaml = {
          path = ./ocaml;
          description = "OCaml development environment";
        };

        opa = {
          path = ./opa;
          description = "Open Policy Agent development environment";
        };

        protobuf = {
          path = ./protobuf;
          description = "Protobuf development environment";
        };

        python = {
          path = ./python;
          description = "Python development environment";
        };

        shell = {
          path = ./shell;
          description = "Shell script development environment";
        };

        zig = {
          path = ./zig;
          description = "Zig development environment";
        };

        # Aliases
        c = c-cpp;
        cpp = c-cpp;
      };
    };
}
