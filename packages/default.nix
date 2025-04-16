{
  inputs,
  system,
}: final: prev: {
  app2unit = inputs.app2unit.packages.${system}.default;
}
