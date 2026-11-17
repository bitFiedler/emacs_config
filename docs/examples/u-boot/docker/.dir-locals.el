((c-ts-base-mode
  . ((eglot-server-programs
      . (((c-ts-mode c++-ts-mode)
          . ("python3" "/ABSOLUTE/PATH/TO/my-docker-clangd.py"
             "--image" "emacs-eglot-u-boot:local"
             "--host-root" "/ABSOLUTE/PATH/TO/u-boot-docker"
             "--container-root" "/work/u-boot"
             "--database" "/work/u-boot"
             "--remove-compile-flag=-fstack-usage"
             "--remove-compile-flag=-fno-toplevel-reorder"
             "--" "--enable-config")))))))
