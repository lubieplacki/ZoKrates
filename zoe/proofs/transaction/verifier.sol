// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.4.14;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point) {
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point p) pure internal returns (G1Point) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return the sum of two points of G1
    function addition(G1Point p1, G1Point p2) internal returns (G1Point r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 6, 0, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }
    /// @return the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point p, uint s) internal returns (G1Point r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 7, 0, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] p1, G2Point[] p2) internal returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 8, 0, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point a1, G2Point a2, G1Point b1, G2Point b2) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point a1, G2Point a2,
            G1Point b1, G2Point b2,
            G1Point c1, G2Point c2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point a1, G2Point a2,
            G1Point b1, G2Point b2,
            G1Point c1, G2Point c2,
            G1Point d1, G2Point d2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G2Point A;
        Pairing.G1Point B;
        Pairing.G2Point C;
        Pairing.G2Point gamma;
        Pairing.G1Point gammaBeta1;
        Pairing.G2Point gammaBeta2;
        Pairing.G2Point Z;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G1Point A_p;
        Pairing.G2Point B;
        Pairing.G1Point B_p;
        Pairing.G1Point C;
        Pairing.G1Point C_p;
        Pairing.G1Point K;
        Pairing.G1Point H;
    }
    function verifyingKey() pure internal returns (VerifyingKey vk) {
        vk.A = Pairing.G2Point([0x1ae3e0ca1d8d8faf7d096cb888afa08300c015c61026b99d5e04b866ab559925, 0x96912db5bbbe6afb157aa3812a0f22ea6f62051b491b10af3b3c1c3b9594e43], [0x2b5cdff552e06535b7290564ff64df841b90179ccb11f21f61eaddbf881816ab, 0x20559c98222dc386681ef4e72ab1e97d16bda3411506859efdf21c271d91d33d]);
        vk.B = Pairing.G1Point(0x2de19c0cf80719904a41e96639c64f8c3f50d54ad731c517fcdcf61e90263104, 0x8cec8359be566bf12d8519197252d7514e3da84b9a7041e12773c2261f23482);
        vk.C = Pairing.G2Point([0x21bb708b906a23569a3d737b8cdd395877d47b111cfd898d98677663977258bc, 0x2da2dcd4744b0d22b0cbe0f702241b4e9ab3931b7fca32775ef26b099ceb5ff4], [0x7d7af9feef78199280a627d455455913ef4ffa2de01b724d139cc277eb40159, 0x5b81a8748b036790b3b36170673993148963d084dc6cfabb511c098940bfa94]);
        vk.gamma = Pairing.G2Point([0x202d4f7781a78604b22cc5167e6f5e9e24f601be322225e96c7a2fc90c86227a, 0x1153053add8df46c06ede0c764f1c0934aa178713e50c9facb6d5d601147367c], [0x234dec66d39ae5162cc833ef937ec64f90b84da606dfdf3d42398d62a5e1d719, 0x29d564991f6216f8e5f71c4dd5022dcabef1d1fb579f6d556b515dc5674d26f1]);
        vk.gammaBeta1 = Pairing.G1Point(0x1d9372a96cc676961533dcd35f4f063e1cb2f1460da3b3bdcd26bca447fc3cb, 0xaa0d8784007f796a4d6fc02cfd976f56afb932e457e5756ca0a2abdbb2cfce1);
        vk.gammaBeta2 = Pairing.G2Point([0xfad027d0eb34169823145fd7ba4cf6ccffc54414afd833949bf820ccd671194, 0x2d889854a4e4a2e9f28f15a6885a876868064ac471e3b05ad96455261a3556c5], [0x2cf8fc372b0a2465900e1ee521a49769755d96b57bf21f21912e7354cb4252a1, 0x3044b161674ca2e21115fd2a7f7e198b2e95586ea28adc98b1d1f2fabfffe3b0]);
        vk.Z = Pairing.G2Point([0x2e540d858a64fd0250d85d1c704a9873d360f48f05081749d61d1457cde9388a, 0x1831451c0f2f9cb123bb1d4a8cc2e6eee4d6b8e61a973087fa7b88f9297f281], [0x2b447c9b99ea531856bd808ef420137b4626db10e0c733db7dec1f8d6caddfb6, 0x8984f6090c75e7876e7c81c2d4ff288a7273fa3d5cbc18ca211bcecae7ee6b5]);
        vk.IC = new Pairing.G1Point[](6);
        vk.IC[0] = Pairing.G1Point(0x1ea6672903724e216e06774a2ec0c9c933ac374ec88792a5f1303ab64ca255fe, 0x2bb2e5ea30f427067a39bb3dd162508aed5c6c23da6e9a7cd1750c175bb3ba28);
        vk.IC[1] = Pairing.G1Point(0x4d831d027a2eab8601537d1f2eddc8692ee13366d8e80bc7a0cf6b5c55449bd, 0x1c02859ab1b53cc959ffea812efa15d94be6afc3fb9b57ca266cb5a192719b75);
        vk.IC[2] = Pairing.G1Point(0x2702c9121cf1f73769bdf2696ae2d88576acdf361a8f170108568edb858845ee, 0x2aa09941356377c4b3a8152a3c6d266b5aae737f39f61852cc7b570842b35823);
        vk.IC[3] = Pairing.G1Point(0x2a77849ba58ea51882c7e719a3f3fcddd986003e5f4f77b8892dc0fc8ddd78a1, 0x1346b3cfd1611c63f19b2c9165fd6c115882d81dcb3629352c5c99a37c43be6a);
        vk.IC[4] = Pairing.G1Point(0x1b98db7c0c49785863aaa028826189a556bc5a16adb4e8f91e341b165f3d7a12, 0xadfae9480564d718bd6a319c769dead5421f2f6a18e0c69986f7da1a8196879);
        vk.IC[5] = Pairing.G1Point(0x258c08b53c7aab3b2518906b9fa8a898c5f8ad872fa79369f157064d89ee3326, 0x16e575a3a3b196875cdf19e8fde77d3264a41aab08277b16a4f4d76e62757428);
    }
    function verify(uint[] input, Proof proof) internal returns (uint) {
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++)
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd2(proof.A, vk.A, Pairing.negate(proof.A_p), Pairing.P2())) return 1;
        if (!Pairing.pairingProd2(vk.B, proof.B, Pairing.negate(proof.B_p), Pairing.P2())) return 2;
        if (!Pairing.pairingProd2(proof.C, vk.C, Pairing.negate(proof.C_p), Pairing.P2())) return 3;
        if (!Pairing.pairingProd3(
            proof.K, vk.gamma,
            Pairing.negate(Pairing.addition(vk_x, Pairing.addition(proof.A, proof.C))), vk.gammaBeta2,
            Pairing.negate(vk.gammaBeta1), proof.B
        )) return 4;
        if (!Pairing.pairingProd3(
                Pairing.addition(vk_x, proof.A), proof.B,
                Pairing.negate(proof.H), vk.Z,
                Pairing.negate(proof.C), Pairing.P2()
        )) return 5;
        return 0;
    }
    event Verified(string);
    function verifyTx(
            uint[2] a,
            uint[2] a_p,
            uint[2][2] b,
            uint[2] b_p,
            uint[2] c,
            uint[2] c_p,
            uint[2] h,
            uint[2] k,
            uint[5] input
        ) public returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.A_p = Pairing.G1Point(a_p[0], a_p[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.B_p = Pairing.G1Point(b_p[0], b_p[1]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        proof.C_p = Pairing.G1Point(c_p[0], c_p[1]);
        proof.H = Pairing.G1Point(h[0], h[1]);
        proof.K = Pairing.G1Point(k[0], k[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            emit Verified("Transaction successfully verified.");
            return true;
        } else {
            return false;
        }
    }
}
