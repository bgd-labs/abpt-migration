const Big = require("bignumber.js");
const Decimal = require("decimal.js");
const { encodeAbiParameters } = require("viem");

function* createWeightMatrix(base, end, step, weights) {
  for (let i = base; i <= end; i += step) {
    yield [i, ...weights.map((w) => Math.pow(base, w))];
  }
}

function* createWeightMatrixLog(base, count, logStep, weights) {
  let currentBase = base;
  for (let i = 0; i < count; i++) {
    yield [
      new Big(currentBase).times(new Big(10).pow(18)).toFixed(0),
      ...weights.map((w) =>
        new Big(Math.pow(currentBase, w) * 10 ** 18).toFixed(0)
      ),
    ];
    currentBase = currentBase * Math.pow(base, logStep);
  }
}

function toList(gen) {
  let l = [];
  for (let x of gen) {
    l.push(x);
  }
  return l;
}

const weights = [0.2, 0.8];
const ether = "1000000000000000000";

function weightsToK(weights) {
  const factor1 = new Decimal(weights[0]).pow(weights[0]);
  const factor2 = new Decimal(weights[1]).pow(weights[1]);
  const divisor = factor1.mul(factor2);
  const k = new Decimal(ether).div(divisor).toFixed(0);
  return k;
}

const result = encodeAbiParameters(
  [{ type: "uint256[][]" }, { type: "uint256" }],
  [toList(createWeightMatrixLog(1, 29, 1, weights)), weightsToK(weights)]
);

console.log(result);
