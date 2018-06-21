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
        vk.A = Pairing.G2Point([0xae2526f73891020d0b4cc25257af9864bf47e3aec4b908fad3862f78dd8a043, 0x6af0d906b11cc1c6371e48f449e032cdf60a769cd838a3808dfb310f6c0b5bf], [0x2e140c2b681c37ff79b82734c2b7eed0cba1491ffd7834dee6bb0b6ad46169d0, 0x75a6dc46122fa66dfe6ee56de860bfd3cd8b781dab7215e9a7a033bba799cd5]);
        vk.B = Pairing.G1Point(0x2d83e98630a1344b7cec7033759a1cd4399f47de4c0f2367c425a13383b80c91, 0x1c95fc29b4fa7f34102b9670c6f97fb92c3e5c60b4ea3540329975539ac7113);
        vk.C = Pairing.G2Point([0x1f8feda146837ec50f0059c3771e1c36e3131b82a9c730615092c3fb44ca93c, 0x250689b7611cf03573ada3b54dae1f0ebeb90197464e2996dd2295d66af27155], [0x29e49710a26a99763b0953385c8557f7c1dd234b803b46c3e6d148610c9ec7b7, 0x23f51af335d9a243b04b2de82a82ae92d0c23285e4eafac875300f9360ffd7a8]);
        vk.gamma = Pairing.G2Point([0x2b26029ac2d1352196e9a13e078a66213d160ef00bea55ab00d97d554ac3777b, 0x21345eab8f108c591434a1264f8878a020f0a61f36e2dfe4ad64c73f9434fcc9], [0x7b57f32a898a23df9a658ca687386564c5b0290525fdb3fe24499914313b5fd, 0xee60c293afc726eecd68c6bbfbbfb166f3bf0fba033d8f796256a60080fe338]);
        vk.gammaBeta1 = Pairing.G1Point(0x19d53318b7437c089a6b5934037f2ec00c3d0f167314cf91a3a29eee687ee400, 0x243a6b1f56de52038f8bfe2dd28fe1583f1b5bf88f16dda2d77f5e261a1bb8e1);
        vk.gammaBeta2 = Pairing.G2Point([0x2e91790e22b0e46a7ebd8aedc462e8b1e9411d03761cbdedd5fa822fded6a0bf, 0x6455822925f95dabdf4e55228fd040247f2cb064a0896069e6318ba7dce5cd], [0x1f91143b84a27149ce86b899b53b8aec9b00a82e88f4cfdc4ebf60e801e2a2b5, 0x8aeb4bfc63f4e5452f27b30e9923a833ee71868038e87a5411582dc4290afff]);
        vk.Z = Pairing.G2Point([0x438260c649b7cd3b39f92b8fed603af75c47fc25feabbb87ff097d7dec8d04f, 0x2e57d9b7341424de51745329227d14b93f27492fe23751445345bb05bfc731f1], [0x2af52a5898d86e5f562edbf5ac5cb5f7a93cb002ece35d8ddd763123115719da, 0x210a2757ac15912c496415c27177966d3e72bbd808ea777ab9abe357ea2eaecf]);
        vk.IC = new Pairing.G1Point[](6);
        vk.IC[0] = Pairing.G1Point(0xc1e7fd777324fea1ee6d1ff8a4bd9df2bde5511adcc027882c671d02cbd366e, 0x2891c2778ba1c09765ee936908791cea59da6685b749c24dea75e73f58be3eef);
        vk.IC[1] = Pairing.G1Point(0xb904434a8711dd70756b3f4c167444be8bf91cda95ba00888490103252d0f34, 0x167c8c7636395949944678a67677808cebcdc3a978930d8d45c6899975c6b246);
        vk.IC[2] = Pairing.G1Point(0x2508d81c6bc55b867c816878997c1b368a4dcd2de94b28cbb9b2eda6d93232bd, 0x160e5cb4e56aaa5ffedb327356720ff3a107b3ad4c751da75099d53545357089);
        vk.IC[3] = Pairing.G1Point(0x19bc9b1fe66ff7757b0dc7ba67fcc425633c581fa8f3baa6795109bf8bc95551, 0x39800525c28633425898eb66a4e6f04438957f6ca26552cf59ae0bd4ba42c89);
        vk.IC[4] = Pairing.G1Point(0x2daff938f00b0f83d44af1d5a66934cfb8b6dd770dc6dcd6744667be91abe19c, 0x1c2e074fc15f316dd0deb659e9295a5f931773b48b65e71bbdd0f6ab13aacc06);
        vk.IC[5] = Pairing.G1Point(0x20a8b23a0a0332a3650a05d6c86169b8638f9ce9183ce041a871aafc6a3b063f, 0x72620e56d2c13d8246dc76cf2f492bec85753fb677079fb8b6fb9be5fb4ce28);
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
