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
        vk.A = Pairing.G2Point([0x1f809650588d4aa4e76af189ad7107cf53af1724b34ee34f7bf325f1874d1998, 0x28048bcc282c2f86677e08c892e14858982fb97ae5c1ae3f6fe8129512b5e1db], [0x1689ab596043392ada9887d2395031faf7b9ba4c09def0e9fb1bf101a42906c5, 0x2460d5f21021675a9b854584af0793639dec6b29c0c832c21dfdd468d949a60f]);
        vk.B = Pairing.G1Point(0xafc2de720ce481b1a44e411cbb8f522d8fc5fd3f3ab5c5895a1ff7ba4f99ec5, 0x1b376f9c876eab22f6ae6abf95599ef74ea4e117c93637f7ae9d8ad1599587df);
        vk.C = Pairing.G2Point([0x2869dbdc6cb09b3543f793dd9dd6bc348b59d73d1fcf276149f7ee30c3f9c725, 0xd9e5471fff35100e84ee54bccfd7955c508ec37f8549e03a8affc9eacdab076], [0x6357085e5bdc176930433b9efa387f2141be288a32a8888e56374b56a50a840, 0x12bb7d43f568d69c7f678c1c8307c61fc1f331be534d426a9e59080377775ba5]);
        vk.gamma = Pairing.G2Point([0xc786422192ba92d204d2cdaf9e5b86a8396f4d495f6af90cf7a4c9918f814, 0x304ea800f7ad62df1132e2eea29294617dc7d1f3b29e3cd60f975494a1afad07], [0x10be770e68f170fa504634744fc5dfaf4690a1437ec63be5a78530b61cf6dbe, 0x122aa44d6e1d7a747bc398dd45dd7746dd342d2a2acdcf9012371cfd2f463ac8]);
        vk.gammaBeta1 = Pairing.G1Point(0xcfa7bdc24192e46b0a58e9ff0dae677f4710a8309fe8521a5d2e17b01ee816, 0x21e44e70e67450068e6a1b85d432300ed1e98735be3d87db2cc5dc3eb0a35f6f);
        vk.gammaBeta2 = Pairing.G2Point([0x46f49577790a045870cf60980df445b2955422a6bcc4a0db341baefcc3414ca, 0x2f478eea60b11d229933f2bef7a005c1885b92744953e7bb8eb51f686929dae4], [0xea068ad16850635eff73701be2bee93df368a42a2b9fec35ac681d40b81dfc5, 0x1b0bb14ac67684a39761456ef62eee4c6a780ac443788df5420c5d9581f54f73]);
        vk.Z = Pairing.G2Point([0x17228e038833b63d2343b61a955e0a1ee81288e1a8e53ed9212e9188f192780, 0x135beb20295b4d2a8ef03961340cff6b52398119735287d53311b91edeb0e889], [0xb5ed05532f44ef03f14e4a5f4326eb1820069b67401466cd374fe5c16556fd7, 0x1eb474bde0e86254a576601a536583568928994c19974b0212658ba391b65d10]);
        vk.IC = new Pairing.G1Point[](6);
        vk.IC[0] = Pairing.G1Point(0x219abe193b43df936fd561bbea5782f2752ea87b5816a42a49c526ab5231a4d2, 0x1a6a1cb711e70569be9e8ad309fb002fb421a640e08d06d4f5057153d418cf5c);
        vk.IC[1] = Pairing.G1Point(0x163a213c9dccf84847441491fdd15313d23c30bd2cb0ad797438266568856e10, 0x28670eea80dcbef8f17866da76e494b2f340142441602ec33698430467c3685a);
        vk.IC[2] = Pairing.G1Point(0xdc5bff9c553a53f8413b2302e95e35c3bee9b027a4b4a7abe3687e801328da1, 0x11dba05a263a5b64f08f1af2b3ba793e15607f22f752db4d60e45a4d22b4daac);
        vk.IC[3] = Pairing.G1Point(0x495aff5c2a249dd8617bb7b75227a5d0f1a6f083b0b6e113cdef44cd8fce89c, 0x1ab72a190a74a4081a8022694318274ec814dced0f0bacc15073ee6a2645b377);
        vk.IC[4] = Pairing.G1Point(0x2516a5721a30864f8b3eef523f38080dac89fea2d22662c4d9e666d82f2eb8d7, 0x196164642a121795fd52bd071483a2d0a82712be183c977e6482ee018d16899c);
        vk.IC[5] = Pairing.G1Point(0xc38b399bff2ccc0cecc7c33480c4a8f934ceaee3acfbbcc11cf4b4b7d7a2213, 0x3ef0134d04a424a8e9caf069c74e81c0ddaeedb221325a54ed9541512f37790);
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
