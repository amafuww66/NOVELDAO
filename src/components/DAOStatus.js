import React, { useEffect, useState } from "react";

function DAOStatus() {
  const [daoStats, setDaoStats] = useState({
    totalSupply: "-",
    treasuryBalance: "-",
    quorum: "-",
    votingPeriod: "-",
    currentRound: "-",
    contestStatus: "-",
  });

  useEffect(() => {
    const loadData = async () => {
      try {
        setDaoStats({
          totalSupply: "To be loaded from contract",
          treasuryBalance: "To be loaded from contract",
          quorum: "To be loaded from contract",
          votingPeriod: "To be loaded from contract",
          currentRound: "To be loaded from contract",
          contestStatus: "To be loaded from contract",
        });
      } catch (error) {
        console.error("Failed to load DAO status:", error);
      }
    };

    loadData();
  }, []);

  return (
    <div className="card">
      <h2 className="section-title">Overview</h2>
      <div className="grid-2">
        <div><strong>Total Token Supply:</strong> {daoStats.totalSupply}</div>
        <div><strong>Treasury Balance:</strong> {daoStats.treasuryBalance}</div>
        <div><strong>Quorum:</strong> {daoStats.quorum}</div>
        <div><strong>Voting Period:</strong> {daoStats.votingPeriod}</div>
        <div><strong>Current Contest Round:</strong> {daoStats.currentRound}</div>
        <div><strong>Contest Status:</strong> {daoStats.contestStatus}</div>
      </div>
    </div>
  );
}

export default DAOStatus;
