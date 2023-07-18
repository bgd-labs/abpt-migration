import Decimal from "decimal.js";
import { encodeAbiParameters } from "viem";

const ether = "1000000000000000000";

function createMatrix(weights, steps) {
  let matrix = [];
  for (let i = 1; i <= steps; i++) {
    matrix.push([
      new Decimal(10).pow(i).times(ether).toFixed(0),
      new Decimal(10).pow(i).pow(weights[0]).times(ether).toFixed(0),
      new Decimal(10).pow(i).pow(weights[1]).times(ether).toFixed(0),
    ]);
  }
  return matrix;
}

function weightsToK(weights) {
  const factor1 = new Decimal(weights[0]).pow(weights[0]);
  const factor2 = new Decimal(weights[1]).pow(weights[1]);
  const divisor = factor1.mul(factor2);
  const k = new Decimal(ether).div(divisor).toFixed(0);
  return k;
}

export function getEncodedParams(weights) {
  const result = encodeAbiParameters(
    [{ type: "uint256[][]" }, { type: "uint256" }],
    [createMatrix(weights, 20), weightsToK(weights)]
  );
  return result;
}
