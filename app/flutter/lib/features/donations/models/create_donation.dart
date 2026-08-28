class CreateDonationAllocation {
  const CreateDonationAllocation({
    required this.causeId,
    required this.organisationId,
    required this.amount,
  });

  final String causeId;
  final String organisationId;
  final String amount;

  Map<String, dynamic> toJson() => {
        'causeId': causeId,
        'organisationId': organisationId,
        'amount': amount,
      };
}

class CreateDonation {
  const CreateDonation({
    required this.amount,
    required this.causeId,
    required this.organisationId,
  });

  final String amount;
  final String causeId;
  final String organisationId;

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'currency': 'INR',
        'allocations': [
          CreateDonationAllocation(
            causeId: causeId,
            organisationId: organisationId,
            amount: amount,
          ).toJson(),
        ],
      };
}
