((c-ts-base-mode
  . ((eglot-server-programs
      . (((c-ts-mode c++-ts-mode)
          . ("python3" "/ABSOLUTE/PATH/TO/my-docker-clangd.py"
             "--image" "emacs-eglot-demo:local"
             "--host-root" "/ABSOLUTE/PATH/TO/docker-make"
             "--container-root" "/work/project"
             "--database" "/work/project")))))))
