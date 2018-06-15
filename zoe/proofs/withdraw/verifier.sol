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
        vk.A = Pairing.G2Point([0x2dc1091b9fb60e170ca99fc58eca7a9031edc6e3aa013168aab20a60dce7fa80, 0x178c37e620270028464fb47b297b907b20b7af6de1cc9cc44279d21a165962c1], [0xb6494a381d21aea90c3e063fb5fb05f302c0ff8d6e7f3b1cac96d14d80fb661, 0x1f490408a63521b35fe751f80ea19130f0f94fedf2599c92c761da288c29e1f6]);
        vk.B = Pairing.G1Point(0x12d91691732a0fb05d5f77cb6cb273b2c47b012bf3548a60a8634ae564cabf40, 0x126dc4b308dd15decf8613b2c3179f064365359f3332c6c16d3981858c7fff1d);
        vk.C = Pairing.G2Point([0x2904dbe6621c755c7153657d5c1b963b602dfa85a627349ca9beb4779a501197, 0xb438e759c8dae59d576de9be4c85b4aa6d72ae42d10bc43fc2781e3ee66f1a6], [0x2996ae926897a4fd9770c3ebbeffc3726f602fdce4668f26e67a76c0a1a5dc56, 0x26c8f5acdedace2e1ea333e013e5f81d8094c0d2f47802ee1897ddb475c8724b]);
        vk.gamma = Pairing.G2Point([0x12485fc4abda0ff8d97fedb57f965fbfc2a69693a21da334f7fe3b17898f54f9, 0x22392ea6b17f6c0892ced5846f69bd4208d27603051b543a9d544b6c2b63a8ff], [0x59497920612ae2d9ee7bae94201c24377d2a6aa01b55af9e05fc79f4b9e696f, 0x2089efcc12c3010611fcd43e25fb4630fdab477ff014c783c2ac399974d52b70]);
        vk.gammaBeta1 = Pairing.G1Point(0x823d23efbf28b601585442faf63f76d7d3d51235de44ccb294451352b2976e5, 0x104ea2184bdd00181fb46c5d29285fd43a3ed53b58a737ed9bfcecbb63971f93);
        vk.gammaBeta2 = Pairing.G2Point([0x12f665f4f9eaa27616940bf6a7d1b39506717c4ef6dff7b294bc2001d42b57a5, 0x1cea24b7908729695cdc5491103a0fcf69734b266e4d7765bbb82b78de3f4866], [0x1345d8d4075a8f296bbc79d8c446c6872358f2461cd841d9764420dc787915a8, 0x21d109d928abcabe3ab2d1867176862ad93bc612ac7e52cdc07db913cd385ea7]);
        vk.Z = Pairing.G2Point([0x2a23784176e9ccd736b620f4078e9d47fcc342d2acd7e37a1620665b6952854b, 0x2b00dd477ed9ca477dd70cc1ec1cddc97ec379ec507ffd2a45e9f062ac283c1], [0x2d59d303ebfdd3baf62124ab5bce19e12ef6df759f41d2af0edf2227e0247314, 0x15eba3025f2b3e95285fffefffa46bcb31fc490a8097909d617aa1a635cd8684]);
        vk.IC = new Pairing.G1Point[](6);
        vk.IC[0] = Pairing.G1Point(0x1ccc51c80c4d8ce84e18d69d11be8498d946b896b0a9ca08cbdd062f59b0820, 0x16dda5d76466691f24f4858405c88947e6c4a0b08ae90343f2cd9f086e7668f8);
        vk.IC[1] = Pairing.G1Point(0xbdc91df4de6f6c65b0d845b5e1f9ebc05c7055540391773161497775088e7d2, 0x14b091a059d1cc67928966624babc77444609d40cfeddbff32addd2ad3421c20);
        vk.IC[2] = Pairing.G1Point(0x138eb21044e131ee6eb856862f68583f39ce39bf508f87244dadd5580601aa30, 0x24d0eacfbb110936b8d3a3c847d4bdd9d59f5a9443c869c3ac0f8f8f320babcc);
        vk.IC[3] = Pairing.G1Point(0x1a5a6eb185bbd89a3fb756f9a54c529ca5e54f683bbf32548d4a743a5dcdea96, 0x1ad0d507a4423479a9e28d8db5fb193b66b18e67a2b5bcf79b0f172bfc58bcd1);
        vk.IC[4] = Pairing.G1Point(0x1d677f087d8d4bcb8f5520c146aaca0db627d5e3307cc0d69d977e162f016070, 0x2a8483b09bbb5839a42d635f6ee723964d19d0a89e6217d5c344fa8a5a33a6c9);
        vk.IC[5] = Pairing.G1Point(0x2f0f314e68afff846e7a93017550d62bd3ac78e5e936879d23f355e3bca49aa4, 0x2b91c624a28d395c22a24167b1a7e770b9f50aa904d90ec04ca2e5f87277fabe);
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
