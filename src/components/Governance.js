import React, { useEffect, useState } from "react";
import { ethers } from "ethers";
import {
  getGovernorWriteContract,
  getGovernorReadContract,
  ContestManagerABI,
  CONTRACT_ADDRESSES,
} from "../utils/contracts";

function Governance({ account }) {
  const [proposalType, setProposalType] = useState("createContest");
  const [contestName, setContestName] = useState("");
  const [deadlineInput, setDeadlineInput] = useState("");
  const [contestId, setContestId] = useState("");
  const [description, setDescription] = useState("");

  const [status, setStatus] = useState("");
  const [txHash, setTxHash] = useState("");
  const [loading, setLoading] = useState(false);

  const [proposals, setProposals] = useState([]);

  const loadProposals = async () => {
    try {
      const governor = await getGovernorReadContract();
      const total = Number(await governor.proposalCount());
      const loaded = [];

      for (let i = total - 1; i >= 0; i--) {
        const p = await governor.proposals(i);
        const executable = await governor.canExecute(i);

        loaded.push({
          id: i,
          proposer: p.proposer,
          target: p.target,
          description: p.description,
          deadline: Number(p.deadline),
          yesVotes: p.yesVotes.toString(),
          noVotes: p.noVotes.toString(),
          executed: p.executed,
          canExecute: executable,
        });
      }

      setProposals(loaded);
    } catch (error) {
      console.error("Failed to load proposals:", error);
    }
  };

  useEffect(() => {
    loadProposals();
  }, []);

  const createProposal = async () => {
    if (!account) {
      alert("Connect wallet first");
      return;
    }

    try {
      setLoading(true);
      setStatus("Preparing proposal...");
      setTxHash("");

      const governor = await getGovernorWriteContract();
      const contestInterface = new ethers.Interface(ContestManagerABI);

      let calldata = "0x";
      let finalDescription = description.trim();

      if (proposalType === "createContest") {
        if (!contestName.trim()) {
          alert("Please enter contest name");
          setLoading(false);
          return;
        }

        if (!deadlineInput) {
          alert("Please select a deadline");
          setLoading(false);
          return;
        }

        const deadline = Math.floor(new Date(deadlineInput).getTime() / 1000);

        if (!deadline || deadline <= Math.floor(Date.now() / 1000)) {
          alert("Deadline must be in the future");
          setLoading(false);
          return;
        }

        calldata = contestInterface.encodeFunctionData("createContest", [
          contestName.trim(),
          deadline,
        ]);

        if (!finalDescription) {
          finalDescription = `Proposal: Create contest "${contestName.trim()}"`;
        }
      } else if (proposalType === "endVoting") {
        if (contestId === "" || isNaN(contestId)) {
          alert("Please enter a valid contest ID");
          setLoading(false);
          return;
        }

        calldata = contestInterface.encodeFunctionData("endVoting", [
          Number(contestId),
        ]);

        if (!finalDescription) {
          finalDescription = `Proposal: End voting for contest #${contestId}`;
        }
      } else if (proposalType === "finalizeWinner") {
        if (contestId === "" || isNaN(contestId)) {
          alert("Please enter a valid contest ID");
          setLoading(false);
          return;
        }

        calldata = contestInterface.encodeFunctionData("finalizeWinner", [
          Number(contestId),
        ]);

        if (!finalDescription) {
          finalDescription = `Proposal: Finalize winners for contest #${contestId}`;
        }
      } else {
        alert("Unknown proposal type");
        setLoading(false);
        return;
      }

      setStatus("Waiting for wallet confirmation...");

      const tx = await governor.propose(
        CONTRACT_ADDRESSES.contestManager,
        0,
        calldata,
        finalDescription
      );

      setTxHash(tx.hash);
      setStatus("Transaction submitted. Waiting for confirmation...");

      await tx.wait();

      setStatus("Proposal created successfully!");
      setContestName("");
      setDeadlineInput("");
      setContestId("");
      setDescription("");

      await loadProposals();
    } catch (error) {
      console.error("Create proposal failed:", error);

      if (error?.reason) {
        setStatus(`Failed: ${error.reason}`);
      } else if (error?.shortMessage) {
        setStatus(`Failed: ${error.shortMessage}`);
      } else if (error?.message) {
        setStatus(`Failed: ${error.message}`);
      } else {
        setStatus("Failed to create proposal");
      }
    } finally {
      setLoading(false);
    }
  };

  const voteProposal = async (proposalId, support) => {
    if (!account) {
      alert("Connect wallet first");
      return;
    }

    try {
      setLoading(true);
      setStatus("Waiting for vote confirmation...");
      const governor = await getGovernorWriteContract();

      const tx = await governor.vote(proposalId, support);
      setTxHash(tx.hash);

      await tx.wait();

      setStatus(`Vote submitted successfully!`);
      await loadProposals();
    } catch (error) {
      console.error("Vote failed:", error);

      if (error?.reason) {
        setStatus(`Vote failed: ${error.reason}`);
      } else if (error?.shortMessage) {
        setStatus(`Vote failed: ${error.shortMessage}`);
      } else if (error?.message) {
        setStatus(`Vote failed: ${error.message}`);
      } else {
        setStatus("Vote failed");
      }
    } finally {
      setLoading(false);
    }
  };

  const executeProposal = async (proposalId) => {
    if (!account) {
      alert("Connect wallet first");
      return;
    }

    try {
      setLoading(true);
      setStatus("Waiting for execution confirmation...");
      const governor = await getGovernorWriteContract();

      const tx = await governor.execute(proposalId);
      setTxHash(tx.hash);

      await tx.wait();

      setStatus(`Proposal executed successfully!`);
      await loadProposals();
    } catch (error) {
      console.error("Execution failed:", error);

      if (error?.reason) {
        setStatus(`Execution failed: ${error.reason}`);
      } else if (error?.shortMessage) {
        setStatus(`Execution failed: ${error.shortMessage}`);
      } else if (error?.message) {
        setStatus(`Execution failed: ${error.message}`);
      } else {
        setStatus("Execution failed");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="card">
      <h2>Governance</h2>

      <label>Proposal Type</label>
      <select
        value={proposalType}
        onChange={(e) => setProposalType(e.target.value)}
      >
        <option value="createContest">Create Contest</option>
        <option value="endVoting">End Voting</option>
        <option value="finalizeWinner">Finalize Winner</option>
      </select>

      {proposalType === "createContest" && (
        <>
          <label>Contest Name</label>
          <input
            value={contestName}
            onChange={(e) => setContestName(e.target.value)}
            placeholder="Enter contest name"
          />

          <label>Deadline</label>
          <input
            type="datetime-local"
            value={deadlineInput}
            onChange={(e) => setDeadlineInput(e.target.value)}
          />
        </>
      )}

      {(proposalType === "endVoting" ||
        proposalType === "finalizeWinner") && (
        <>
          <label>Contest ID</label>
          <input
            value={contestId}
            onChange={(e) => setContestId(e.target.value)}
            placeholder="Enter contest ID"
          />
        </>
      )}

      <label>Description (optional)</label>
      <input
        value={description}
        onChange={(e) => setDescription(e.target.value)}
        placeholder="Enter proposal description"
      />

      <button onClick={createProposal} disabled={loading}>
        {loading ? "Processing..." : "Create Proposal"}
      </button>

      {status && <p>Status: {status}</p>}
      {txHash && <p style={{ wordBreak: "break-all" }}>Tx Hash: {txHash}</p>}

      <hr style={{ margin: "24px 0" }} />

      <h3>On-Chain Proposals</h3>

      {proposals.length === 0 ? (
        <p>No proposals found.</p>
      ) : (
        proposals.map((p) => (
          <div
            key={p.id}
            style={{
              border: "1px solid #ddd",
              borderRadius: "10px",
              padding: "12px",
              marginBottom: "12px",
              textAlign: "left",
            }}
          >
            <p><strong>ID:</strong> {p.id}</p>
            <p><strong>Description:</strong> {p.description}</p>
            <p><strong>Proposer:</strong> {p.proposer}</p>
            <p><strong>Yes Votes:</strong> {p.yesVotes}</p>
            <p><strong>No Votes:</strong> {p.noVotes}</p>
            <p><strong>Deadline:</strong> {new Date(p.deadline * 1000).toLocaleString()}</p>
            <p><strong>Executed:</strong> {p.executed ? "Yes" : "No"}</p>

            {!p.executed && (
              <div style={{ display: "flex", gap: "10px", flexWrap: "wrap" }}>
                <button onClick={() => voteProposal(p.id, true)} disabled={loading}>
                  Vote Yes
                </button>
                <button onClick={() => voteProposal(p.id, false)} disabled={loading}>
                  Vote No
                </button>
                {p.canExecute && (
                  <button onClick={() => executeProposal(p.id)} disabled={loading}>
                    Execute
                  </button>
                )}
              </div>
            )}
          </div>
        ))
      )}
    </div>
  );
}

export default Governance;
