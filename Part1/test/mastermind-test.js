//[assignment] write your own unit test to show that your Mastermind variation circuit is working as expected
const chai = require("chai");
const ethers = require("hardhat").ethers;
const wasm_tester = require("circom_tester").wasm;
const buildPoseidon = require("circomlibjs").buildPoseidon;
const assert = chai.assert;

async function buildTestInput(testCase, poseidon) {
  const saltedSoln = ethers.BigNumber.from(ethers.utils.randomBytes(32));
  let F = poseidon.F;
  let res = poseidon([
    saltedSoln,
    testCase.guess[0],
    testCase.guess[1],
    testCase.guess[2],
    testCase.guess[3],
  ]);
  const testInput = {
    pubNumBlack: testCase.whiteNum,
    pubNumWhite: testCase.blackNum,
    extraClue: testCase.soln.reduce((partialSum, a) => partialSum + a, 0),
    pubSolnHash: F.toObject(res),
    privSalt: saltedSoln,

    pubGuessA: testCase.guess[0],
    pubGuessB: testCase.guess[1],
    pubGuessC: testCase.guess[2],
    pubGuessD: testCase.guess[3],
    privSolnA: testCase.soln[0],
    privSolnB: testCase.soln[1],
    privSolnC: testCase.soln[2],
    privSolnD: testCase.soln[3],
  };
  return { testInput, res };
}

describe("Number Mastermind test", function () {
  let circuit;
  let poseidon;
  let F;
  before(async function () {
    circuit = await wasm_tester(
      "contracts/circuits/MastermindVariation.circom"
    );
    await circuit.loadConstraints();
    poseidon = await buildPoseidon();
    F = poseidon.F;
  });
  it("Return correct if solution is correct", async () => {
    // input
    const testCase = {
      guess: [1, 2, 3, 4],
      soln: [1, 2, 3, 4],
      whiteNum: 4,
      blackNum: 0,
    };
    const { testInput, res } = await buildTestInput(testCase, poseidon);
    const witness = await circuit.calculateWitness(testInput, true);
    assert(F.eq(F.e(witness[1]), F.e(res)));
  });
  it("Return error if solution is wrong", async () => {
    // input
    const testCase = {
      guess: [1, 2, 3, 4],
      soln: [1, 2, 3, 5],
      whiteNum: 3,
      blackNum: 0,
    };
    const { testInput } = await buildTestInput(testCase, poseidon);
    try {
      await circuit.calculateWitness(testInput, true);
      assert(false, "Input must be rejected by the circuit!");
    } catch (err) {
      assert(true, "Input rejected!");
    }
  });
});
