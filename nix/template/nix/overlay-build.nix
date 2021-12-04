final: prev: {
    # DESIGN: passing through GNU Hello as our example package
    my-hello = final.callPackage ({hello}: hello) {};
}
