class Program {
  final int id;
  final String name;
  final String sponsor;
  final String description;
  final double requiredMinBalance;
  final int requiredMinPrs;
  final String reward;
  final String category;

  const Program({
    required this.id,
    required this.name,
    required this.sponsor,
    required this.description,
    required this.requiredMinBalance,
    required this.requiredMinPrs,
    required this.reward,
    this.category = 'Grants',
  });
}

// Hardcoded for MVP. In production, this would be fetched from the VeilRegistry smart contract.
const List<Program> availablePrograms = [
  Program(
    id: 10,
    name: "Starter Grant",
    sponsor: "BlocSoc WEC NITK",
    description: "For NITK students starting in Web3. Prove you have merged >= 3 PRs.",
    requiredMinBalance: 0.0,
    requiredMinPrs: 3,
    reward: "\$15 USDC",
    category: "Grants",
  ),

  Program(
    id: 2,
    name: "DeFi Early Adopter",
    sponsor: "Aave",
    description: "Exclusive access to Aave v4 beta for active DeFi users. Balance > \$10,000.",
    requiredMinBalance: 10000.0,
    requiredMinPrs: 0,
    reward: "Exclusive NFT",
    category: "Cashback",
  ),
  Program(
    id: 3,
    name: "USDC Tester Grant",
    sponsor: "Veil Network",
    description: "Testnet USDC payout for zero-knowledge verifications. Prove you have merged >= 3 PRs.",
    requiredMinBalance: 0.0,
    requiredMinPrs: 3,
    reward: "1 USDC",
    category: "Grants",
  ),
  Program(
    id: 4,
    name: "ARC Testnet Grant",
    sponsor: "Arc Network",
    description: "Native ARC Testnet payout for open-source devs. Prove you have merged >= 3 PRs.",
    requiredMinBalance: 0.0,
    requiredMinPrs: 3,
    reward: "1 ARC",
    category: "Grants",
  ),
  Program(
    id: 5,
    name: "ETH Hacker Grant",
    sponsor: "Ethereum Foundation",
    description: "Sepolia ETH payout for early beta testers. Prove you have merged >= 5 PRs.",
    requiredMinBalance: 0.0,
    requiredMinPrs: 5,
    reward: "0.001 ETH",
    category: "Grants",
  ),
  Program(
    id: 6,
    name: "USDC Power User",
    sponsor: "Circle",
    description: "Testnet USDC payout for active contributors. Prove you have merged >= 10 PRs.",
    requiredMinBalance: 0.0,
    requiredMinPrs: 10,
    reward: "2 USDC",
    category: "Refunds",
  ),
];
