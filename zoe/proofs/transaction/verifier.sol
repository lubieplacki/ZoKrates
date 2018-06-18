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
        vk.A = Pairing.G2Point([0x1392ec00574ae7cd29d27e3460052da03513416b083b40cb8c0a4ceea3c2daff, 0x2dc2fb28f7c768829480779fc30d47bcd56ce2b320f627c6281cbcd46bd32133], [0x20278a5fafeaaa57fe5b17ca8c2d6934850fe39d501c1c8813529c41161cd233, 0x1b1fda42a0488003c944958000e8adbf1149e34f1d90cd6b2c49ff0c0cffc132]);
        vk.B = Pairing.G1Point(0x2737756270e699be6d5015c54076b1fe6c92da89f8981b1438c306df7b5f8005, 0x2b2ee677dda6e7d74abb86b9255398882b8d11f9d40add441b406eb8ec790538);
        vk.C = Pairing.G2Point([0x17efb6327b7ed84763c187725e05e3c970a2400c2fafa0c85b56cef82cc7fb79, 0x172cb8dd35977afcbae34895db21b90ddaac0d8329a91ca1f83287d0e230b498], [0x20904fe3609084b8717ca79d38e215dd5579819563ad82715f4f36bbe6c542a, 0x2dd64e9e7e10910147653b66d83bb2c7d647cc721dccb486b6cd06eeb0995a1f]);
        vk.gamma = Pairing.G2Point([0x79bc87cd176bcc324eb18adc0e6b76d738eca3c0b2454d56aaf2edd08139658, 0x22d35b98d6bc3a3017e79d682f5a7319320f524288162449e66f29f61f7f5ac2], [0x11773ef88950795c77240a1ffa4a454ce6533f1db1195fffb8069b40c7480552, 0x77b1b112347de6444ab344d19dd99befa1bf2f29a9b27f986f82b4ec4653f9]);
        vk.gammaBeta1 = Pairing.G1Point(0x14df1867a09a7b9dfc06a849bdd757bfb83a39cc256e0c4e9d71b0be3f4ca062, 0x1847de0f1933df02d0d4caaa38e4383e760d01b39554db4a4ad3fb09a2190f9c);
        vk.gammaBeta2 = Pairing.G2Point([0x23c4ff7f36fecf0bbc34567bb23251549486bf4541307b199590773966c56836, 0x8064ddd50a242ac3adfc33fc2b527659f8caeafc97ec4b43daa5a8ea0671189], [0x15293787c12b40acf2932786555142f53f4a92408149e81c746708f4b7e34844, 0x1d97de8a990dd9348dcd7641d89c483022f486d2867d40afcbb433c6d97f5d04]);
        vk.Z = Pairing.G2Point([0x2e68c1cd9ceb207902c27165d72ad899a595cca1020e6e9f7ddf123115a02d11, 0xe4dbb0c4bd0178b06c62d6ba1b6b7f314f5030654676b658d0fac03d58716b2], [0x2fbf7d9f6b47f90a16d2cd4409b31a43423da5e335ad90a9b99c78ea680f5594, 0x426faa94f13c3ce233ef0154e8947af450fc515095059caab3b0725766c250f]);
        vk.IC = new Pairing.G1Point[](6);
        vk.IC[0] = Pairing.G1Point(0x60907d0ae7ecdecf02eab6058b4502ddef56b2b9fe16f5f3fdc611f363f2ecb, 0xe92e91e622c3d300e82fb6133cb97c0b2a7a694a0f4b690a7191af7888a12b5);
        vk.IC[1] = Pairing.G1Point(0x2357621bc5a51e041ed5ad820c515cc143cf96f83b22ba73fdfe877381b0471e, 0x17a6e21c7b4dc1fb730e57ce6bac04859b4859a1d8429e825dbaa497e7449682);
        vk.IC[2] = Pairing.G1Point(0x165756f45b07170e9ab9ee9df694ff34f61401d92122882c24686d3ab1300728, 0x13e1253eccb3f3f9bdb9436a5eabd9c81b4a6259243100e17ea88641eb463e21);
        vk.IC[3] = Pairing.G1Point(0xa1fc3d8b69cc67a35c10c97c3faa31a3b620692e1925d1090753fd54cb35b02, 0x171e222f02b53adaf2e69e399e4bd362df3b5e161157a02bd53f2508e5d6a58d);
        vk.IC[4] = Pairing.G1Point(0x17be59fdb7a2c281f366b1f02ba5cd613183cdd25683ea60d5b0f1a4e3890cd, 0x10e86d8e6d830518c9525fb3350157d1c54905f98578ea60b66d3453f8137c3a);
        vk.IC[5] = Pairing.G1Point(0x8be2a261394427659307198e218432a0579bbdeb626c4b13cded0eee1bb18ae, 0xd97a406eecc9af9691e3252378484a1ed842210d8426a05e4ccd42f43534fe);
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
