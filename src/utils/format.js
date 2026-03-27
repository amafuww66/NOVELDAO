export const shortenAddress = (address) => {
  if (!address) return "";
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
};

export const safeDisplay = (value) => {
  if (value === null || value === undefined || value === "") return "-";
  return value;
};
