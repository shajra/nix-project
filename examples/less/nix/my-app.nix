{
  writeShellApplication,
  curl,
  w3m,
}:

writeShellApplication {
  name = "my-app";
  meta.description = "Example application";
  runtimeInputs = [
    curl
    w3m
  ];
  text = ''
    curl -s 'https://nixos.org' | w3m -dump -T text/html
  '';
}
