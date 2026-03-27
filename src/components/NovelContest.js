import React, { useState } from "react";

function NovelContest({ account }) {
  const [title, setTitle] = useState("");
  const [summary, setSummary] = useState("");
  const [novels, setNovels] = useState([]);

  const submitNovel = async () => {
    if (!account) {
      alert("Please connect wallet first.");
      return;
    }

    if (!title || !summary) {
      alert("Please complete the form.");
      return;
    }

    const newNovel = {
      id: novels.length + 1,
      title,
      summary,
      author: account,
      votes: 0,
    };

    setNovels([...novels, newNovel]);
    setTitle("");
    setSummary("");
  };

  const voteNovel = (id) => {
    const updated = novels.map((novel) =>
      novel.id === id ? { ...novel, votes: novel.votes + 1 } : novel
    );
    setNovels(updated);
  };

  return (
    <div className="card">
      <h2 className="section-title">Novel Contest</h2>

      <div className="card">
        <h3>Submit Your Novel</h3>
        <label>Title</label>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Novel title"
        />

        <label>Summary</label>
        <textarea
          value={summary}
          onChange={(e) => setSummary(e.target.value)}
          placeholder="Short summary"
          rows="4"
        />

        <button className="primary-btn" onClick={submitNovel}>
          Submit Novel
        </button>
      </div>

      <div className="card">
        <h3>Submitted Novels</h3>
        {novels.length === 0 ? (
          <p>No submissions yet.</p>
        ) : (
          novels.map((novel) => (
            <div key={novel.id} className="card">
              <p><strong>Title:</strong> {novel.title}</p>
              <p><strong>Summary:</strong> {novel.summary}</p>
              <p><strong>Author:</strong> {novel.author}</p>
              <p><strong>Votes:</strong> {novel.votes}</p>
              <button className="secondary-btn" onClick={() => voteNovel(novel.id)}>
                Vote
              </button>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

export default NovelContest;
