import React, { useState } from "react";

function ProposalList({ account }) {
  const [proposalTitle, setProposalTitle] = useState("");
  const [proposalDesc, setProposalDesc] = useState("");
  const [proposals, setProposals] = useState([]);

  const createProposal = async () => {
    if (!account) {
      alert("Please connect wallet first.");
      return;
    }

    try {
      const newProposal = {
        id: proposals.length + 1,
        title: proposalTitle,
        description: proposalDesc,
        status: "Pending",
      };

      setProposals([...proposals, newProposal]);
      setProposalTitle("");
      setProposalDesc("");
    } catch (error) {
      console.error("Create proposal failed:", error);
    }
  };

  return (
    <div className="card">
      <h2 className="section-title">Governance</h2>

      <div className="card">
        <h3>Create Proposal</h3>
        <label>Proposal Title</label>
        <input
          value={proposalTitle}
          onChange={(e) => setProposalTitle(e.target.value)}
          placeholder="Enter proposal title"
        />

        <label>Proposal Description</label>
        <textarea
          value={proposalDesc}
          onChange={(e) => setProposalDesc(e.target.value)}
          placeholder="Enter proposal description"
          rows="4"
        />

        <button className="primary-btn" onClick={createProposal}>
          Create Proposal
        </button>
      </div>

      <div className="card">
        <h3>Proposal List</h3>
        {proposals.length === 0 ? (
          <p>No proposals yet.</p>
        ) : (
          proposals.map((proposal) => (
            <div key={proposal.id} className="card">
              <p><strong>ID:</strong> {proposal.id}</p>
              <p><strong>Title:</strong> {proposal.title}</p>
              <p><strong>Description:</strong> {proposal.description}</p>
              <p><strong>Status:</strong> {proposal.status}</p>
              <button className="secondary-btn">Vote For</button>
              <button className="secondary-btn" style={{ marginLeft: "10px" }}>
                Vote Against
              </button>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

export default ProposalList;
