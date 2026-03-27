import React, { useState } from "react";
import "./App.css";

import ConnectWallet from "./components/ConnectWallet";
import DAOStatus from "./components/DAOStatus";
import ProposalList from "./components/ProposalList";
import NovelContest from "./components/NovelContest";
import TreasuryPanel from "./components/TreasuryPanel";

function App() {
  const [activeTab, setActiveTab] = useState("overview");
  const [account, setAccount] = useState("");

  const renderTab = () => {
    switch (activeTab) {
      case "overview":
        return <DAOStatus account={account} />;
      case "wallet":
        return <ConnectWallet account={account} setAccount={setAccount} />;
      case "governance":
        return <ProposalList account={account} />;
      case "contest":
        return <NovelContest account={account} />;
      case "treasury":
        return <TreasuryPanel account={account} />;
      default:
        return <DAOStatus account={account} />;
    }
  };

  return (
    <div className="app">
      <header className="app-header">
        <h1>Novel DAO Dashboard</h1>
        <p>Minimum Deliverable Interactive Front-End</p>
      </header>

      <nav className="tab-bar">
        <button onClick={() => setActiveTab("overview")}>Overview</button>
        <button onClick={() => setActiveTab("wallet")}>Member Center</button>
        <button onClick={() => setActiveTab("governance")}>Governance</button>
        <button onClick={() => setActiveTab("contest")}>Novel Contest</button>
        <button onClick={() => setActiveTab("treasury")}>Treasury</button>
      </nav>

      <main className="main-content">{renderTab()}</main>
    </div>
  );
}

export default App;
