-- CreateTable
CREATE TABLE "Language" (
    "id" UUID NOT NULL,
    "code" VARCHAR(10) NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "nativeName" VARCHAR(100) NOT NULL,
    "isDefault" BOOLEAN NOT NULL DEFAULT false,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Language_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Cause" (
    "id" UUID NOT NULL,
    "slug" VARCHAR(100) NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "displayOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Cause_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CauseTranslation" (
    "id" UUID NOT NULL,
    "causeId" UUID NOT NULL,
    "languageId" UUID NOT NULL,
    "name" VARCHAR(200) NOT NULL,
    "description" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CauseTranslation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Organisation" (
    "id" UUID NOT NULL,
    "slug" VARCHAR(120) NOT NULL,
    "logoUrl" VARCHAR(1000),
    "websiteUrl" VARCHAR(1000),
    "phone" VARCHAR(30),
    "email" VARCHAR(320),
    "address" TEXT,
    "city" VARCHAR(100),
    "state" VARCHAR(100),
    "country" VARCHAR(2) NOT NULL DEFAULT 'IN',
    "latitude" DECIMAL(9,6),
    "longitude" DECIMAL(9,6),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "displayOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Organisation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OrganisationTranslation" (
    "id" UUID NOT NULL,
    "organisationId" UUID NOT NULL,
    "languageId" UUID NOT NULL,
    "name" VARCHAR(250) NOT NULL,
    "description" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OrganisationTranslation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OrganisationCause" (
    "id" TEXT NOT NULL,
    "organisationId" UUID NOT NULL,
    "causeId" UUID NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "displayOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OrganisationCause_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Language_code_key" ON "Language"("code");

-- CreateIndex
CREATE INDEX "Language_isActive_idx" ON "Language"("isActive");

-- CreateIndex
CREATE UNIQUE INDEX "Cause_slug_key" ON "Cause"("slug");

-- CreateIndex
CREATE INDEX "Cause_isActive_displayOrder_idx" ON "Cause"("isActive", "displayOrder");

-- CreateIndex
CREATE INDEX "CauseTranslation_languageId_idx" ON "CauseTranslation"("languageId");

-- CreateIndex
CREATE UNIQUE INDEX "CauseTranslation_causeId_languageId_key" ON "CauseTranslation"("causeId", "languageId");

-- CreateIndex
CREATE UNIQUE INDEX "Organisation_slug_key" ON "Organisation"("slug");

-- CreateIndex
CREATE INDEX "Organisation_isActive_displayOrder_idx" ON "Organisation"("isActive", "displayOrder");

-- CreateIndex
CREATE INDEX "Organisation_city_state_idx" ON "Organisation"("city", "state");

-- CreateIndex
CREATE INDEX "OrganisationTranslation_languageId_idx" ON "OrganisationTranslation"("languageId");

-- CreateIndex
CREATE UNIQUE INDEX "OrganisationTranslation_organisationId_languageId_key" ON "OrganisationTranslation"("organisationId", "languageId");

-- CreateIndex
CREATE INDEX "OrganisationCause_causeId_isActive_displayOrder_idx" ON "OrganisationCause"("causeId", "isActive", "displayOrder");

-- CreateIndex
CREATE INDEX "OrganisationCause_organisationId_isActive_displayOrder_idx" ON "OrganisationCause"("organisationId", "isActive", "displayOrder");

-- CreateIndex
CREATE UNIQUE INDEX "OrganisationCause_organisationId_causeId_key" ON "OrganisationCause"("organisationId", "causeId");

-- AddForeignKey
ALTER TABLE "CauseTranslation" ADD CONSTRAINT "CauseTranslation_causeId_fkey" FOREIGN KEY ("causeId") REFERENCES "Cause"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CauseTranslation" ADD CONSTRAINT "CauseTranslation_languageId_fkey" FOREIGN KEY ("languageId") REFERENCES "Language"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrganisationTranslation" ADD CONSTRAINT "OrganisationTranslation_organisationId_fkey" FOREIGN KEY ("organisationId") REFERENCES "Organisation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrganisationTranslation" ADD CONSTRAINT "OrganisationTranslation_languageId_fkey" FOREIGN KEY ("languageId") REFERENCES "Language"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrganisationCause" ADD CONSTRAINT "OrganisationCause_organisationId_fkey" FOREIGN KEY ("organisationId") REFERENCES "Organisation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OrganisationCause" ADD CONSTRAINT "OrganisationCause_causeId_fkey" FOREIGN KEY ("causeId") REFERENCES "Cause"("id") ON DELETE CASCADE ON UPDATE CASCADE;
