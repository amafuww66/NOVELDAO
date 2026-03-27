import React, { useState } from "react";

function NovelContest({ account }) {
  const [title, setTitle] = useState("");
  const [novels, setNovels] = useState([]);

  const submit = () => {
    if (!account) {
      alert("Connect wallet first");
      return;
    }

    const newNovel = {
      id: novels.length + 1,
      title,
      votes: 0,
    };

    setNovels([...novels, newNovel]);
    setTitle("");
  };

  const vote = (id) => {
    const updated = novels.map((n) =>
      n.id === id ? { ...n, votes: n.votes + 1 } : n
    );
    setNovels(updated);
  };

  return (
    <div className="card">
      <h2>Novel Contest</h2>

      <input
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        placeholder="Novel title"
      />

      <button onClick={submit}>Submit</button>

      {novels.map((n) => (
        <div key={n.id} className="card">
          <p>{n.title}</p>
          <p>Votes: {n.votes}</p>
          <button onClick={() => vote(n.id)}>Vote</button>
        </div>
      ))}
    </div>
  );
}

export default NovelContest;
