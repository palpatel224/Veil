class Program {
  final int id;
  final String name;
  final String sponsor;
  final String description;
  final double requiredMinBalance;
  final int requiredMinPrs;
  final String reward;

  const Program({
    required this.id,
    required this.name,
    required this.sponsor,
    required this.description,
    required this.requiredMinBalance,
    required this.requiredMinPrs,
    required this.reward,
  });
}

// Hardcoded for MVP. In production, this would be fetched from the VeilRegistry smart contract.
const List<Program> availablePrograms = [
  Program(
    id: 0,
    name: "Starter Grant",
    sponsor: "BlocSoc WEC NITK",
    description: "For NITK students starting in Web3. Prove you have merged >= 3 PRs.",
    requiredMinBalance: 0.0,
    requiredMinPrs: 3,
    reward: "\$10 USDC",
  ),
  Program(
    id: 1,
    name: "Open Source Champion",
    sponsor: "Gitcoin",
    description: "Reward for major open source contributors. Merged >= 20 PRs.",
    requiredMinBalance: 0.0,
    requiredMinPrs: 20,
    reward: "\$200 USDC",
  ),
  Program(
    id: 2,
    name: "DeFi Early Adopter",
    sponsor: "Aave",
    description: "Exclusive access to Aave v4 beta for active DeFi users. Balance > \$10,000.",
    requiredMinBalance: 10000.0,
    requiredMinPrs: 0,
    reward: "Exclusive NFT",
  ),
  Program(
    id: 3,
    name: "USDC Tester Grant",
    sponsor: "Veil Network",
    description: "Testnet USDC payout for zero-knowledge verifications. Prove you have merged >= 3 PRs.",
    requiredMinBalance: 0.0,
    requiredMinPrs: 3,
    reward: "1 USDC",
  ),
];
