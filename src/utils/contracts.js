import { ethers } from "ethers";

import ContestManagerABI from "../abi/ContestManager.json";
import MembershipABI from "../abi/Membership.json";
import NovelTokenABI from "../abi/NovelToken.json";
import RoleManagerABI from "../abi/RoleManager.json";
import GovernorABI from "../abi/Governor.json";

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
  return new ethers.Contract(
    CONTRACT_ADDRESSES.governor,
    GovernorABI,
    signer
  );
};

export const getGovernorReadContract = async () => {
  const provider = getBrowserProvider();
  return new ethers.Contract(
    CONTRACT_ADDRESSES.governor,
    GovernorABI,
    provider
  );
};

export {
  ContestManagerABI,
  MembershipABI,
  NovelTokenABI,
  RoleManagerABI,
  GovernorABI,
};
