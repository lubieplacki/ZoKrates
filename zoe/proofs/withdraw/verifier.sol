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
        vk.A = Pairing.G2Point([0x2b1407f6743077148fddf9029c785e49cec03abde35674649fbd5d5808667df5, 0xa005a3347333d61add1dddc82b2ccb1390e528df1d13bea9039a017e81fa827], [0x1911bce1cc02bd3520228c0c43aac2f23a48cb125ffe53e1d18073fd270b4030, 0x292129ffafbf1bab0758fb3df07f1bbbdbef6d4151e27b5f0b5a5be01d921629]);
        vk.B = Pairing.G1Point(0x19a2203b506559ba9b461e7cdbcb3fa92fe2358f2a0dcb0e77b78b1db15efaaf, 0x19f2f59eeda22a9facecc9edbaae7e4af21ad6254655204d2b7aaa93dbdaeb9a);
        vk.C = Pairing.G2Point([0x1ab4ccf4649b7ee5aca363dd4f6ba416615f920e7fe04e434abfdd226a5e0758, 0xb2aa36a7edc99a3fa21fddcf338f242b35b24e9d71a9220e9fe3f593e6cf3b7], [0x28566c211537d195410fcdeba1b046b672921d4aab591fe7139700dd63aff42a, 0x3b84b6aa703b92d16a4d5c3e32e71aac91cda94943520d067840c9f89ccdf7b]);
        vk.gamma = Pairing.G2Point([0x2ede0f8a4eb342890d28514ed80769d522005e9b1e09f2ace44d6bf76da144bc, 0x261f9dfc4ccf478a9f63233f8e4111f362cfd6d97b189d113ed828750a1c5984], [0xcf0738bbc7dc0caa3de62125d3a4b3fdc5bd1ff8519be3121eb832dfd368339, 0x4ed1cbf21ad2411bdf6e52c2fb5b88d2a227f46c024150837592003f43bd8f4]);
        vk.gammaBeta1 = Pairing.G1Point(0x27769d4c4a4e7efaa1b33d7e741f538c5071669520f3563f1ba9392603ab1198, 0xf2d7befa265b572bba0e8626c7119b10df54a8f21431456d032a763e0a656be);
        vk.gammaBeta2 = Pairing.G2Point([0x26eaa856a318547009be6199ddb968158eadda4bec3e29c446f2324d431e2e2a, 0x1e79d61a8a3963b96f13bce6fc756849b393f63356f071238a9d480e7fbd105f], [0x229ac5c7c0a5801f89a3682e52f487f0a857c509318424ba62f12e7583c31493, 0x650c7c9b7905840a570949b5318e3d31e6dad6690567255ac34caedff39c03d]);
        vk.Z = Pairing.G2Point([0x2fded99bbf6c9bcc5c2e9a4e95541bd0ff7b2bf6c9c7ca7afdf8c209bf6feb53, 0xafcb07a6195e8b4d972cd101fc789ae5dc9cf4520c54b1bc7912b6d11dcd794], [0x1cd6234a2ad3d6434c032ea38a663b7d85c3031490c1c5aede56ffe240658775, 0x2773239542825393a778edf5e3fd1e92d4897e143a56df1d003ae7216207c7d0]);
        vk.IC = new Pairing.G1Point[](6);
        vk.IC[0] = Pairing.G1Point(0xfbf4ec1730e37ca6e76c52c3559346390dac715eba12d49c253430ba6b352d5, 0x2d2166ef1d4ec650862f364c39554407b38fe386f7d59a7d54f6a8d952daaa03);
        vk.IC[1] = Pairing.G1Point(0x2834e1cad8f3db2b2e5c730f2b2b4f5dfa4af9f27767f9bfa0c009fc0a689066, 0x11ce679a1c473ff450f23291f41955d4c04a4b2b925496ebe51842dd314c217);
        vk.IC[2] = Pairing.G1Point(0x19203f550dff8f85befe0afee969381a8f8e693f85e100ac961da3dcef3cbac6, 0x1f84598befe5b5ad772980ae572f487fdcbd42efa02e5cffd9674522e7a9a9f);
        vk.IC[3] = Pairing.G1Point(0x1be8b9bc35411c1d81d790024a9654031c0a6dc4bd49e7928516b90ee96e15ef, 0x1886bd81a09899994f1fc160cdcad00ce58c00114b2c67c8f39ac3d78e1e8b69);
        vk.IC[4] = Pairing.G1Point(0xfebed1a93a60932326b9b5fa6e2c24d9734481786bed406d9c7286e403c75ca, 0x36b499e0af48864d90ffb2eb471334aea2e46095e0fdf96b3418cb27b6e8bcf);
        vk.IC[5] = Pairing.G1Point(0xa9536746b04eab366605e30639c934d3e83aa1cf1564baebc36f1ecaa1b5303, 0x20a7930942d01bf251395c1a37565eb462fd6d3d219ace9363783a3281e2cb61);
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
