import React, { useState } from "react";
import { ethers } from "ethers";

function MemberCenter({ account, setAccount }) {
  const [status, setStatus] = useState("Not connected");

  const connectWallet = async () => {
    try {
      if (!window.ethereum) {
        setStatus("MetaMask not found");
        return;
      }

      const accounts = await window.ethereum.request({
        method: "eth_requestAccounts",
      });

      setAccount(accounts[0]);
      setStatus("Connected");
    } catch (err) {
      console.error(err);
      setStatus("Connection failed");
    }
  };

  return (
    <div className="card">
      <h2>Member Center</h2>

      <button onClick={connectWallet}>Connect Wallet</button>

      <p>Status: {status}</p>
      <p>Account: {account || "Not connected"}</p>
    </div>
  );
}

export default MemberCenter;
