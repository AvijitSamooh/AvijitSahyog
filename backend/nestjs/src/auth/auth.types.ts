export interface FirebaseIdentity {
  uid: string;
  email?: string;
  displayName?: string;
  photoUrl?: string;
}

export interface AuthenticatedRequest {
  user: FirebaseIdentity;
}
