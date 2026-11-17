((c-ts-base-mode
  . ((eglot-server-programs
      . (((c-ts-mode c++-ts-mode)
          . ("python3" "/ABSOLUTE/PATH/TO/my-docker-clangd.py"
             "--image" "emacs-eglot-linux:local"
             "--host-root" "/ABSOLUTE/PATH/TO/linux-docker"
             "--container-root" "/work/linux"
             "--database" "/work/linux")))))))
