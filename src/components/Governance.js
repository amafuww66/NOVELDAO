import React, { useState } from "react";
import { ethers } from "ethers";
import {
  getGovernorWriteContract,
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

      const targets = [CONTRACT_ADDRESSES.contestManager];
      const values = [0];
      const calldatas = [calldata];

      setStatus("Waiting for wallet confirmation...");

      const tx = await governor.propose(
        targets,
        values,
        calldatas,
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
      {txHash && (
        <p style={{ wordBreak: "break-all" }}>
          Tx Hash: {txHash}
        </p>
      )}
    </div>
  );
}

export default Governance;
