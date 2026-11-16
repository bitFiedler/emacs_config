((c-ts-base-mode
  . ((eglot-server-programs
      . (((c-ts-mode c++-ts-mode)
          . ("python3" "/home/mp/emacstools/my-docker-clangd.py"
             "--image" "docker.gde.kapschtraffic.com/leo/leo:trixie"
             "--host-root" "/home/mp/sourcen/leo/leo")))))))
