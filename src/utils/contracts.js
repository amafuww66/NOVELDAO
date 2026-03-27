import { ethers } from "ethers";

import NovelTokenABI from "../abi/NovelToken.json";
import MembershipABI from "../abi/Membership.json";
import RoleManagerABI from "../abi/RoleManager.json";
import ContestManagerABI from "../abi/ContestManager.json";
import TreasuryABI from "../abi/Treasury.json";
import GovernorABI from "../abi/SimpleGovernor.json";

export const CONTRACT_ADDRESSES = {
  novelToken: process.env.REACT_APP_NOVEL_TOKEN_ADDRESS,
  membership: process.env.REACT_APP_MEMBERSHIP_ADDRESS,
  roleManager: process.env.REACT_APP_ROLE_MANAGER_ADDRESS,
  contestManager: process.env.REACT_APP_CONTEST_MANAGER_ADDRESS,
  treasury: process.env.REACT_APP_TREASURY_ADDRESS,
  governor: process.env.REACT_APP_GOVERNOR_ADDRESS,
};

export const getProvider = () => {
  if (!window.ethereum) throw new Error("MetaMask not found");
  return new ethers.BrowserProvider(window.ethereum);
};

export const getSigner = async () => {
  const provider = getProvider();
  return await provider.getSigner();
};

export const getReadContract = async (name, abi) => {
  const provider = getProvider();
  return new ethers.Contract(CONTRACT_ADDRESSES[name], abi, provider);
};

export const getWriteContract = async (name, abi) => {
  const signer = await getSigner();
  return new ethers.Contract(CONTRACT_ADDRESSES[name], abi, signer);
};

export {
  NovelTokenABI,
  MembershipABI,
  RoleManagerABI,
  ContestManagerABI,
  TreasuryABI,
  GovernorABI,
};
