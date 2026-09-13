-- Add the elevated platform role without changing existing USER/ADMIN assignments.
ALTER TYPE "UserRole" ADD VALUE IF NOT EXISTS 'SUPER_ADMIN';
