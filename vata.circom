pragma circom 2.1.6;

template VataRoot() {
    signal input root;
    signal input challenge;

    signal output out;

    // Bind root and challenge
    out <== root * challenge;
}

component main = VataRoot();
