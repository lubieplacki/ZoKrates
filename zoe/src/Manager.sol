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
  uint constant max_leaves = 2**20;
  uint constant tree_size = 2**21;
  struct Mtree {
    uint current;
    uint[idx] leaves;
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

  function getCommitments() constant returns (uint[max_leaves] res_commitments) {
    return MT.leaves;
  }

  function getCommitmentsTree() constant returns (uint[tree_size] res_tree) {
    uint i;
    for (i = 0; i < max_leaves; i++)
      res_tree[max_leaves + i] = MT.leaves[i];

    for (i = max_leaves - 1; i >= 0; i--)
      res_tree[i] = sha256(res_tree[2 * i], res_tree[2 * i + 1]);

    return res_tree;
  }

  function getRoot() constant returns (uint root) {
    return getCommitmentsTree()[1];
  }

  function add_commitment(uint commitment) internal returns (bool res) {
    if (MT.current == max_leaves)
      return false;
    MT.leaves[MT.current] = commitment;
    MT.current++;

    return true;
  }
  event TransactionEvent(uint[2] encoded_msg);
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
      uint[2] encoded_msg
    ) public payable returns (bool res) {
    if (deposit_internal(a, a_p, b, b_p, c, c_p, h, k, commitment, msg.value)) {
      commitments[commitment] = true;
      roots[getRoot()] = true;
      emit TransactionEvent(encoded_msg);
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
    uint invalidator,
    uint root,
    uint commitment_out,
    uint commitment_change
  ) internal returns (bool res) {
    if (invalidators[invalidator])
      return false;
    if (commitments[commitment_change])
      return false;
    if (commitments[commitment_out])
      return false;
    if (roots[root] == false)
      return false;
    if (tv.verifyTx(a, a_p, b, b_p, c, c_p, h, k, [invalidator, root, commitment_out, commitment_change]) == false)
      return false;
    if (MT.current + 2 >= max_leaves)
      return false;
    add_commitment(commitment_out);
    add_commitment(commitment_change);
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
    uint invalidator,
    uint root,
    uint commitment_out,
    uint commitment_change,
    uint[2] encoded_msg
  ) public returns (bool res) {
    if (transaction_internal(a, a_p, b, b_p, c, c_p, h, k, invalidator, root, commitment_out, commitment_change)) {
      invalidators[invalidator] = true;
      commitments[commitment_out] = true;
      commitments[commitment_change] = true;
      roots[getRoot()] = true;
      emit TransactionEvent(encoded_msg);
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
    uint invalidator,
    uint root,
    uint value_out,
    uint commitment_change
  ) internal returns (bool res) {
    if (invalidators[invalidator])
      return false;
    if (commitments[commitment_change])
      return false;
    if (roots[root] == false)
      return false;
    if (tv.verifyTx(a, a_p, b, b_p, c, c_p, h, k, [invalidator, root, value_out, commitment_change]) == false)
      return false;
    return add_commitment(commitment_change);
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
    uint invalidator,
    uint root,
    uint value_out,
    uint commitment_change
  ) public returns (bool res) {
    if (transaction_internal(a, a_p, b, b_p, c, c_p, h, k, invalidator, root, value_out, commitment_change)) {
      invalidators[invalidator] = true;
      commitments[commitment_change] = true;
      roots[getRoot()] = true;
      msg.sender.transfer(value_out);
      return true;
    } else {
      return false;
    }
  }
}
