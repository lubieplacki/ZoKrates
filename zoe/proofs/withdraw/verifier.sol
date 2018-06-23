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
        vk.A = Pairing.G2Point([0x1e7097f728ad1d871d329b1b0ff37a0a40ce49bae9af8b212b2bdcf4ad045d84, 0xa3d53d1e54830d1e51b7bb66a9976ff660d57fd55891ada9b6bc660fb0892af], [0x11ccf2ca49bc01220481dae33d19bcf31c9569e7c19c53d38a480730f1843412, 0x2f0faf2818d7df5cd4b7ff4f0ac18060b7ba14c1a6aa71c75819eaee00af0607]);
        vk.B = Pairing.G1Point(0x2e6c61de68bd87585c6028c06f94c4aca86fd52d33085865b1d155a95d8395f2, 0x1bbacc204026799345758ea5f5a0c22532a2c475731d99c0ffb34d9f3c133ed1);
        vk.C = Pairing.G2Point([0x23aec864f90734f60cd2d96d648fd610130ebf49057c5c6bd570b59fb9efce1c, 0x85c23fa942f0976fd27debad45f35deff1a7a1a1031df6eca2509fdc70972c8], [0x1dc875d4ac4f9e8003cd0639aef22d16ef1a90f6d4d69fec5b98c585757b9a1e, 0x2244e92a6f79966fa3d4e01a634730a12cb15ef757c5a649a4df378afa931363]);
        vk.gamma = Pairing.G2Point([0x627cf7c31146f8358c02b7b9f8a688ab9924b0c7de36c9f2fb96e483426805c, 0x29842ccb660fa07a4fc387593c1e474d750babb85cc0d5d8a841af8f838ad3ab], [0x2e8565ba25b0f3c0f1cbf3b935318b14285af7d1bf88fc6461ee7c1364baac2e, 0x216a567fbd1484bf0d823324c45b26a1d82f7d1aeed80bb87ae34e179eb8acd4]);
        vk.gammaBeta1 = Pairing.G1Point(0x211a5145de46a7a55f8a2e5387af82ca4f22a646c90219c1c0608cb549b3b1e1, 0x1dff6d324f0449da5ff5bcf054361e6db02ac3ac68cc4e0dc08d132d26e5d7f7);
        vk.gammaBeta2 = Pairing.G2Point([0x2aef1e556b195566332cde7e3e2053f37e3eb6e6272609496c47b2567954e357, 0x2539e78f75f15b36c7fa4e09e075df33b5dc69b7df912575cd4fe23e6a7ab63a], [0x31c43ba54abbdfad29637fcc76b2f22cdbafae8338f955c89b22c9e45ef728f, 0x288673770c2fe7665229af979e0da528461cd8effb558136baa50e9c7c7fcef4]);
        vk.Z = Pairing.G2Point([0x14a31dd36e3a245d4474f715a144258fde5c6e3cb45ad0d4aba2e00124032c5, 0x299fa90251ab5b08fd6316436ddbc8c4602803da167c63b53f7c37b09274f525], [0x15643b515e75e90a22952edfd12ee11545c37e8a92fa2bc8a42c41cc92745456, 0x17f51fec74dcff7989638c027ed4fea05e0f5c5da653265e5d1b36418d5a6976]);
        vk.IC = new Pairing.G1Point[](6);
        vk.IC[0] = Pairing.G1Point(0x2a3cae364a7df8cebf18b3fe973966f8ae67b65d4fa0247426d4fd4d0c198ede, 0xde9bce34dcb6bbd3e4d9832a3cd1ddeed166528c8575156106c7da00932a562);
        vk.IC[1] = Pairing.G1Point(0x23b5e94e20df79d130afa31cfeb9fe1ccc1a50a31db31c1dcf2fe3b40102765e, 0x1b598747d3b04c2a8ffc951d6b35c5d5ebc7de5d61ea5a205cd9503f296cb3a8);
        vk.IC[2] = Pairing.G1Point(0xc26f6e7de4df05f4402f72db4051d60411bea2077db7f22c57c57e42b95ce92, 0x1c613e272c3be9b5107326efcc8c41598820420a0e5cb2654d56af9f8696f441);
        vk.IC[3] = Pairing.G1Point(0x823c8c26027294ab96a59d8e3090af776324ee6c5b8c10c59eb4f705893881e, 0x255b774a6e6f2042cbec143136d2783682bf02a6e93a245799a483068e34ceae);
        vk.IC[4] = Pairing.G1Point(0x268e3b743a82284f4d559106db341630cabe66ee62752e3a56698f85476dbd61, 0x7763c7c5d952f0681edb9b259a2ed3a06fbe03803852baf6e9b5c55f32a66b5);
        vk.IC[5] = Pairing.G1Point(0x55fd0795d15facc036567a4fb1cf2109789f824d0ca1eff4e9ebd0d8d47c40e, 0x2b260934130075d1587cc4a68bd0715e63565dae1457088f11f06a8e0274bfe7);
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
