pragma circom 2.0.0;

// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

// Number Mastermind
/// Colors = 6 numbers
/// Holes = 4 numbers
/// Uses numbers instead of colors. The codemaker may optionally give, as an extra clue, the sum of the digits.
template MastermindVariation() {
    // Public inputs
    signal input pubGuessA;
    signal input pubGuessB;
    signal input pubGuessC;
    signal input pubGuessD;

    // Number exists, but it's not in the right place
    signal input pubNumBlack;
    // Number exists, AND it's in the right place!
    signal input pubNumWhite;
    signal input pubSolnHash;
    // Extra clue: sum of the digits.
    signal input extraClue;

    // Private inputs
    signal input privSolnA;
    signal input privSolnB;
    signal input privSolnC;
    signal input privSolnD;
    signal input privSalt;

    // Output
    signal output solnHashOut;

    var guess[4] =[pubGuessA, pubGuessB, pubGuessC, pubGuessD];
    var soln[4] =[privSolnA, privSolnB, privSolnC, privSolnD];
    var j = 0;
    var k = 0;
    component lessThan[8];
    component equalGuess[6];
    component equalSoln[6];
    var equalIdx = 0;

    // Create a constraint that the solution and guess digits are all less than 10.
    for (j = 0; j < 4; j++) {
        lessThan[j] = LessThan(4);
        lessThan[j].in[0] <== guess[j];
        lessThan[j].in[1] <== 10;
        lessThan[j].out === 1;
        lessThan[j + 4] = LessThan(4);
        lessThan[j + 4].in[0] <== soln[j];
        lessThan[j + 4].in[1] <== 10;
        lessThan[j + 4].out === 1;
        for (k = j + 1; k < 4; k++) {
            // Create a constraint that the solution and guess digits are unique. no duplication.
            equalGuess[equalIdx] = IsEqual();
            equalGuess[equalIdx].in[0] <== guess[j];
            equalGuess[equalIdx].in[1] <== guess[k];
            equalGuess[equalIdx].out === 0;
            equalSoln[equalIdx] = IsEqual();
            equalSoln[equalIdx].in[0] <== soln[j];
            equalSoln[equalIdx].in[1] <== soln[k];
            equalSoln[equalIdx].out === 0;
            equalIdx += 1;
        }
    }

    // Create a constraint that the solution and the guess digits  sum are equal to public sum.
    signal guessSum;
    guessSum <== guess[0] + guess[1] + guess[2] + guess[3];
    guessSum === extraClue;

    signal solnSum;
    solnSum <== soln[0] + soln[1] + soln[2] + soln[3];
    solnSum === extraClue;

    // Count black & white
    var whitePegs = 0;
    var blackPegs = 0;
    component equalHB[16];

    for (j = 0; j < 4; j++) {
        for (k = 0; k < 4; k++) {
            equalHB[4 * j + k] = IsEqual();
            equalHB[4 * j + k].in[0] <== soln[j];
            equalHB[4 * j + k].in[1] <== guess[k];
            blackPegs += equalHB[4 * j + k].out;
            if (j == k) {
                whitePegs += equalHB[4 * j + k].out;
                blackPegs -= equalHB[4 * j + k].out;
            }
        }
    }

    // Create a constraint around the number of whitePegs
    component equalHit = IsEqual();
    equalHit.in[0] <== pubNumBlack;
    equalHit.in[1] <== whitePegs;
    equalHit.out === 1;

    // Create a constraint around the number of blackPegs
    component equalBlow = IsEqual();
    equalBlow.in[0] <== pubNumWhite;
    equalBlow.in[1] <== blackPegs;
    equalBlow.out === 1;

    // Verify that the hash of the private solution matches pubSolnHash
    component poseidon = Poseidon(5);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== privSolnA;
    poseidon.inputs[2] <== privSolnB;
    poseidon.inputs[3] <== privSolnC;
    poseidon.inputs[4] <== privSolnD;

    solnHashOut <== poseidon.out;
    pubSolnHash === solnHashOut;
}

component main { public[pubGuessA, pubGuessB, pubGuessC, pubGuessD, pubNumBlack, pubNumWhite, pubSolnHash, extraClue] } = MastermindVariation();