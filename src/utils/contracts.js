import { ethers } from "ethers";

import ContestManagerRaw from "../abi/ContestManager.json";
import MembershipRaw from "../abi/Membership.json";
import NovelTokenRaw from "../abi/NovelToken.json";
import RoleManagerRaw from "../abi/RoleManager.json";
import GovernorRaw from "../abi/Governor.json";

const normalizeABI = (raw) => {
  if (Array.isArray(raw)) return raw;
  if (raw && Array.isArray(raw.abi)) return raw.abi;
  throw new Error("Invalid ABI format");
};

export const ContestManagerABI = normalizeABI(ContestManagerRaw);
export const MembershipABI = normalizeABI(MembershipRaw);
export const NovelTokenABI = normalizeABI(NovelTokenRaw);
export const RoleManagerABI = normalizeABI(RoleManagerRaw);
export const GovernorABI = normalizeABI(GovernorRaw);

export const CONTRACT_ADDRESSES = {
  contestManager: process.env.REACT_APP_CONTEST_MANAGER_ADDRESS,
  membership: process.env.REACT_APP_MEMBERSHIP_ADDRESS,
  novelToken: process.env.REACT_APP_NOVEL_TOKEN_ADDRESS,
  roleManager: process.env.REACT_APP_ROLE_MANAGER_ADDRESS,
  governor: process.env.REACT_APP_GOVERNOR_ADDRESS,
};

export const getBrowserProvider = () => {
  if (!window.ethereum) {
    throw new Error("MetaMask not found");
  }
  return new ethers.BrowserProvider(window.ethereum);
};

export const getSigner = async () => {
  const provider = getBrowserProvider();
  return await provider.getSigner();
};

export const getGovernorWriteContract = async () => {
  const signer = await getSigner();

  console.log("Governor ABI is array:", Array.isArray(GovernorABI));
  console.log(
    "Governor propose fragment:",
    GovernorABI.find((x) => x.type === "function" && x.name === "propose")
  );
  console.log("Governor address:", CONTRACT_ADDRESSES.governor);

  const contract = new ethers.Contract(
    CONTRACT_ADDRESSES.governor,
    GovernorABI,
    signer
  );

  console.log("Governor contract propose:", contract.propose);

  return contract;
};

export const getGovernorReadContract = async () => {
  const provider = getBrowserProvider();

  return new ethers.Contract(
    CONTRACT_ADDRESSES.governor,
    GovernorABI,
    provider
  );
};
