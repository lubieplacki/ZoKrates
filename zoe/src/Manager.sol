pragma solidity ^0.4.14;

contract DepositVerifier {
  function verifyTx(
            uint[2] a,
            uint[2] a_p,
            uint[2][2] b,
            uint[2] b_p,
            uint[2] c,
            uint[2] c_p,
            uint[2] h,
            uint[2] k,
            uint[2] input
        ) returns (bool) {}
}
contract TransactionVerifier {
  function verifyTx(
            uint[2] a,
            uint[2] a_p,
            uint[2][2] b,
            uint[2] b_p,
            uint[2] c,
            uint[2] c_p,
            uint[2] h,
            uint[2] k,
            uint[4] input
        ) returns (bool) {}
}
contract WithdrawVerifier {
  function verifyTx(
            uint[2] a,
            uint[2] a_p,
            uint[2][2] b,
            uint[2] b_p,
            uint[2] c,
            uint[2] c_p,
            uint[2] h,
            uint[2] k,
            uint[4] input
        ) returns (bool) {}
}
contract Manager {
  DepositVerifier dv;
  TransactionVerifier tv;
  WithdrawVerifier wv;
  mapping (uint => bool) public invalidators;
  mapping (uint => bool) public commitments;
  mapping (uint => bool) public roots;
  event TransactionEvent(string encrypted_msg);
  event RegisterEvent(uint pk, string enc_pk, address from);
  uint constant max_leaves = 64;
  uint constant tree_size = 128;
  struct Mtree {
    uint current;
    uint[max_leaves] leaves;
  }
  Mtree public MT;

  function Manager(address _dv, address _tv, address _wv) public {
    dv = DepositVerifier(_dv);
    tv = TransactionVerifier(_tv);
    wv = WithdrawVerifier(_wv);
    MT.current = 0;
    uint i;
    for (i = 0; i < max_leaves; i++)
      MT.leaves[i] = 0x0;
  }
  function register(uint pk, string enc_pk) public returns (bool res) {
    emit RegisterEvent(pk, enc_pk, msg.sender);
    return true;
  }
  function getCommitments() view public returns (uint[max_leaves] res_commitments) {
    return MT.leaves;
  }
  function checkInvalidator(uint invalidator) view public returns (bool exists) {
    return invalidators[invalidator];
  }

  function getCommitmentsTree() view public returns (uint[tree_size] res_tree) {
    uint i;
    for (i = 0; i < max_leaves; i++)
      res_tree[max_leaves + i] = MT.leaves[i];

    for (i = max_leaves - 1; i > 0; i--)
      res_tree[i] = uint(sha256(res_tree[2 * i], res_tree[2 * i + 1]));

    return res_tree;
  }

  function getSha256(uint8 input[512]) view public returns (uint hash) {
    return uint(sha256(input));
  }

  function getRoot() view public returns (uint root) {
    return getCommitmentsTree()[1];
  }

  function add_commitment(uint commitment) internal returns (bool res) {
    if (MT.current == max_leaves)
      return false;
    MT.leaves[MT.current] = commitment;
    MT.current++;

    return true;
  }

  function deposit_internal(
    uint[2] a,
    uint[2] a_p,
    uint[2][2] b,
    uint[2] b_p,
    uint[2] c,
    uint[2] c_p,
    uint[2] h,
    uint[2] k,
    uint commitment,
    uint value
  ) internal returns (bool res) {
    if (commitments[commitment])
      return false;
    if (dv.verifyTx(a, a_p, b, b_p, c, c_p, h, k, [commitment, value]) == false)
      return false;
    return add_commitment(commitment);
  }
  function deposit(
      uint[2] a,
      uint[2] a_p,
      uint[2][2] b,
      uint[2] b_p,
      uint[2] c,
      uint[2] c_p,
      uint[2] h,
      uint[2] k,
      uint commitment,
      string encrypted_msg
    ) public payable returns (bool res) {
    if (deposit_internal(a, a_p, b, b_p, c, c_p, h, k, commitment, msg.value)) {
      commitments[commitment] = true;
      roots[getRoot()] = true;
      emit TransactionEvent(encrypted_msg);
      return true;
    } else {
      msg.sender.transfer(msg.value);
      return false;
    }
  }

  function transaction_internal(
    uint[2] a,
    uint[2] a_p,
    uint[2][2] b,
    uint[2] b_p,
    uint[2] c,
    uint[2] c_p,
    uint[2] h,
    uint[2] k,
    uint[4] public_input
  ) internal returns (bool res) {
    if (invalidators[public_input[0]])
      return false;
    if (roots[public_input[1]] == false)
        return false;
    if (commitments[public_input[2]])
      return false;
    if (commitments[public_input[3]])
      return false;

    if (tv.verifyTx(a, a_p, b, b_p, c, c_p, h, k, public_input) == false)
      return false;
    if (MT.current + 2 >= max_leaves)
      return false;
    add_commitment(public_input[2]);
    add_commitment(public_input[3]);
    return true;
  }

  function transaction(
    uint[2] a,
    uint[2] a_p,
    uint[2][2] b,
    uint[2] b_p,
    uint[2] c,
    uint[2] c_p,
    uint[2] h,
    uint[2] k,
    uint[4] public_input, //invalidator, root, commitment_out, commitment_change
    string encrypted_msg_out,
    string encrypted_msg_change
  ) public returns (bool res) {
    if (transaction_internal(a, a_p, b, b_p, c, c_p, h, k, public_input)) {
      invalidators[public_input[0]] = true;
      commitments[public_input[2]] = true;
      commitments[public_input[3]] = true;
      roots[getRoot()] = true;
      emit TransactionEvent(encrypted_msg_out);
      emit TransactionEvent(encrypted_msg_change);
      return true;
    } else {
      return false;
    }
  }
  function withdraw_internal(
    uint[2] a,
    uint[2] a_p,
    uint[2][2] b,
    uint[2] b_p,
    uint[2] c,
    uint[2] c_p,
    uint[2] h,
    uint[2] k,
    uint[4] public_input
  ) internal returns (bool res) {
    if (invalidators[public_input[0]])
      return false;
    if (roots[public_input[1]] == false)
        return false;
    if (commitments[public_input[3]])
      return false;

    if (tv.verifyTx(a, a_p, b, b_p, c, c_p, h, k, public_input) == false)
      return false;
    return add_commitment(public_input[3]);
  }

  function withdraw(
    uint[2] a,
    uint[2] a_p,
    uint[2][2] b,
    uint[2] b_p,
    uint[2] c,
    uint[2] c_p,
    uint[2] h,
    uint[2] k,
    uint[4] public_input, //invalidator, root, value_out, commitment_change
    string encrypted_msg_change
  ) public returns (bool res) {
    if (transaction_internal(a, a_p, b, b_p, c, c_p, h, k, public_input)) {
      invalidators[public_input[0]] = true;
      commitments[public_input[3]] = true;
      roots[getRoot()] = true;
      msg.sender.transfer(public_input[2]);
      emit TransactionEvent(encrypted_msg_change);
      return true;
    } else {
      return false;
    }
  }
}
