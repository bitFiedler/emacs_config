((c-ts-base-mode
  . ((eglot-server-programs
      . (((c-ts-mode c++-ts-mode)
          . ("clangd" "--background-index"
             "--clang-tidy=false" "--header-insertion=never" "--enable-config")))))))
