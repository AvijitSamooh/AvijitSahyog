export interface CreateDonationDto {
  amount: string;
  currency?: string;
  causeId: string;
}
