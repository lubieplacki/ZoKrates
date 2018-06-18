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
        vk.A = Pairing.G2Point([0x25dd32dd2bcf9857144b969643e6feece1be81697992d46e1e3d4fcfa6ba7aed, 0x2a9a078bc70eb4dc0b9644fe920d397808065b3b7de66f33fd60e134e5d770ed], [0x162391400c82a3a74ae24fbff2770919be97893f0880d62dbef486f2bf14acee, 0x1df63517d0cfc7229addbcc4dd2f3fe77930f90888ce2a15ff052693dfcc77f]);
        vk.B = Pairing.G1Point(0x17a0f5935431ee5941e3034a3ef0900b7175890ce4ee348fc957fe4532f7ea46, 0x13e2acd2b61f7d0a75fcbe6fd9ff640ceb20754bed58057ede7c807c3b2048f1);
        vk.C = Pairing.G2Point([0x1a79d114435dbecb2f1c2bcfb4b4ae2526003714e16aea2ab38d62eea9efe98d, 0x2ea815df33be71dca7dc253533828852c190738b4eb547ea415ceb9eba5d57c], [0x2efe537077f43ae5bcd264dda80776899d29596cbddba4c2ca5ae0f7deb17b6c, 0xd44c618272ef4bf26359a8e2855cb397bf8d2a56d967215dfa94a320b17bd20]);
        vk.gamma = Pairing.G2Point([0x183a25d83a2878aa5b202eed215f16edb0004edeebb94d1f13e673a4ce381317, 0x187c3c97afd2d0246f8d961476d39bd379280c4f29404a882d08f058adf4ab32], [0x24d0cbd539e38955284e83e40ba239cff30d7f89101a2303db092067da0e30d3, 0x1a54a10d8d0566e7e399bdcbe43e7cd32ffb7f4f97cef0dead2482bde8ef789]);
        vk.gammaBeta1 = Pairing.G1Point(0x1721880944e8f316c31ed6a3c2dd2f20b7e384ab970270b4c140f255875d0115, 0x1bbbfc12ad5123a701997a1e72f13602fea053c794dada173ca487e67d9addd8);
        vk.gammaBeta2 = Pairing.G2Point([0x1d1a9f8834bc36749ba911700ada90ea5776034a22aa4a5cd61526366cad6b87, 0x2b30074e73014ee3a45957105dd6dcf55977c449e22ca87e9cae89cc454f8e02], [0x1834dc09d5c667f4122f2a5443f404c8364737b1e6518a2934d25221e7361088, 0x1eb8e1848bd1560af40ba53cf9eb64f08421273209c4523f27334c272892ddf6]);
        vk.Z = Pairing.G2Point([0x52db26a5c61ebf750a062f6f99bb86869961dc447cab1fe826124dbc4207dac, 0xa9852495c5594161eb00bd9ffcbd628799a80b16186e00e7aa0e295c3704990], [0x218d5b4c7e92f1fa39753ccc151293afd341f1b6049d09b7ee11bed2cf3023be, 0xc92b788a87b89334695951cf5f9d638f859e8d5099eab43d4058d9b6051e639]);
        vk.IC = new Pairing.G1Point[](6);
        vk.IC[0] = Pairing.G1Point(0x27b3fd54959e1fc981d0b2be4994969e276697d2c2aaa8369cf4e6dd23b08a5, 0x143d9259b03ca37292cb3380a07bc68297526e2e806153b5fbff7ed3b324e30f);
        vk.IC[1] = Pairing.G1Point(0x306ad113602571bc3b4c7003ea7a39e7fc657662d68d08c53f5bdc92b9617f6, 0x1b96d7aeb7c03919eeb9bf35740b3eb23e8fd1591f089067a49d16df31bfdb32);
        vk.IC[2] = Pairing.G1Point(0x23a65ce0db87e9719251842f41dac01c1864718c70a7ea489a240549cc2ea141, 0x19118ea883653516ba90205d64fd144d8ce263553aef2acb1c65ba2defcf36ec);
        vk.IC[3] = Pairing.G1Point(0x2594f60f9a9315d2aef99647b4fef93bf0436f7acc610ddc827407e0699fa464, 0xa624df1681bef1e5a7c138f7c97cd1fa6f24c1232ba9881941d24b72eeeb46d);
        vk.IC[4] = Pairing.G1Point(0x1000a16e6c5eca09d90dff41cf2c5d41ba10b7488a6328fd81e80e1427945f31, 0xcae6e0c7eea46f9c76ae9030836cec68c651efe8b24dec225a259d719de9451);
        vk.IC[5] = Pairing.G1Point(0x18a3ad203ee43d66fc97611ec88668a0b2c1f65ba88e3f5f12807cfac815952f, 0x1013e7653f12ed2f37d6b177edda3a5b51c360a49fbd2a510e6c1a27ebb41d9f);
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
