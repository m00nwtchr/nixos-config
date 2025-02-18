self: super: {
  lens = super.lens.override (prev: {
    callPackage = fn: args: (prev.callPackage fn (args
      // {
        appimageTools =
          super.appimageTools
          // {
            extractType2 = args:
              super.appimageTools.extract args
              // {
                postExtract =
                  (args.postExtract or "")
                  + ''
                    touch $out/asddsa
                    truncate -s 0 $out/resources/app.asar.unpacked/node_modules/@lensapp/lenscloud-lens-extension/dist/main.js
                  '';
              };
          };
      }));
  });
}
