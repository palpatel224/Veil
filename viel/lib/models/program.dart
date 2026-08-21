class Program {
  final int id;
  final String name;
  final String description;
  final double requiredMinBalance;
  final int requiredMinPrs;

  const Program({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredMinBalance,
    required this.requiredMinPrs,
  });
}

// Hardcoded for MVP. In production, this would be fetched from the VeilRegistry smart contract.
const List<Program> availablePrograms = [
  Program(
    id: 0,
    name: "Web3 Builder Grant",
    description: "Requires > 0.01 ETH & 1+ PRs",
    requiredMinBalance: 0.01,
    requiredMinPrs: 1,
  ),
  Program(
    id: 1,
    name: "Open Source Contributor",
    description: "Requires 10+ PRs",
    requiredMinBalance: 0.0,
    requiredMinPrs: 10,
  ),
  Program(
    id: 2,
    name: "DeFi Power User",
    description: "Requires > 0.1 ETH",
    requiredMinBalance: 0.1,
    requiredMinPrs: 0,
  ),
];
