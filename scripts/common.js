import Decimal from "decimal.js";
import { encodeAbiParameters } from "viem";

const ether = "1000000000000000000";

function weightsToK(weights) {
  const factor1 = new Decimal(weights[0]).pow(weights[0]);
  const factor2 = new Decimal(weights[1]).pow(weights[1]);
  const divisor = factor1.mul(factor2);
  const k = new Decimal(ether).div(divisor).toFixed(0);
  if (process.env.VERBOSE) console.log(k);
  return k;
}

export function getEncodedParams(weights) {
  const result = encodeAbiParameters(
    [{ type: "uint256" }],
    [weightsToK(weights)]
  );
  return result;
}
