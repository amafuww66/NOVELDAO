import React, { useEffect, useState } from "react";
import { ethers } from "ethers";

function ConnectWallet({ account, setAccount }) {
  const [chainId, setChainId] = useState("");
  const [walletStatus, setWalletStatus] = useState("Not connected");

  const connectWallet = async () => {
    try {
      if (!window.ethereum) {
        setWalletStatus("MetaMask not detected");
        return;
      }

      const accounts = await window.ethereum.request({
        method: "eth_requestAccounts",
      });

      const provider = new ethers.BrowserProvider(window.ethereum);
      const network = await provider.getNetwork();

      setAccount(accounts[0]);
      setChainId(network.chainId.toString());
      setWalletStatus("Wallet connected");
    } catch (error) {
      console.error(error);
      setWalletStatus("Connection failed");
    }
  };

  useEffect(() => {
    if (!window.ethereum) return;

    const handleAccountsChanged = (accounts) => {
      setAccount(accounts.length > 0 ? accounts[0] : "");
    };

    const handleChainChanged = () => {
      window.location.reload();
    };

    window.ethereum.on("accountsChanged", handleAccountsChanged);
    window.ethereum.on("chainChanged", handleChainChanged);

    return () => {
      if (window.ethereum.removeListener) {
        window.ethereum.removeListener("accountsChanged", handleAccountsChanged);
        window.ethereum.removeListener("chainChanged", handleChainChanged);
      }
    };
  }, [setAccount]);

  return (
    <div className="card">
      <h2 className="section-title">Member Center</h2>
      <p className="status-text">{walletStatus}</p>

      <button className="primary-btn" onClick={connectWallet}>
        Connect MetaMask
      </button>

      <div style={{ marginTop: "16px" }}>
        <p><strong>Account:</strong> {account || "Not connected"}</p>
        <p><strong>Chain ID:</strong> {chainId || "Unknown"}</p>
      </div>
    </div>
  );
}

export default ConnectWallet;
