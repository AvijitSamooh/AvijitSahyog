export interface CreateDonationAllocationDto {
  causeId: string;
  amount: string;
}

export interface CreateDonationDto {
  amount: string;
  currency?: string;
  allocations: CreateDonationAllocationDto[];
}
