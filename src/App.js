import React, { useState } from "react";
import "./App.css";

import Overview from "./components/Overview";
import MemberCenter from "./components/MemberCenter";
import Governance from "./components/Governance";
import NovelContest from "./components/NovelContest";
import TreasuryPanel from "./components/TreasuryPanel";

function App() {
  const [tab, setTab] = useState("overview");
  const [account, setAccount] = useState("");

  const renderPage = () => {
    switch (tab) {
      case "overview":
        return <Overview />;
      case "member":
        return <MemberCenter account={account} setAccount={setAccount} />;
      case "governance":
        return <Governance account={account} />;
      case "contest":
        return <NovelContest account={account} />;
      case "treasury":
        return <TreasuryPanel />;
      default:
        return <Overview />;
    }
  };

  return (
    <div className="app">
      <h1 className="title">Novel DAO</h1>

      <div className="tabs">
        <button onClick={() => setTab("overview")}>Overview</button>
        <button onClick={() => setTab("member")}>Member</button>
        <button onClick={() => setTab("governance")}>Governance</button>
        <button onClick={() => setTab("contest")}>Contest</button>
        <button onClick={() => setTab("treasury")}>Treasury</button>
      </div>

      <div className="content">{renderPage()}</div>
    </div>
  );
}

export default App;
