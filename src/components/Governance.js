import React, { useState } from "react";

function Governance({ account }) {
  const [title, setTitle] = useState("");
  const [proposals, setProposals] = useState([]);

  const createProposal = () => {
    if (!account) {
      alert("Connect wallet first");
      return;
    }

    const newProposal = {
      id: proposals.length + 1,
      title,
      votes: 0,
    };

    setProposals([...proposals, newProposal]);
    setTitle("");
  };

  const vote = (id) => {
    const updated = proposals.map((p) =>
      p.id === id ? { ...p, votes: p.votes + 1 } : p
    );
    setProposals(updated);
  };

  return (
    <div className="card">
      <h2>Governance</h2>

      <input
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        placeholder="Proposal title"
      />

      <button onClick={createProposal}>Create</button>

      {proposals.map((p) => (
        <div key={p.id} className="card">
          <p>{p.title}</p>
          <p>Votes: {p.votes}</p>
          <button onClick={() => vote(p.id)}>Vote</button>
        </div>
      ))}
    </div>
  );
}

export default Governance;
