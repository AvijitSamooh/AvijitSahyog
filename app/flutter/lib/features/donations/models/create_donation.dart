class CreateDonationAllocation {
  const CreateDonationAllocation({
    required this.causeId,
    required this.amount,
  });

  final String causeId;
  final String amount;

  Map<String, dynamic> toJson() => {
        'causeId': causeId,
        'amount': amount,
      };
}

class CreateDonation {
  const CreateDonation({
    required this.amount,
    required this.allocations,
  });

  final String amount;
  final List<CreateDonationAllocation> allocations;

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'currency': 'INR',
        'allocations': allocations.map((allocation) => allocation.toJson()).toList(),
      };
}
