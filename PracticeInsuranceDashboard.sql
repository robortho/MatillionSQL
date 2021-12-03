


SELECT DISTINCT
	GETDATE() AS AsOfDate
	, 'Today' AS ExamFilterType
	, NULL AS ICS_Link
    , 'https://portal.orthofi.com/Patient/Detail/'+CAST(pe.PatientId AS VARCHAR(8))+'#tab=nledger' AS PatientLink
	, pe.ExamTypeId
	, et.Name AS ExamType
	, ISNULL(GuardianInsuranceCount.InsuranceCount, 0) AS GuardianInsuranceCount
	, ISNULL(PatientInsuranceCount.InsuranceCount, 0) AS PatientInsuranceCount
	, pe.PatientExamId
	, pe.PatientFormsStatusId
	, pe.PatientId
	, p.LastName + ', ' + p.FirstName AS Patient
	, pe.ExamDate
	, pe.InsuranceMaxAvailable
	, pe.RecordsDate
	, pl.PracticeId
	, pe.PracticeLocationId
	, prac.Name as 'PracticeName'
	, pl.City as 'PracticeLocation'
	, pt.ContractId
	, pt.PatientTreatmentStatusId
	, t.SelectedGuardianId
	, pe.PatientExamResultId
	, pt.StartDate
	, PendingDownPayments.PaymentPlanId
	, pe.IsHipaaFormComplete
	, pe.IsPatientFormComplete
	, pe.IsInsuranceFormComplete
	, pe.IsMedicalFormComplete
	, pe.IsResponsiblePartyFormComplete
	, CAST(ISNULL(pt.SelectedAtHome, 0) AS BIT) AS IsStartSmilingAtHome
	, LEFT(psup.FirstName, 1) + '.' + LEFT(psup.LastName, 1) + '.' AS TreatmentCoordinator
	, CAST(CASE WHEN pla.ApplicationModuleId IS NULL THEN 0 ELSE 1 END AS BIT) AS ModuleAccess
	, CASE WHEN ivs.Name IS NULL THEN '' ELSE ivs.NAME END AS InsuranceVerificationStatus
	, p.DateOfBirth
	, pl.FormsEffectiveDate
	, p.PrimaryGuardianId
	, gprimaryup.FirstName + ' ' + gprimaryup.LastName AS PrimaryContact
	, p.FinancialGuardianId
	, gfinancialup.FirstName + ' ' + gfinancialup.LastName AS FinancialContact
	, patprac.FollowUpDate
	, LastMedicalHistoryForm.MedicalHistoryLastCompletedOn
	, CAST(CASE WHEN ISNULL(ExamCounts.ExamCount, 1) > 1 THEN 0 ELSE 1 END AS BIT) AS IsFirstExam
	, NULL AS EstimatedAppliancePlacementDate
	, CAST(CASE WHEN LEN(gfinancial.SSN) > 0 THEN 1 ELSE 0 END AS BIT) AS IsFinancialContactSsnEntered
	, CAST(CASE WHEN pl.SimplifiedPricingEffectiveDate < t.createdon THEN 1 ELSE 0 END AS BIT) AS IsOrthoFiSubmittingInsurance
	, CAST(CASE WHEN pl.FormsEffectiveDate > pe.ExamDate THEN 1 ELSE 0 END AS BIT) AS IsPreOrthoFi
	, CAST(0 AS BIT) AS HasFutureExam
	, pl.TimeZoneOffset
	, -1 as InsuranceClaimId
	,-1 as InsuranceFormSubmissionId
	--,null as ContinuationSubmissionEligibilityDate
	,-1 as RemainingFrequencyId
	, ISNULL(ahgup.username, gprimaryup.username) AS Username
	, patprac.PatientPendingReasonId
	, patprac.PatientPendingReasonOther
	, ppr.Name AS PatientPendingReason
	, per.Name AS PatientExamResult
	,null as IsAutomaticPaymentDistribution
	, CAST(CASE WHEN ISNULL(PatientInsuranceCount.PausedCount, 0) > 0 THEN 1 ELSE 0 END AS BIT) HasPausedInsurance
	, CAST(0 AS BIT) AS IsTerminated
	, ISNULL(dhmo.DHMOCount, 0) AS DHMOCount
	, prac.NavLogoUrl
	, -1 AS InsurancePolicyPatientEligibilityId
	, 0.00 AS EstimatedAR
	, RIGHT(nbr.NBR_NAME, LEN(nbr.NBR_NAME) - 2) AS NoBenefitReason
FROM
	PatientExam pe WITH(NOLOCK) 
	INNER JOIN ExamType et WITH(NOLOCK) ON pe.ExamTypeId = et.ExamTypeId
	INNER JOIN Patient p WITH(NOLOCK) ON pe.PatientId = p.PatientId
	INNER JOIN PracticeLocation pl WITH(NOLOCK) ON pe.PracticeLocationId = pl.PracticeLocationId
	INNER JOIN PatientPractice patprac WITH(NOLOCK) ON patprac.PracticeId = pl.PracticeId AND patprac.PatientId = p.PatientId
	INNER JOIN Practice prac WITH(NOLOCK) ON pl.PracticeId = prac.PracticeId
	INNER JOIN PracticeStaff ps WITH(NOLOCK) ON pe.TreatmentCoordinatorId = ps.PracticeStaffId
	INNER JOIN UserProfile psup WITH(NOLOCK) ON ps.UserId = psup.UserId
	LEFT JOIN TreatmentContract pt WITH(NOLOCK) ON pe.PatientExamId = pt.PatientExamId
	LEFT JOIN Contract t WITH(NOLOCK) ON t.ContractId = pt.ContractId
	LEFT JOIN (SELECT bpp.PaymentPlanId, bpp.ContractId
				FROM PaymentPlan bpp WITH(NOLOCK)
					INNER JOIN TreatmentPaymentPlan pp WITH(NOLOCK) ON pp.PaymentPlanId = bpp.PaymentPlanId
					INNER JOIN Invoices i WITH(NOLOCK) ON pp.PaymentPlanId = i.PaymentPlanId AND i.InvoiceTypeId = 1 AND i.InvoiceClassId = 2 AND (i.InvoiceStatusId = 1 OR i.InvoiceStatusId = 6)
				WHERE
					bpp.PaymentPlanStatusId = 2) PendingDownPayments ON pt.ContractId = PendingDownPayments.ContractId
	LEFT JOIN (SELECT COUNT(1) AS InsuranceCount, SUM(CASE WHEN ippe.InsuranceVerificationStatusId = 8 THEN 1 ELSE 0 END) PausedCount, ippee.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam ippee WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) on ippee.InsurancePolicyPatientEligibilityId = ippe.InsurancePolicyPatientEligibilityId
				GROUP BY ippee.PatientExamId) AS GuardianInsuranceCount ON pe.PatientExamId = GuardianInsuranceCount.PatientExamId
	LEFT JOIN (SELECT COUNT(1) AS InsuranceCount, SUM(CASE WHEN ippe.InsuranceVerificationStatusId = 8 THEN 1 ELSE 0 END) PausedCount, ippee.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam ippee WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) on ippee.InsurancePolicyPatientEligibilityId = ippe.InsurancePolicyPatientEligibilityId
				WHERE (ippe.InsurancePlanPriorityId <> 5 OR ippe.InsurancePlanPriorityId IS NULL)
				GROUP BY ippee.PatientExamId) AS PatientInsuranceCount ON pe.PatientExamId = PatientInsuranceCount.PatientExamId
	LEFT JOIN dbo.PracticeLocationApplicationModule pla WITH(NOLOCK) ON (pe.PracticeLocationId = pla.PracticeLocationId AND pla.ApplicationModuleId IN (12) AND pl.InsuranceSubmissionEffectiveDate IS NOT NULL AND ISNULL(pe.RecordsDate, pe.ExamDate) >= pl.InsuranceSubmissionEffectiveDate)
	LEFT JOIN dbo.InsuranceSummary insum WITH(NOLOCK) ON pe.PatientExamId = insum.PatientExamId
	LEFT JOIN dbo.InsuranceVerificationStatus ivs WITH(NOLOCK) ON insum.InsuranceVerificationStatusId = ivs.InsuranceVerificationStatusId
	LEFT JOIN Guardian gprimary WITH(NOLOCK) ON p.PrimaryGuardianId = gprimary.GuardianId
	LEFT JOIN UserProfile gprimaryup WITH(NOLOCK) ON gprimary.UserId = gprimaryup.UserId
	LEFT JOIN Guardian gfinancial WITH(NOLOCK) ON p.FinancialGuardianId = gfinancial.GuardianId
	LEFT JOIN UserProfile gfinancialup WITH(NOLOCK) ON gfinancial.UserId = gfinancialup.UserId
	LEFT JOIN (SELECT pe2.PatientId, MAX(pemh.UpdatedOn) AS MedicalHistoryLastCompletedOn
				FROM PatientExamMedicalHistory pemh WITH(NOLOCK)
					INNER JOIN PatientExam pe2 WITH(NOLOCK) ON pemh.PatientExamId = pe2.PatientExamId
				GROUP BY
					pe2.PatientId) AS LastMedicalHistoryForm ON pe.PatientId = LastMedicalHistoryForm.PatientId
	LEFT JOIN Guardian accountHoldingGuardian WITH(NOLOCK) ON gprimary.accountHoldingGuardianId = accountHoldingGuardian.GuardianId
	LEFT JOIN UserProfile ahgup WITH(NOLOCK) ON accountHoldingGuardian.UserId = ahgup.UserId
	LEFT JOIN PatientPendingReason ppr WITH(NOLOCK) ON patprac.PatientPendingReasonId = ppr.PatientPendingReasonId
	LEFT JOIN PatientExamResult per WITH(NOLOCK) ON pe.PatientExamResultId = per.PatientExamResultId
	INNER JOIN (SELECT pe2.PatientId, COUNT(1) AS ExamCount
				FROM PatientExam pe2 WITH(NOLOCK)
				GROUP BY pe2.PatientId) AS ExamCounts ON p.PatientId = ExamCounts.PatientId
	LEFT JOIN (SELECT COUNT(1) AS DHMOCount, eligExam.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam eligExam WITH(NOLOCK)
					INNER JOIN InsurancePolicyPatientEligibility elig WITH(NOLOCK) ON elig.InsurancePolicyPatientEligibilityId = eligExam.InsurancePolicyPatientEligibilityId
					INNER JOIN InsurancePolicyPatient patient WITH(NOLOCK) ON patient.InsurancePolicyPatientId = elig.InsurancePolicyPatientId
					INNER JOIN InsurancePolicy policy WITH(NOLOCK) ON policy.InsurancePolicyId = patient.InsurancePolicyId
					LEFT JOIN InsuranceGroup ig WITH(NOLOCK) ON policy.InsuranceGroupId = ig.InsuranceGroupId
				WHERE ig.InsuranceNetworkTypeId = 2 AND (elig.InsuranceVerificationStatusID <> 5 OR elig.InsuranceVerificationStatusID IS NULL) AND policy.IsTerminated = 0
				GROUP BY eligExam.PatientExamId) AS dhmo ON pe.PatientExamId = dhmo.PatientExamId			
	LEFT JOIN (SELECT 
				ipp.PatientId
				, STUFF((
					SELECT DISTINCT ' | ' + nbr2.Name
					FROM NoBenefitReason nbr2 WITH(NOLOCK)
					INNER JOIN InsurancePolicyPatientEligibility ippe2 WITH(NOLOCK) ON ippe2.NoBenefitReasonId = nbr2.NoBenefitReasonId
					INNER JOIN InsurancePolicyPatient ipp2 WITH(NOLOCK) ON ipp2.InsurancePolicyPatientId = ippe2.InsurancePolicyPatientId
					WHERE ipp.PatientId = ipp2.PatientId
					FOR XML PATH('')
				),1,1,'') AS NBR_NAME
				FROM NoBenefitReason nbr WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) ON ippe.NoBenefitReasonId = nbr.NoBenefitReasonId
				INNER JOIN InsurancePolicyPatient ipp WITH(NOLOCK) ON ipp.InsurancePolicyPatientId = ippe.InsurancePolicyPatientId) nbr ON nbr.PatientId = pe.PatientId
WHERE
	(
		(pe.PatientExamResultId IS NULL AND dbo.GetTimezoneAdjustedDate(ISNULL(pe.RecordsDate, pe.ExamDate), pl.TimeZoneOffset) = /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())))
		OR
		(ISNULL(pe.PatientExamResultId, 0) = 1 AND pt.PatientTreatmentStatusId IS NOT NULL AND pt.PatientTreatmentStatusId < 4 AND patprac.FollowUpDate IS NULL AND ((dbo.GetTimezoneAdjustedDate (pe.ExamDate, pl.TimeZoneOffset) = /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())) AND pe.RecordsDate IS NULL AND pt.StartDate IS NULL) OR (pe.RecordsDate IS NOT NULL AND dbo.GetTimezoneAdjustedDate (pe.RecordsDate, pl.TimeZoneOffset) = /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))) OR (pt.StartDate IS NOT NULL AND dbo.GetTimezoneAdjustedDate (pt.StartDate, pl.TimeZoneOffset) = /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())))))
		OR
		(ISNULL(pe.PatientExamResultId, 0) = 1 AND pt.StartDate IS NULL AND pt.SelectedAtHome = 1 AND ISNULL(pt.PatientTreatmentStatusId, 0) < 4)
	)
	AND p.IsActive = 1
	AND pe.IsActive = 1
	AND pe.HideOnDashboard = 0

UNION ALL
		
SELECT DISTINCT
	GETDATE() AS AsOfDate
	, 'Tomorrow' AS ExamFilerType
    , NULL AS ICS_Link
    , 'https://portal.orthofi.com/Patient/Detail/'+CAST(pe.PatientId AS VARCHAR(8))+'#tab=nledger' AS PatientLink
	, pe.ExamTypeId
	, et.Name AS ExamType
	, ISNULL(GuardianInsuranceCount.InsuranceCount, 0) AS GuardianInsuranceCount
	, ISNULL(PatientInsuranceCount.InsuranceCount, 0) AS PatientInsuranceCount
	, pe.PatientExamId
	, pe.PatientFormsStatusId
	, pe.PatientId
	, p.LastName + ', ' + p.FirstName AS Patient
	, pe.ExamDate
	, pe.InsuranceMaxAvailable
	, pe.RecordsDate
	, pl.PracticeId
	, pe.PracticeLocationId
	, prac.Name as 'PracticeName'
	, pl.City as 'PracticeLocation'
	, pt.ContractId
	, pt.PatientTreatmentStatusId
	, t.SelectedGuardianId
	, pe.PatientExamResultId
	, pt.StartDate
	, PendingDownPayments.PaymentPlanId
	, pe.IsHipaaFormComplete
	, pe.IsPatientFormComplete
	, pe.IsInsuranceFormComplete
	, pe.IsMedicalFormComplete
	, pe.IsResponsiblePartyFormComplete
	, CAST(ISNULL(pt.SelectedAtHome, 0) AS BIT) AS IsStartSmilingAtHome
	, LEFT(psup.FirstName, 1) + '.' + LEFT(psup.LastName, 1) + '.' AS TreatmentCoordinator
	, CAST(CASE WHEN pla.ApplicationModuleId IS NULL THEN 0 ELSE 1 END AS BIT) AS ModuleAccess
	, CASE WHEN ivs.Name IS NULL THEN '' ELSE ivs.NAME END AS InsuranceVerificationStatus
	, p.DateOfBirth
	, pl.FormsEffectiveDate
	, p.PrimaryGuardianId
	, gprimaryup.FirstName + ' ' + gprimaryup.LastName AS PrimaryContact
	, p.FinancialGuardianId
	, gfinancialup.FirstName + ' ' + gfinancialup.LastName AS FinancialContact
	, patprac.FollowUpDate
	, LastMedicalHistoryForm.MedicalHistoryLastCompletedOn
	, CAST(CASE WHEN ISNULL(ExamCounts.ExamCount, 1) > 1 THEN 0 ELSE 1 END AS BIT) AS IsFirstExam
	, NULL AS EstimatedAppliancePlacementDate
	, CAST(CASE WHEN LEN(gfinancial.SSN) > 0 THEN 1 ELSE 0 END AS BIT) AS IsFinancialContactSsnEntered
	, CAST(CASE WHEN pl.SimplifiedPricingEffectiveDate < t.createdon THEN 1 ELSE 0 END AS BIT) AS IsOrthoFiSubmittingInsurance
	, CAST(CASE WHEN pl.FormsEffectiveDate > pe.ExamDate THEN 1 ELSE 0 END AS BIT) AS IsPreOrthoFi
	, CAST(0 AS BIT) AS HasFutureExam
	, pl.TimeZoneOffset
	, -1 as InsuranceClaimId
	,-1 as InsuranceFormSubmissionId
	--,null as ContinuationSubmissionEligibilityDate
	,-1 as RemainingFrequencyId
	, ISNULL(ahgup.username, gprimaryup.username) AS Username
	, patprac.PatientPendingReasonId
	, patprac.PatientPendingReasonOther
	, ppr.Name AS PatientPendingReason
	, per.Name AS PatientExamResult
	,null as IsAutomaticPaymentDistribution
	, CAST(CASE WHEN ISNULL(PatientInsuranceCount.PausedCount, 0) > 0 THEN 1 ELSE 0 END AS BIT) HasPausedInsurance
	, CAST(0 AS BIT) AS IsTerminated
	, ISNULL(dhmo.DHMOCount, 0) AS DHMOCount
	, prac.NavLogoUrl
	, -1 AS InsurancePolicyPatientEligibilityId
	, 0.00 AS EstimatedAR
	, RIGHT(nbr.NBR_NAME, LEN(nbr.NBR_NAME) - 2) AS NoBenefitReason
FROM
	PatientExam pe WITH(NOLOCK) 
	INNER JOIN ExamType et WITH(NOLOCK) ON pe.ExamTypeId = et.ExamTypeId
	INNER JOIN Patient p WITH(NOLOCK) ON pe.PatientId = p.PatientId
	INNER JOIN PracticeLocation pl WITH(NOLOCK) ON pe.PracticeLocationId = pl.PracticeLocationId
	INNER JOIN PatientPractice patprac WITH(NOLOCK) ON patprac.PracticeId = pl.PracticeId AND patprac.PatientId = p.PatientId
	INNER JOIN Practice prac WITH(NOLOCK) ON pl.PracticeId = prac.PracticeId
	INNER JOIN PracticeStaff ps WITH(NOLOCK) ON pe.TreatmentCoordinatorId = ps.PracticeStaffId
	INNER JOIN UserProfile psup WITH(NOLOCK) ON ps.UserId = psup.UserId
	LEFT JOIN TreatmentContract pt WITH(NOLOCK) ON pe.PatientExamId = pt.PatientExamId
	LEFT JOIN Contract t WITH(NOLOCK) ON t.ContractId = pt.ContractId
	LEFT JOIN (SELECT bpp.PaymentPlanId, bpp.ContractId
				FROM PaymentPlan bpp WITH(NOLOCK)
					INNER JOIN TreatmentPaymentPlan pp WITH(NOLOCK) ON pp.PaymentPlanId = bpp.PaymentPlanId
					INNER JOIN Invoices i WITH(NOLOCK) ON pp.PaymentPlanId = i.PaymentPlanId AND i.InvoiceTypeId = 1 AND i.InvoiceClassId = 2 AND (i.InvoiceStatusId = 1 OR i.InvoiceStatusId = 6)
				WHERE
					bpp.PaymentPlanStatusId = 2) PendingDownPayments ON pt.ContractId = PendingDownPayments.ContractId
	LEFT JOIN (SELECT COUNT(1) AS InsuranceCount, SUM(CASE WHEN ippe.InsuranceVerificationStatusId = 8 THEN 1 ELSE 0 END) PausedCount, ippee.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam ippee WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) on ippee.InsurancePolicyPatientEligibilityId = ippe.InsurancePolicyPatientEligibilityId
				GROUP BY ippee.PatientExamId) AS GuardianInsuranceCount ON pe.PatientExamId = GuardianInsuranceCount.PatientExamId
	LEFT JOIN (SELECT COUNT(1) AS InsuranceCount, SUM(CASE WHEN ippe.InsuranceVerificationStatusId = 8 THEN 1 ELSE 0 END) PausedCount, ippee.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam ippee WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) on ippee.InsurancePolicyPatientEligibilityId = ippe.InsurancePolicyPatientEligibilityId
				WHERE (ippe.InsurancePlanPriorityId <> 5 OR ippe.InsurancePlanPriorityId IS NULL)
				GROUP BY ippee.PatientExamId) AS PatientInsuranceCount ON pe.PatientExamId = PatientInsuranceCount.PatientExamId
	LEFT JOIN dbo.PracticeLocationApplicationModule pla WITH(NOLOCK) ON (pe.PracticeLocationId = pla.PracticeLocationId AND pla.ApplicationModuleId IN (12) AND pl.InsuranceSubmissionEffectiveDate IS NOT NULL AND ISNULL(pe.RecordsDate, pe.ExamDate) >= pl.InsuranceSubmissionEffectiveDate)
	LEFT JOIN dbo.InsuranceSummary insum WITH(NOLOCK) ON pe.PatientExamId = insum.PatientExamId
	LEFT JOIN dbo.InsuranceVerificationStatus ivs WITH(NOLOCK) ON insum.InsuranceVerificationStatusId = ivs.InsuranceVerificationStatusId
	LEFT JOIN Guardian gprimary WITH(NOLOCK) ON p.PrimaryGuardianId = gprimary.GuardianId
	LEFT JOIN UserProfile gprimaryup WITH(NOLOCK) ON gprimary.UserId = gprimaryup.UserId
	LEFT JOIN Guardian gfinancial WITH(NOLOCK) ON p.FinancialGuardianId = gfinancial.GuardianId
	LEFT JOIN UserProfile gfinancialup WITH(NOLOCK) ON gfinancial.UserId = gfinancialup.UserId
	LEFT JOIN (SELECT pe2.PatientId, MAX(pemh.UpdatedOn) AS MedicalHistoryLastCompletedOn
				FROM PatientExamMedicalHistory pemh WITH(NOLOCK)
					INNER JOIN PatientExam pe2 WITH(NOLOCK) ON pemh.PatientExamId = pe2.PatientExamId
				GROUP BY
					pe2.PatientId) AS LastMedicalHistoryForm ON pe.PatientId = LastMedicalHistoryForm.PatientId
	LEFT JOIN Guardian accountHoldingGuardian WITH(NOLOCK) ON gprimary.accountHoldingGuardianId = accountHoldingGuardian.GuardianId
	LEFT JOIN UserProfile ahgup WITH(NOLOCK) ON accountHoldingGuardian.UserId = ahgup.UserId
	LEFT JOIN PatientPendingReason ppr WITH(NOLOCK) ON patprac.PatientPendingReasonId = ppr.PatientPendingReasonId
	LEFT JOIN PatientExamResult per WITH(NOLOCK) ON pe.PatientExamResultId = per.PatientExamResultId
	INNER JOIN (SELECT pe2.PatientId, COUNT(1) AS ExamCount
				FROM PatientExam pe2 WITH(NOLOCK)
				GROUP BY pe2.PatientId) AS ExamCounts ON p.PatientId = ExamCounts.PatientId
	LEFT JOIN (SELECT COUNT(1) AS DHMOCount, eligExam.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam eligExam WITH(NOLOCK)
					INNER JOIN InsurancePolicyPatientEligibility elig WITH(NOLOCK) ON elig.InsurancePolicyPatientEligibilityId = eligExam.InsurancePolicyPatientEligibilityId
					INNER JOIN InsurancePolicyPatient patient WITH(NOLOCK) ON patient.InsurancePolicyPatientId = elig.InsurancePolicyPatientId
					INNER JOIN InsurancePolicy policy WITH(NOLOCK) ON policy.InsurancePolicyId = patient.InsurancePolicyId
					LEFT JOIN InsuranceGroup ig WITH(NOLOCK) ON policy.InsuranceGroupId = ig.InsuranceGroupId
				WHERE ig.InsuranceNetworkTypeId = 2 AND (elig.InsuranceVerificationStatusID <> 5 OR elig.InsuranceVerificationStatusID IS NULL) AND policy.IsTerminated = 0
				GROUP BY eligExam.PatientExamId) AS dhmo ON pe.PatientExamId = dhmo.PatientExamId
	LEFT JOIN (SELECT 
				ipp.PatientId
				, STUFF((
					SELECT DISTINCT ' | ' + nbr2.Name
					FROM NoBenefitReason nbr2 WITH(NOLOCK)
					INNER JOIN InsurancePolicyPatientEligibility ippe2 WITH(NOLOCK) ON ippe2.NoBenefitReasonId = nbr2.NoBenefitReasonId
					INNER JOIN InsurancePolicyPatient ipp2 WITH(NOLOCK) ON ipp2.InsurancePolicyPatientId = ippe2.InsurancePolicyPatientId
					WHERE ipp.PatientId = ipp2.PatientId
					FOR XML PATH('')
				),1,1,'') AS NBR_NAME
				FROM NoBenefitReason nbr WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) ON ippe.NoBenefitReasonId = nbr.NoBenefitReasonId
				INNER JOIN InsurancePolicyPatient ipp WITH(NOLOCK) ON ipp.InsurancePolicyPatientId = ippe.InsurancePolicyPatientId) nbr ON nbr.PatientId = pe.PatientId
WHERE
	p.IsActive = 1
	AND pe.IsActive = 1
	AND pe.HideOnDashboard = 0
	AND 
	(((dbo.GetTimezoneAdjustedDate (pe.ExamDate, pl.TimeZoneOffset) = /*@Tomorrow*/DATEADD(dd, 1, DATEDIFF(dd, 0, GETDATE())) OR dbo.GetTimezoneAdjustedDate (pe.RecordsDate, pl.TimeZoneOffset) = /*@Tomorrow*/DATEADD(dd, 1, DATEDIFF(dd, 0, GETDATE()))) AND pe.PatientExamResultId IS NULL) OR ((dbo.GetTimezoneAdjustedDate (pe.RecordsDate, pl.TimeZoneOffset) = /*@Tomorrow*/DATEADD(dd, 1, DATEDIFF(dd, 0, GETDATE())) OR dbo.GetTimezoneAdjustedDate (pt.StartDate, pl.TimeZoneOffset) = /*@Tomorrow*/DATEADD(dd, 1, DATEDIFF(dd, 0, GETDATE()))) AND pt.PatientTreatmentStatusId < 4))

UNION ALL
	
SELECT ---TOP 1000
	GETDATE() AS AsOfDate
	, 'Upcoming' AS ExamFilterType
    , NULL AS ICS_Link
    , 'https://portal.orthofi.com/Patient/Detail/'+CAST(pe.PatientId AS VARCHAR(8))+'#tab=nledger' AS PatientLink
	, pe.ExamTypeId
	, et.Name AS ExamType
	, ISNULL(GuardianInsuranceCount.InsuranceCount, 0) AS GuardianInsuranceCount
	, ISNULL(PatientInsuranceCount.InsuranceCount, 0) AS PatientInsuranceCount
	, pe.PatientExamId
	, pe.PatientFormsStatusId
	, pe.PatientId
	, p.LastName + ', ' + p.FirstName AS Patient
	, pe.ExamDate
	, pe.InsuranceMaxAvailable
	, pe.RecordsDate
	, pl.PracticeId
	, pe.PracticeLocationId
	, prac.Name as 'PracticeName'
	, pl.City as 'PracticeLocation'
	, pt.ContractId
	, pt.PatientTreatmentStatusId
	, t.SelectedGuardianId
	, pe.PatientExamResultId
	, pt.StartDate
	, PendingDownPayments.PaymentPlanId
	, pe.IsHipaaFormComplete
	, pe.IsPatientFormComplete
	, pe.IsInsuranceFormComplete
	, pe.IsMedicalFormComplete
	, pe.IsResponsiblePartyFormComplete
	, CAST(ISNULL(pt.SelectedAtHome, 0) AS BIT) AS IsStartSmilingAtHome
	, LEFT(psup.FirstName, 1) + '.' + LEFT(psup.LastName, 1) + '.' AS TreatmentCoordinator
	, CAST(CASE WHEN pla.ApplicationModuleId IS NULL THEN 0 ELSE 1 END AS BIT) AS ModuleAccess
	, CASE WHEN ivs.Name IS NULL THEN '' ELSE ivs.NAME END AS InsuranceVerificationStatus
	, p.DateOfBirth
	, pl.FormsEffectiveDate
	, p.PrimaryGuardianId
	, gprimaryup.FirstName + ' ' + gprimaryup.LastName AS PrimaryContact
	, p.FinancialGuardianId
	, gfinancialup.FirstName + ' ' + gfinancialup.LastName AS FinancialContact
	, patprac.FollowUpDate
	, LastMedicalHistoryForm.MedicalHistoryLastCompletedOn
	, CAST(CASE WHEN ISNULL(ExamCounts.ExamCount, 1) > 1 THEN 0 ELSE 1 END AS BIT) AS IsFirstExam
	, NULL AS EstimatedAppliancePlacementDate
	, CAST(CASE WHEN LEN(gfinancial.SSN) > 0 THEN 1 ELSE 0 END AS BIT) AS IsFinancialContactSsnEntered
	, CAST(CASE WHEN pl.SimplifiedPricingEffectiveDate < t.createdon THEN 1 ELSE 0 END AS BIT) AS IsOrthoFiSubmittingInsurance
	, CAST(CASE WHEN pl.FormsEffectiveDate > pe.ExamDate THEN 1 ELSE 0 END AS BIT) AS IsPreOrthoFi
	, CAST(0 AS BIT) AS HasFutureExam
	, pl.TimeZoneOffset
	, -1 as InsuranceClaimId
	,-1 as InsuranceFormSubmissionId
	--,null as ContinuationSubmissionEligibilityDate
	,-1 as RemainingFrequencyId
	, ISNULL(ahgup.username, gprimaryup.username) AS Username
	, patprac.PatientPendingReasonId
	, patprac.PatientPendingReasonOther
	, ppr.Name AS PatientPendingReason
	, per.Name AS PatientExamResult
	,null as IsAutomaticPaymentDistribution
	, CAST(CASE WHEN ISNULL(PatientInsuranceCount.PausedCount, 0) > 0 THEN 1 ELSE 0 END AS BIT) HasPausedInsurance
	, CAST(0 AS BIT) AS IsTerminated
	, ISNULL(dhmo.DHMOCount, 0) AS DHMOCount
	, prac.NavLogoUrl
	, -1 AS InsurancePolicyPatientEligibilityId
	, 0.00 AS EstimatedAR
	, RIGHT(nbr.NBR_NAME, LEN(nbr.NBR_NAME) - 2) AS NoBenefitReason
FROM
	PatientExam pe WITH(NOLOCK) 
	INNER JOIN ExamType et WITH(NOLOCK) ON pe.ExamTypeId = et.ExamTypeId
	INNER JOIN Patient p WITH(NOLOCK) ON pe.PatientId = p.PatientId
	INNER JOIN PracticeLocation pl WITH(NOLOCK) ON pe.PracticeLocationId = pl.PracticeLocationId
	INNER JOIN PatientPractice patprac WITH(NOLOCK) ON patprac.PracticeId = pl.PracticeId AND patprac.PatientId = p.PatientId
	INNER JOIN Practice prac WITH(NOLOCK) ON pl.PracticeId = prac.PracticeId
	INNER JOIN PracticeStaff ps WITH(NOLOCK) ON pe.TreatmentCoordinatorId = ps.PracticeStaffId
	INNER JOIN UserProfile psup WITH(NOLOCK) ON ps.UserId = psup.UserId
	LEFT JOIN TreatmentContract pt WITH(NOLOCK) ON pe.PatientExamId = pt.PatientExamId
	LEFT JOIN Contract t WITH(NOLOCK) ON t.ContractId = pt.ContractId
	LEFT JOIN (SELECT bpp.PaymentPlanId, bpp.ContractId
				FROM PaymentPlan bpp WITH(NOLOCK)
					INNER JOIN TreatmentPaymentPlan pp WITH(NOLOCK) ON pp.PaymentPlanId = bpp.PaymentPlanId
					INNER JOIN Invoices i WITH(NOLOCK) ON pp.PaymentPlanId = i.PaymentPlanId AND i.InvoiceTypeId = 1 AND i.InvoiceClassId = 2 AND (i.InvoiceStatusId = 1 OR i.InvoiceStatusId = 6)
				WHERE
					bpp.PaymentPlanStatusId = 2) PendingDownPayments ON pt.ContractId = PendingDownPayments.ContractId
	LEFT JOIN (SELECT COUNT(1) AS InsuranceCount, SUM(CASE WHEN ippe.InsuranceVerificationStatusId = 8 THEN 1 ELSE 0 END) PausedCount, ippee.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam ippee WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) on ippee.InsurancePolicyPatientEligibilityId = ippe.InsurancePolicyPatientEligibilityId
				GROUP BY ippee.PatientExamId) AS GuardianInsuranceCount ON pe.PatientExamId = GuardianInsuranceCount.PatientExamId
	LEFT JOIN (SELECT COUNT(1) AS InsuranceCount, SUM(CASE WHEN ippe.InsuranceVerificationStatusId = 8 THEN 1 ELSE 0 END) PausedCount, ippee.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam ippee WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) on ippee.InsurancePolicyPatientEligibilityId = ippe.InsurancePolicyPatientEligibilityId
				WHERE (ippe.InsurancePlanPriorityId <> 5 OR ippe.InsurancePlanPriorityId IS NULL)
				GROUP BY ippee.PatientExamId) AS PatientInsuranceCount ON pe.PatientExamId = PatientInsuranceCount.PatientExamId
	LEFT JOIN dbo.PracticeLocationApplicationModule pla WITH(NOLOCK) ON (pe.PracticeLocationId = pla.PracticeLocationId AND pla.ApplicationModuleId IN (12) AND pl.InsuranceSubmissionEffectiveDate IS NOT NULL AND ISNULL(pe.RecordsDate, pe.ExamDate) >= pl.InsuranceSubmissionEffectiveDate)
	LEFT JOIN dbo.InsuranceSummary insum WITH(NOLOCK) ON pe.PatientExamId = insum.PatientExamId
	LEFT JOIN dbo.InsuranceVerificationStatus ivs WITH(NOLOCK) ON insum.InsuranceVerificationStatusId = ivs.InsuranceVerificationStatusId
	LEFT JOIN Guardian gprimary WITH(NOLOCK) ON p.PrimaryGuardianId = gprimary.GuardianId
	LEFT JOIN UserProfile gprimaryup WITH(NOLOCK) ON gprimary.UserId = gprimaryup.UserId
	LEFT JOIN Guardian gfinancial WITH(NOLOCK) ON p.FinancialGuardianId = gfinancial.GuardianId
	LEFT JOIN UserProfile gfinancialup WITH(NOLOCK) ON gfinancial.UserId = gfinancialup.UserId
	LEFT JOIN (SELECT pe2.PatientId, MAX(pemh.UpdatedOn) AS MedicalHistoryLastCompletedOn
				FROM PatientExamMedicalHistory pemh WITH(NOLOCK)
					INNER JOIN PatientExam pe2 WITH(NOLOCK) ON pemh.PatientExamId = pe2.PatientExamId
				GROUP BY
					pe2.PatientId) AS LastMedicalHistoryForm ON pe.PatientId = LastMedicalHistoryForm.PatientId
	LEFT JOIN Guardian accountHoldingGuardian WITH(NOLOCK) ON gprimary.accountHoldingGuardianId = accountHoldingGuardian.GuardianId
	LEFT JOIN UserProfile ahgup WITH(NOLOCK) ON accountHoldingGuardian.UserId = ahgup.UserId
	LEFT JOIN PatientPendingReason ppr WITH(NOLOCK) ON patprac.PatientPendingReasonId = ppr.PatientPendingReasonId
	LEFT JOIN PatientExamResult per WITH(NOLOCK) ON pe.PatientExamResultId = per.PatientExamResultId
	INNER JOIN (SELECT pe2.PatientId, COUNT(1) AS ExamCount
				FROM PatientExam pe2 WITH(NOLOCK)
				GROUP BY pe2.PatientId) AS ExamCounts ON p.PatientId = ExamCounts.PatientId
	LEFT JOIN (SELECT COUNT(1) AS DHMOCount, eligExam.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam eligExam WITH(NOLOCK)
					INNER JOIN InsurancePolicyPatientEligibility elig WITH(NOLOCK) ON elig.InsurancePolicyPatientEligibilityId = eligExam.InsurancePolicyPatientEligibilityId
					INNER JOIN InsurancePolicyPatient patient WITH(NOLOCK) ON patient.InsurancePolicyPatientId = elig.InsurancePolicyPatientId
					INNER JOIN InsurancePolicy policy WITH(NOLOCK) ON policy.InsurancePolicyId = patient.InsurancePolicyId
					LEFT JOIN InsuranceGroup ig WITH(NOLOCK) ON policy.InsuranceGroupId = ig.InsuranceGroupId
				WHERE ig.InsuranceNetworkTypeId = 2 AND (elig.InsuranceVerificationStatusID <> 5 OR elig.InsuranceVerificationStatusID IS NULL) AND policy.IsTerminated = 0
				GROUP BY eligExam.PatientExamId) AS dhmo ON pe.PatientExamId = dhmo.PatientExamId	
	LEFT JOIN (SELECT 
				ipp.PatientId
				, STUFF((
					SELECT DISTINCT ' | ' + nbr2.Name
					FROM NoBenefitReason nbr2 WITH(NOLOCK)
					INNER JOIN InsurancePolicyPatientEligibility ippe2 WITH(NOLOCK) ON ippe2.NoBenefitReasonId = nbr2.NoBenefitReasonId
					INNER JOIN InsurancePolicyPatient ipp2 WITH(NOLOCK) ON ipp2.InsurancePolicyPatientId = ippe2.InsurancePolicyPatientId
					WHERE ipp.PatientId = ipp2.PatientId
					FOR XML PATH('')
				),1,1,'') AS NBR_NAME
				FROM NoBenefitReason nbr WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) ON ippe.NoBenefitReasonId = nbr.NoBenefitReasonId
				INNER JOIN InsurancePolicyPatient ipp WITH(NOLOCK) ON ipp.InsurancePolicyPatientId = ippe.InsurancePolicyPatientId) nbr ON nbr.PatientId = pe.PatientId
WHERE
	p.IsActive = 1
	AND pe.IsActive = 1
	AND pe.HideOnDashboard = 0
	AND 
	(((dbo.GetTimezoneAdjustedDate (pe.ExamDate, pl.TimeZoneOffset) > /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())) OR (pe.RecordsDate IS NOT NULL AND dbo.GetTimezoneAdjustedDate (pe.RecordsDate, pl.TimeZoneOffset) > /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())))) AND pe.PatientExamResultId IS NULL) OR ((dbo.GetTimezoneAdjustedDate (pe.RecordsDate, pl.TimeZoneOffset) > /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())) OR dbo.GetTimezoneAdjustedDate (pt.StartDate, pl.TimeZoneOffset) > /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))) AND pt.PatientTreatmentStatusId < 4))
--ORDER BY
	--ISNULL(pt.StartDate, ISNULL(pe.RecordsDate, pe.ExamDate))

UNION ALL
	
SELECT DISTINCT
	GETDATE() AS AsOfDate
	, 'PastDue' AS ExamFilterType
    , NULL AS ICS_Link
    , 'https://portal.orthofi.com/Patient/Detail/'+CAST(pe.PatientId AS VARCHAR(8))+'#tab=nledger' AS PatientLink
	, pe.ExamTypeId
	, et.Name AS ExamType
	, ISNULL(GuardianInsuranceCount.InsuranceCount, 0) AS GuardianInsuranceCount
	, ISNULL(PatientInsuranceCount.InsuranceCount, 0) AS PatientInsuranceCount
	, pe.PatientExamId
	, pe.PatientFormsStatusId
	, pe.PatientId
	, p.LastName + ', ' + p.FirstName AS Patient
	, pe.ExamDate
	, pe.InsuranceMaxAvailable
	, pe.RecordsDate
	, pl.PracticeId
	, pe.PracticeLocationId
	, prac.Name as 'PracticeName'
	, pl.City as 'PracticeLocation'
	, pt.ContractId
	, pt.PatientTreatmentStatusId
	, t.SelectedGuardianId
	, pe.PatientExamResultId
	, pt.StartDate
	, PendingDownPayments.PaymentPlanId
	, pe.IsHipaaFormComplete
	, pe.IsPatientFormComplete
	, pe.IsInsuranceFormComplete
	, pe.IsMedicalFormComplete
	, pe.IsResponsiblePartyFormComplete
	, CAST(ISNULL(pt.SelectedAtHome, 0) AS BIT) AS IsStartSmilingAtHome
	, LEFT(psup.FirstName, 1) + '.' + LEFT(psup.LastName, 1) + '.' AS TreatmentCoordinator
	, CAST(CASE WHEN pla.ApplicationModuleId IS NULL THEN 0 ELSE 1 END AS BIT) AS ModuleAccess
	, CASE WHEN ivs.Name IS NULL THEN '' ELSE ivs.NAME END AS InsuranceVerificationStatus
	, p.DateOfBirth
	, pl.FormsEffectiveDate
	, p.PrimaryGuardianId
	, gprimaryup.FirstName + ' ' + gprimaryup.LastName AS PrimaryContact
	, p.FinancialGuardianId
	, gfinancialup.FirstName + ' ' + gfinancialup.LastName AS FinancialContact
	, patprac.FollowUpDate
	, LastMedicalHistoryForm.MedicalHistoryLastCompletedOn
	, CAST(CASE WHEN ISNULL(ExamCounts.ExamCount, 1) > 1 THEN 0 ELSE 1 END AS BIT) AS IsFirstExam
	, NULL AS EstimatedAppliancePlacementDate
	, CAST(CASE WHEN LEN(gfinancial.SSN) > 0 THEN 1 ELSE 0 END AS BIT) AS IsFinancialContactSsnEntered
	, CAST(CASE WHEN pl.SimplifiedPricingEffectiveDate < t.createdon THEN 1 ELSE 0 END AS BIT) AS IsOrthoFiSubmittingInsurance
	, CAST(CASE WHEN pl.FormsEffectiveDate > pe.ExamDate THEN 1 ELSE 0 END AS BIT) AS IsPreOrthoFi
	, CAST(CASE WHEN EXISTS(Select PatientExamId from PatientExam pe2 WITH(NOLOCK) where pe2.PatientId = pe.PatientId and pe2.ExamDate > pe.ExamDate) THEN 1 ELSE 0 END AS BIT) AS HasFutureExam
	, pl.TimeZoneOffset
	, -1 as InsuranceClaimId
	,-1 as InsuranceFormSubmissionId
	--,null as ContinuationSubmissionEligibilityDate
	,-1 as RemainingFrequencyId
	, ISNULL(ahgup.username, gprimaryup.username) AS Username
	, patprac.PatientPendingReasonId
	, patprac.PatientPendingReasonOther
	, ppr.Name AS PatientPendingReason
	, per.Name AS PatientExamResult
	,null as IsAutomaticPaymentDistribution
	, CAST(CASE WHEN ISNULL(PatientInsuranceCount.PausedCount, 0) > 0 THEN 1 ELSE 0 END AS BIT) HasPausedInsurance
	, CAST(0 AS BIT) AS IsTerminated
	, ISNULL(dhmo.DHMOCount, 0) AS DHMOCount
	, prac.NavLogoUrl
	, -1 AS InsurancePolicyPatientEligibilityId
	, 0.00 AS EstimatedAR
	, RIGHT(nbr.NBR_NAME, LEN(nbr.NBR_NAME) - 2) AS NoBenefitReason

FROM	
	PatientExam pe WITH(NOLOCK) 
	INNER JOIN ExamType et WITH(NOLOCK) ON pe.ExamTypeId = et.ExamTypeId
	INNER JOIN Patient p WITH(NOLOCK) ON pe.PatientId = p.PatientId
	INNER JOIN PracticeLocation pl WITH(NOLOCK) ON pe.PracticeLocationId = pl.PracticeLocationId
	INNER JOIN PatientPractice patprac WITH(NOLOCK) ON patprac.PracticeId = pl.PracticeId AND patprac.PatientId = p.PatientId
	INNER JOIN Practice prac WITH(NOLOCK) ON pl.PracticeId = prac.PracticeId
	INNER JOIN PracticeStaff ps WITH(NOLOCK) ON pe.TreatmentCoordinatorId = ps.PracticeStaffId
	INNER JOIN UserProfile psup WITH(NOLOCK) ON ps.UserId = psup.UserId
	LEFT JOIN TreatmentContract pt WITH(NOLOCK) ON pe.PatientExamId = pt.PatientExamId
	LEFT JOIN [Contract] t WITH(NOLOCK) ON t.ContractId = pt.ContractId
	LEFT JOIN (SELECT bpp.PaymentPlanId, bpp.ContractId
				FROM PaymentPlan bpp WITH(NOLOCK)
					INNER JOIN TreatmentPaymentPlan pp WITH(NOLOCK) ON pp.PaymentPlanId = bpp.PaymentPlanId
					INNER JOIN Invoices i WITH(NOLOCK) ON pp.PaymentPlanId = i.PaymentPlanId AND i.InvoiceTypeId = 1 AND i.InvoiceClassId = 2 AND (i.InvoiceStatusId = 1 OR i.InvoiceStatusId = 6)
				WHERE
					bpp.PaymentPlanStatusId = 2) PendingDownPayments ON pt.ContractId = PendingDownPayments.ContractId
	LEFT JOIN (SELECT COUNT(1) AS InsuranceCount, SUM(CASE WHEN ippe.InsuranceVerificationStatusId = 8 THEN 1 ELSE 0 END) PausedCount, ippee.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam ippee WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) on ippee.InsurancePolicyPatientEligibilityId = ippe.InsurancePolicyPatientEligibilityId
				GROUP BY ippee.PatientExamId) AS GuardianInsuranceCount ON pe.PatientExamId = GuardianInsuranceCount.PatientExamId
	LEFT JOIN (SELECT COUNT(1) AS InsuranceCount, SUM(CASE WHEN ippe.InsuranceVerificationStatusId = 8 THEN 1 ELSE 0 END) PausedCount, ippee.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam ippee WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) on ippee.InsurancePolicyPatientEligibilityId = ippe.InsurancePolicyPatientEligibilityId
				WHERE (ippe.InsurancePlanPriorityId <> 5 OR ippe.InsurancePlanPriorityId IS NULL)
				GROUP BY ippee.PatientExamId) AS PatientInsuranceCount ON pe.PatientExamId = PatientInsuranceCount.PatientExamId
	LEFT JOIN dbo.PracticeLocationApplicationModule pla WITH(NOLOCK) ON (pe.PracticeLocationId = pla.PracticeLocationId AND pla.ApplicationModuleId IN (12) AND pl.InsuranceSubmissionEffectiveDate IS NOT NULL AND ISNULL(pe.RecordsDate, pe.ExamDate) >= pl.InsuranceSubmissionEffectiveDate)
	LEFT JOIN dbo.InsuranceSummary insum WITH(NOLOCK) ON pe.PatientExamId = insum.PatientExamId
	LEFT JOIN dbo.InsuranceVerificationStatus ivs WITH(NOLOCK) ON insum.InsuranceVerificationStatusId = ivs.InsuranceVerificationStatusId
	LEFT JOIN Guardian gprimary WITH(NOLOCK) ON p.PrimaryGuardianId = gprimary.GuardianId
	LEFT JOIN UserProfile gprimaryup WITH(NOLOCK) ON gprimary.UserId = gprimaryup.UserId
	LEFT JOIN Guardian gfinancial WITH(NOLOCK) ON p.FinancialGuardianId = gfinancial.GuardianId
	LEFT JOIN UserProfile gfinancialup WITH(NOLOCK) ON gfinancial.UserId = gfinancialup.UserId
	LEFT JOIN (SELECT pe2.PatientId, MAX(pemh.UpdatedOn) AS MedicalHistoryLastCompletedOn
				FROM PatientExamMedicalHistory pemh WITH(NOLOCK)
					INNER JOIN PatientExam pe2 WITH(NOLOCK) ON pemh.PatientExamId = pe2.PatientExamId
				GROUP BY
					pe2.PatientId) AS LastMedicalHistoryForm ON pe.PatientId = LastMedicalHistoryForm.PatientId
	LEFT JOIN Guardian accountHoldingGuardian WITH(NOLOCK) ON gprimary.accountHoldingGuardianId = accountHoldingGuardian.GuardianId
	LEFT JOIN UserProfile ahgup WITH(NOLOCK) ON accountHoldingGuardian.UserId = ahgup.UserId
	LEFT JOIN PatientPendingReason ppr WITH(NOLOCK) ON patprac.PatientPendingReasonId = ppr.PatientPendingReasonId
	LEFT JOIN PatientExamResult per WITH(NOLOCK) ON pe.PatientExamResultId = per.PatientExamResultId
	INNER JOIN (SELECT pe2.PatientId, COUNT(1) AS ExamCount
				FROM PatientExam pe2 WITH(NOLOCK)
				GROUP BY pe2.PatientId) AS ExamCounts ON p.PatientId = ExamCounts.PatientId
	LEFT JOIN (SELECT COUNT(1) AS DHMOCount, eligExam.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam eligExam WITH(NOLOCK)
					INNER JOIN InsurancePolicyPatientEligibility elig WITH(NOLOCK) ON elig.InsurancePolicyPatientEligibilityId = eligExam.InsurancePolicyPatientEligibilityId
					INNER JOIN InsurancePolicyPatient patient WITH(NOLOCK) ON patient.InsurancePolicyPatientId = elig.InsurancePolicyPatientId
					INNER JOIN InsurancePolicy policy WITH(NOLOCK) ON policy.InsurancePolicyId = patient.InsurancePolicyId
					LEFT JOIN InsuranceGroup ig WITH(NOLOCK) ON policy.InsuranceGroupId = ig.InsuranceGroupId
				WHERE ig.InsuranceNetworkTypeId = 2 AND (elig.InsuranceVerificationStatusID <> 5 OR elig.InsuranceVerificationStatusID IS NULL) AND policy.IsTerminated = 0
				GROUP BY eligExam.PatientExamId) AS dhmo ON pe.PatientExamId = dhmo.PatientExamId	
	LEFT JOIN (SELECT ippee.PatientExamId
						, COUNT(DISTINCT ippe.InsurancePolicyPatientEligibilityId) Total
						, SUM(ISNULL(ic.EstimatedAr, 0)) TotalAr
						, MAX(ip.CreatedOn) LastCreatedOn
				FROM	InsurancePolicyPatientEligibility ippe WITH(NOLOCK)
					INNER JOIN InsurancePolicyPatientEligibilityExam ippee WITH(NOLOCK) ON ippe.InsurancePolicyPatientEligibilityId = ippee.InsurancePolicyPatientEligibilityId
					INNER JOIN InsurancePolicyPatient ipp WITH(NOLOCK) ON ippe.InsurancePolicyPatientId = ipp.InsurancePolicyPatientId
					INNER JOIN InsurancePolicy ip WITH(NOLOCK) ON ipp.InsurancePolicyId = ip.InsurancePolicyId
					LEFT JOIN InsuranceClaim ic WITH(NOLOCK) ON ippe.InsurancePolicyPatientEligibilityId = ic.InsurancePolicyPatientEligibilityId
				WHERE ippe.InsuranceVerificationStatusId = 4
				GROUP BY
					ippee.PatientExamId) UtvPolicies ON pe.PatientExamId = UtvPolicies.PatientExamId
	LEFT JOIN (SELECT pp.ContractId, MIN(pp.CreatedOn) SignedOn
				FROM PaymentPlan pp WITH(NOLOCK)
				WHERE pp.PaymentPlanTypeId = 1
				GROUP BY pp.ContractId) SignedContract ON t.ContractId = SignedContract.ContractId		
	LEFT JOIN (SELECT 
				ipp.PatientId
				, STUFF((
					SELECT DISTINCT ' | ' + nbr2.Name
					FROM NoBenefitReason nbr2 WITH(NOLOCK)
					INNER JOIN InsurancePolicyPatientEligibility ippe2 WITH(NOLOCK) ON ippe2.NoBenefitReasonId = nbr2.NoBenefitReasonId
					INNER JOIN InsurancePolicyPatient ipp2 WITH(NOLOCK) ON ipp2.InsurancePolicyPatientId = ippe2.InsurancePolicyPatientId
					WHERE ipp.PatientId = ipp2.PatientId
					FOR XML PATH('')
				),1,1,'') AS NBR_NAME
				FROM NoBenefitReason nbr WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) ON ippe.NoBenefitReasonId = nbr.NoBenefitReasonId
				INNER JOIN InsurancePolicyPatient ipp WITH(NOLOCK) ON ipp.InsurancePolicyPatientId = ippe.InsurancePolicyPatientId) nbr ON nbr.PatientId = pe.PatientId
WHERE
	p.IsActive = 1
	AND pe.HideOnDashboard = 0
	AND pe.IsActive = 1
	AND
		((
		patprac.FollowUpDate IS NULL
		AND
		(
			(pe.PatientExamResultId IS NULL AND dbo.GetTimezoneAdjustedDate (pe.ExamDate, pl.TimeZoneOffset) < /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())) AND (pe.RecordsDate IS NULL OR (pe.RecordsDate IS NOT NULL AND dbo.GetTimezoneAdjustedDate (pe.RecordsDate, pl.TimeZoneOffset) < /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())))))
			OR
			(ISNULL(pt.PatientTreatmentStatusId, 1000) < 4 AND ISNULL(CAST(pt.StartDate AS DATE), '1/1/1900') < /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())))
		))
		OR
		(
			patprac.FollowUpDate IS NULL
			AND
			pe.Patientexamresultid = 3
			AND 
			(NOT EXISTS (Select PatientExamId from PatientExam pe2 WITH(NOLOCK) where pe2.PatientId = pe.PatientId and pe2.ExamDate > pe.ExamDate))
		)
		OR
		((ISNULL(pt.PatientTreatmentStatusId, 0) < 4 OR ISNULL(pe.PatientExamResultId, 0) = 0) AND dbo.GetTimezoneAdjustedDate (ISNULL(pe.RecordsDate, pe.ExamDate), pl.TimeZoneOffset) > /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())) AND UtvPolicies.Total > 0)
		OR
		(ISNULL(pt.PatientTreatmentStatusId, 4) = 4 AND ISNULL(UtvPolicies.TotalAr, 0) > 0)
		OR
		(ISNULL(pt.PatientTreatmentStatusId, 4) = 4 AND ISNULL(UtvPolicies.Total, 0) > 0 AND ISNULL(SignedContract.SignedOn, /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))) < ISNULL(UtvPolicies.LastCreatedOn, /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))))
	)

UNION ALL

(
SELECT DISTINCT
	GETDATE() AS AsOfDate
	, 'Pending' AS ExamFilterType
    , NULL AS ICS_Link
    , 'https://portal.orthofi.com/Patient/Detail/'+CAST(pe.PatientId AS VARCHAR(8))+'#tab=nledger' AS PatientLink
	, pe.ExamTypeId
	, '' AS ExamType
	, 0 AS GuardianInsuranceCount
	, 0 AS PatientInsuranceCount
	, pe.PatientExamId
	, pe.PatientFormsStatusId
	, pe.PatientId
	, p.LastName + ', ' + p.FirstName AS Patient
	, pe.ExamDate
	, pe.InsuranceMaxAvailable
	, pe.RecordsDate
	, pl.PracticeId
	, pe.PracticeLocationId
	, '' AS PracticeName
	, pl.City as 'PracticeLocation'
	, pt.ContractId
	, pt.PatientTreatmentStatusId
	, -1 AS SelectedGuardianId
	, pe.PatientExamResultId
	, pt.StartDate
	, -1 AS PaymentPlanId
	, pe.IsHipaaFormComplete
	, pe.IsPatientFormComplete
	, pe.IsInsuranceFormComplete
	, pe.IsMedicalFormComplete
	, pe.IsResponsiblePartyFormComplete
	, CAST(0 AS BIT) AS IsStartSmilingAtHome
	, LEFT(psup.FirstName, 1) + '.' + LEFT(psup.LastName, 1) + '.' AS TreatmentCoordinator
	, CAST(0 AS BIT) AS ModuleAccess
	, '' AS InsuranceVerificationStatus
	, p.DateOfBirth
	, pl.FormsEffectiveDate
	, p.PrimaryGuardianId
	, gprimaryup.FirstName + ' ' + gprimaryup.LastName AS PrimaryContact
	, p.FinancialGuardianId
	, '' AS FinancialContact
	, patprac.FollowUpDate
	, GETDATE() AS MedicalHistoryLastCompletedOn
	, CAST(0 AS BIT) AS IsFirstExam
	, NULL AS EstimatedAppliancePlacementDate
	, CAST(0 AS BIT) AS IsFinancialContactSsnEntered
	, CAST(0 AS BIT) AS IsOrthoFiSubmittingInsurance
	, CAST(CASE WHEN pl.FormsEffectiveDate > pe.ExamDate THEN 1 ELSE 0 END AS BIT) AS IsPreOrthoFi
	, CAST(0 AS BIT) AS HasFutureExam
	, pl.TimeZoneOffset
	, -1 as InsuranceClaimId
	,-1 as InsuranceFormSubmissionId
	--,null as ContinuationSubmissionEligibilityDate
	,-1 as RemainingFrequencyId
	, '' AS Username
	, patprac.PatientPendingReasonId
	, patprac.PatientPendingReasonOther
	, ppr.Name AS PatientPendingReason
	, per.Name AS PatientExamResult
	, null as IsAutomaticPaymentDistribution
	, CAST(0 AS BIT) AS HasPausedInsurance
	, CAST(0 AS BIT) AS IsTerminated
	, 0 AS DHMOCount
	, '' AS NavLogoUrl
	, -1 AS InsurancePolicyPatientEligibilityId
	, 0.00 AS EstimatedAR
	, '' AS NoBenefitReason
FROM
	(
		SELECT pe2.PracticeLocationId, MAX(pe2.PatientExamId) AS MostRecentId 
		FROM PatientExam pe2 WITH(NOLOCK)
		WHERE IsActive = 1
		GROUP BY PatientId, pe2.PracticeLocationId
	) MostRecentPatientExam
	INNER JOIN PatientExam pe WITH(NOLOCK) ON MostRecentPatientExam.MostRecentId = pe.PatientExamId AND MostRecentPatientExam.PracticeLocationId = pe.PracticeLocationId
	INNER JOIN Patient p WITH(NOLOCK) ON pe.PatientId = p.PatientId
	INNER JOIN PracticeLocation pl WITH(NOLOCK) ON pe.PracticeLocationId = pl.PracticeLocationId 
	INNER JOIN PatientPractice patprac WITH(NOLOCK) ON patprac.PracticeId = pl.PracticeId AND patprac.PatientId = p.PatientId
	INNER JOIN PracticeStaff ps WITH(NOLOCK) ON pe.TreatmentCoordinatorId = ps.PracticeStaffId
	INNER JOIN UserProfile psup WITH(NOLOCK) ON ps.UserId = psup.UserId
	LEFT JOIN TreatmentContract pt WITH(NOLOCK) ON pe.PatientExamId = pt.PatientExamId
	LEFT JOIN Guardian gprimary WITH(NOLOCK) ON p.PrimaryGuardianId = gprimary.GuardianId
	LEFT JOIN UserProfile gprimaryup WITH(NOLOCK) ON gprimary.UserId = gprimaryup.UserId
	LEFT JOIN PatientPendingReason ppr WITH(NOLOCK) ON patprac.PatientPendingReasonId = ppr.PatientPendingReasonId
	LEFT JOIN PatientExamResult per WITH(NOLOCK) ON pe.PatientExamResultId = per.PatientExamResultId
WHERE
	p.IsActive = 1
	AND CAST(patprac.FollowUpDate AS DATE) <= /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))
UNION
SELECT DISTINCT
	GETDATE() AS AsOfDate
	,'Pending' AS ExamFilterType
    , NULL AS ICS_Link
    , NULL AS PatientLink
	, 0 AS ExamTypeId
	, '' AS ExamType
	, 0 AS GuardianInsuranceCount
	, 0 AS PatientInsuranceCount
	, 0 AS PatientExamId
	, 0 AS PatientFormsStatusId
	, patprac.PatientId
	, p.LastName + ', ' + p.FirstName AS Patient
	, GETDATE() AS ExamDate
	, 0 AS InsuranceMaxAvailable
	, null AS RecordsDate
	, patprac.PracticeId
	, pl.PracticeLocationId
	, '' AS PracticeName
	, pl.City as 'PracticeLocation'
	, 0 AS ContractId
	, 0 AS PatientTreatmentStatusId
	, -1 AS SelectedGuardianId
	, 0 AS PatientExamResultId
	, GETDATE() AS StartDate
	, -1 AS PaymentPlanId
	, CAST(0 AS BIT) AS IsHipaaFormComplete
	, CAST(0 AS BIT) AS IsPatientFormComplete
	, CAST(0 AS BIT) AS IsInsuranceFormComplete
	, CAST(0 AS BIT) AS IsMedicalFormComplete
	, CAST(0 AS BIT) AS IsResponsiblePartyFormComplete
	, CAST(0 AS BIT) AS IsStartSmilingAtHome
	, '' AS TreatmentCoordinator
	, CAST(0 AS BIT) AS ModuleAccess
	, '' AS InsuranceVerificationStatus
	, p.DateOfBirth
	, pl.FormsEffectiveDate
	, p.PrimaryGuardianId
	, gprimaryup.FirstName + ' ' + gprimaryup.LastName AS PrimaryContact
	, p.FinancialGuardianId
	, '' AS FinancialContact
	, patprac.FollowUpDate
	, GETDATE() AS MedicalHistoryLastCompletedOn
	, CAST(0 AS BIT) AS IsFirstExam
	, NULL AS EstimatedAppliancePlacementDate
	, CAST(0 AS BIT) AS IsFinancialContactSsnEntered
	, CAST(0 AS BIT) AS IsOrthoFiSubmittingInsurance
	, CAST(CASE WHEN pl.FormsEffectiveDate > pe.ExamDate THEN 1 ELSE 0 END AS BIT) AS IsPreOrthoFi
	, CAST(0 AS BIT) AS HasFutureExam
	, pl.TimeZoneOffset
	, -1 as InsuranceClaimId
	,-1 as InsuranceFormSubmissionId
	--,null as ContinuationSubmissionEligibilityDate
	,-1 as RemainingFrequencyId
	, '' AS Username
	, patprac.PatientPendingReasonId
	, patprac.PatientPendingReasonOther
	, '' AS PatientPendingReason
	, '' AS PatientExamResult
	, null as IsAutomaticPaymentDistribution
	, CAST(0 AS BIT) AS HasPausedInsurance
	, CAST(0 AS BIT) AS IsTerminated
	, 0 AS DHMOCount
	, '' AS NavLogoUrl
	, -1 AS InsurancePolicyPatientEligibilityId
	, 0.00 AS EstimatedAR
	, '' AS NoBenefitReason
FROM
	PatientPractice patprac
	INNER JOIN Patient p on p.PatientId = patprac.PatientId
	INNER JOIN PracticeLocationPatient plp on plp.PatientId = patprac.PatientId
	INNER JOIN PracticeLocation pl on pl.PracticeLocationId = plp.PracticeLocationId
	INNER JOIN Guardian gprimary on gprimary.GuardianId = p.PrimaryGuardianId
	INNER JOIN UserProfile gprimaryup on gprimary.UserId = gprimaryup.UserId
	LEFT JOIN PatientExam pe ON pe.PatientId = patprac.PatientId
WHERE
	patprac.FollowUpDate IS NOT NULL
	AND pe.PatientExamId IS NULL
	AND CAST(patprac.FollowUpDate AS DATE) <= /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))
)

UNION ALL
		
SELECT 
	GETDATE() AS AsOfDate
	, 'AtHome' AS ExamFilterType
    , NULL AS ICS_Link
    , 'https://portal.orthofi.com/Patient/Detail/'+CAST(pe.PatientId AS VARCHAR(8))+'#tab=nledger' AS PatientLink
	, pe.ExamTypeId
	, et.Name AS ExamType
	, ISNULL(GuardianInsuranceCount.InsuranceCount, 0) AS GuardianInsuranceCount
	, ISNULL(PatientInsuranceCount.InsuranceCount, 0) AS PatientInsuranceCount
	, pe.PatientExamId
	, pe.PatientFormsStatusId
	, pe.PatientId
	, p.LastName + ', ' + p.FirstName AS Patient
	, pe.ExamDate
	, pe.InsuranceMaxAvailable
	, pe.RecordsDate
	, pl.PracticeId
	, pe.PracticeLocationId
	, prac.Name as 'PracticeName'
	, pl.City as 'PracticeLocation'
	, pt.ContractId
	, pt.PatientTreatmentStatusId
	, t.SelectedGuardianId
	, pe.PatientExamResultId
	, pt.StartDate
	, PendingDownPayments.PaymentPlanId
	, pe.IsHipaaFormComplete
	, pe.IsPatientFormComplete
	, pe.IsInsuranceFormComplete
	, pe.IsMedicalFormComplete
	, pe.IsResponsiblePartyFormComplete
	, CAST(ISNULL(pt.SelectedAtHome, 0) AS BIT) AS IsStartSmilingAtHome
	, LEFT(psup.FirstName, 1) + '.' + LEFT(psup.LastName, 1) + '.' AS TreatmentCoordinator
	, CAST(CASE WHEN pla.ApplicationModuleId IS NULL THEN 0 ELSE 1 END AS BIT) AS ModuleAccess
	, CASE WHEN ivs.Name IS NULL THEN '' ELSE ivs.NAME END AS InsuranceVerificationStatus
	, p.DateOfBirth
	, pl.FormsEffectiveDate
	, p.PrimaryGuardianId
	, gprimaryup.FirstName + ' ' + gprimaryup.LastName AS PrimaryContact
	, p.FinancialGuardianId
	, gfinancialup.FirstName + ' ' + gfinancialup.LastName AS FinancialContact
	, patprac.FollowUpDate
	, LastMedicalHistoryForm.MedicalHistoryLastCompletedOn
	, CAST(CASE WHEN ISNULL(ExamCounts.ExamCount, 1) > 1 THEN 0 ELSE 1 END AS BIT) AS IsFirstExam
	, NULL AS EstimatedAppliancePlacementDate
	, CAST(CASE WHEN LEN(gfinancial.SSN) > 0 THEN 1 ELSE 0 END AS BIT) AS IsFinancialContactSsnEntered
	, CAST(CASE WHEN pl.SimplifiedPricingEffectiveDate < t.createdon THEN 1 ELSE 0 END AS BIT) AS IsOrthoFiSubmittingInsurance
	, CAST(CASE WHEN pl.FormsEffectiveDate > pe.ExamDate THEN 1 ELSE 0 END AS BIT) AS IsPreOrthoFi
	, CAST(0 AS BIT) AS HasFutureExam
	, pl.TimeZoneOffset
	, -1 as InsuranceClaimId
	,-1 as InsuranceFormSubmissionId
	--,null as ContinuationSubmissionEligibilityDate
	,-1 as RemainingFrequencyId
	, ISNULL(ahgup.username, gprimaryup.username) AS Username
	, patprac.PatientPendingReasonId
	, patprac.PatientPendingReasonOther
	, ppr.Name AS PatientPendingReason
	, per.Name AS PatientExamResult
	,null as IsAutomaticPaymentDistribution
	, CAST(CASE WHEN ISNULL(PatientInsuranceCount.PausedCount, 0) > 0 THEN 1 ELSE 0 END AS BIT) HasPausedInsurance
	, CAST(0 AS BIT) AS IsTerminated
	, ISNULL(dhmo.DHMOCount, 0) AS DHMOCount
	, prac.NavLogoUrl
	, -1 AS InsurancePolicyPatientEligibilityId
	, 0.00 AS EstimatedAR
	, RIGHT(nbr.NBR_NAME, LEN(nbr.NBR_NAME) - 2) AS NoBenefitReason
FROM
	PatientExam pe WITH(NOLOCK) 
	INNER JOIN ExamType et WITH(NOLOCK) ON pe.ExamTypeId = et.ExamTypeId
	INNER JOIN Patient p WITH(NOLOCK) ON pe.PatientId = p.PatientId
	INNER JOIN PracticeLocation pl WITH(NOLOCK) ON pe.PracticeLocationId = pl.PracticeLocationId
	INNER JOIN PatientPractice patprac WITH(NOLOCK) ON patprac.PracticeId = pl.PracticeId AND patprac.PatientId = p.PatientId
	INNER JOIN Practice prac WITH(NOLOCK) ON pl.PracticeId = prac.PracticeId
	INNER JOIN PracticeStaff ps WITH(NOLOCK) ON pe.TreatmentCoordinatorId = ps.PracticeStaffId
	INNER JOIN UserProfile psup WITH(NOLOCK) ON ps.UserId = psup.UserId
	LEFT JOIN TreatmentContract pt WITH(NOLOCK) ON pe.PatientExamId = pt.PatientExamId
	LEFT JOIN dbo.PatientTreatmentOption pto WITH(NOLOCK) ON pt.SelectedPatientTreatmentOptionId = pto.PatientTreatmentOptionId
	LEFT JOIN Contract t WITH(NOLOCK) ON t.ContractId = pt.ContractId
	LEFT JOIN (SELECT bpp.PaymentPlanId, bpp.ContractId
				FROM PaymentPlan bpp WITH(NOLOCK)
					INNER JOIN TreatmentPaymentPlan pp WITH(NOLOCK) ON pp.PaymentPlanId = bpp.PaymentPlanId
					INNER JOIN Invoices i WITH(NOLOCK) ON pp.PaymentPlanId = i.PaymentPlanId AND i.InvoiceTypeId = 1 AND i.InvoiceClassId = 2 AND (i.InvoiceStatusId = 1 OR i.InvoiceStatusId = 6)
				WHERE
					bpp.PaymentPlanStatusId = 2) PendingDownPayments ON pt.ContractId = PendingDownPayments.ContractId
	LEFT JOIN (SELECT COUNT(1) AS InsuranceCount, SUM(CASE WHEN ippe.InsuranceVerificationStatusId = 8 THEN 1 ELSE 0 END) PausedCount, ippee.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam ippee WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) on ippee.InsurancePolicyPatientEligibilityId = ippe.InsurancePolicyPatientEligibilityId
				GROUP BY ippee.PatientExamId) AS GuardianInsuranceCount ON pe.PatientExamId = GuardianInsuranceCount.PatientExamId
	LEFT JOIN (SELECT COUNT(1) AS InsuranceCount, SUM(CASE WHEN ippe.InsuranceVerificationStatusId = 8 THEN 1 ELSE 0 END) PausedCount, ippee.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam ippee WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) on ippee.InsurancePolicyPatientEligibilityId = ippe.InsurancePolicyPatientEligibilityId
				WHERE (ippe.InsurancePlanPriorityId <> 5 OR ippe.InsurancePlanPriorityId IS NULL)
				GROUP BY ippee.PatientExamId) AS PatientInsuranceCount ON pe.PatientExamId = PatientInsuranceCount.PatientExamId
	LEFT JOIN dbo.PracticeLocationApplicationModule pla WITH(NOLOCK) ON (pe.PracticeLocationId = pla.PracticeLocationId AND pla.ApplicationModuleId IN (12) AND pl.InsuranceSubmissionEffectiveDate IS NOT NULL AND ISNULL(pe.RecordsDate, pe.ExamDate) >= pl.InsuranceSubmissionEffectiveDate)
	LEFT JOIN dbo.InsuranceSummary insum WITH(NOLOCK) ON pe.PatientExamId = insum.PatientExamId
	LEFT JOIN dbo.InsuranceVerificationStatus ivs WITH(NOLOCK) ON insum.InsuranceVerificationStatusId = ivs.InsuranceVerificationStatusId
	LEFT JOIN Guardian gprimary WITH(NOLOCK) ON p.PrimaryGuardianId = gprimary.GuardianId
	LEFT JOIN UserProfile gprimaryup WITH(NOLOCK) ON gprimary.UserId = gprimaryup.UserId
	LEFT JOIN Guardian gfinancial WITH(NOLOCK) ON p.FinancialGuardianId = gfinancial.GuardianId
	LEFT JOIN UserProfile gfinancialup WITH(NOLOCK) ON gfinancial.UserId = gfinancialup.UserId
	LEFT JOIN (SELECT pe2.PatientId, MAX(pemh.UpdatedOn) AS MedicalHistoryLastCompletedOn
				FROM PatientExamMedicalHistory pemh WITH(NOLOCK)
					INNER JOIN PatientExam pe2 WITH(NOLOCK) ON pemh.PatientExamId = pe2.PatientExamId
				GROUP BY
					pe2.PatientId) AS LastMedicalHistoryForm ON pe.PatientId = LastMedicalHistoryForm.PatientId
	LEFT JOIN Guardian accountHoldingGuardian WITH(NOLOCK) ON gprimary.accountHoldingGuardianId = accountHoldingGuardian.GuardianId
	LEFT JOIN UserProfile ahgup WITH(NOLOCK) ON accountHoldingGuardian.UserId = ahgup.UserId
	LEFT JOIN PatientPendingReason ppr WITH(NOLOCK) ON patprac.PatientPendingReasonId = ppr.PatientPendingReasonId
	LEFT JOIN PatientExamResult per WITH(NOLOCK) ON pe.PatientExamResultId = per.PatientExamResultId
	INNER JOIN (SELECT pe2.PatientId, COUNT(1) AS ExamCount
				FROM PatientExam pe2 WITH(NOLOCK)
				GROUP BY pe2.PatientId) AS ExamCounts ON p.PatientId = ExamCounts.PatientId
	LEFT JOIN (SELECT COUNT(1) AS DHMOCount, eligExam.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam eligExam WITH(NOLOCK)
					INNER JOIN InsurancePolicyPatientEligibility elig WITH(NOLOCK) ON elig.InsurancePolicyPatientEligibilityId = eligExam.InsurancePolicyPatientEligibilityId
					INNER JOIN InsurancePolicyPatient patient WITH(NOLOCK) ON patient.InsurancePolicyPatientId = elig.InsurancePolicyPatientId
					INNER JOIN InsurancePolicy policy WITH(NOLOCK) ON policy.InsurancePolicyId = patient.InsurancePolicyId
					LEFT JOIN InsuranceGroup ig WITH(NOLOCK) ON policy.InsuranceGroupId = ig.InsuranceGroupId
				WHERE ig.InsuranceNetworkTypeId = 2 AND (elig.InsuranceVerificationStatusID <> 5 OR elig.InsuranceVerificationStatusID IS NULL) AND policy.IsTerminated = 0
				GROUP BY eligExam.PatientExamId) AS dhmo ON pe.PatientExamId = dhmo.PatientExamId	
	LEFT JOIN (SELECT 
				ipp.PatientId
				, STUFF((
					SELECT DISTINCT ' | ' + nbr2.Name
					FROM NoBenefitReason nbr2 WITH(NOLOCK)
					INNER JOIN InsurancePolicyPatientEligibility ippe2 WITH(NOLOCK) ON ippe2.NoBenefitReasonId = nbr2.NoBenefitReasonId
					INNER JOIN InsurancePolicyPatient ipp2 WITH(NOLOCK) ON ipp2.InsurancePolicyPatientId = ippe2.InsurancePolicyPatientId
					WHERE ipp.PatientId = ipp2.PatientId
					FOR XML PATH('')
				),1,1,'') AS NBR_NAME
				FROM NoBenefitReason nbr WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) ON ippe.NoBenefitReasonId = nbr.NoBenefitReasonId
				INNER JOIN InsurancePolicyPatient ipp WITH(NOLOCK) ON ipp.InsurancePolicyPatientId = ippe.InsurancePolicyPatientId) nbr ON nbr.PatientId = pe.PatientId
WHERE
	(
		pt.SelectedAtHome = 1
		AND pt.PatientTreatmentStatusId IS NOT NULL
		AND pt.PatientTreatmentStatusId < 4
		AND pt.StartDate IS NULL
		AND p.IsActive = 1
		AND pe.IsActive = 1
	) OR (
		pt.SignAtHomeStatusId = 1
		AND pt.PatientTreatmentStatusId = 4
		AND pt.SelectedAtHome = 1 
		AND pto.IsApplianceDateVerified = 0
	)
			
UNION ALL

(  
SELECT DISTINCT
	 GETDATE() AS AsOfDate
	, 'InsuranceVerification' AS ExamFilterType
    , 'https://portal.orthofi.com/InsuranceClaim/ClaimSummary/' + CAST(c.ContractId AS VARCHAR(8)) + '/#/summary/' + CAST(ic.InsuranceClaimId AS VARCHAR(8)) AS ICS_Link
    , 'https://portal.orthofi.com/Patient/Detail/'+CAST(c.PatientId AS VARCHAR(8))+'#tab=nledger' AS PatientLink
	, -1 AS ExamTypeId
	, 'Misc Charge' AS ExamType
	, 0 AS GuardianInsuranceCount
	, 0 AS PatientInsuranceCount
	, c.ContractId * -1 AS PatientExamId
	, -1 AS PatientFormsStatusId
	, c.PatientId AS PatientId
	, p.LastName + ', ' + p.FirstName AS Patient
	, c.CreatedOn AS ExamDate
	, ip.InsuranceMaxAvailable
	, NULL AS RecordsDate
	, pl.PracticeId
	, c.PracticeLocationId
	, prac.Name AS 'PracticeName'
	, pl.City AS 'PracticeLocation'
	, c.ContractId
	, -1 AS PatientTreatmentStatusId
	, c.SelectedGuardianId
	, -1 AS PatientExamResultId
	, c.CreatedOn AS StartDate
	, -1 AS PaymentPlanId
	, CAST(1 AS BIT) AS IsHipaaFormComplete
	, CAST(1 AS BIT) AS IsPatientFormComplete
	, CAST(1 AS BIT) AS IsInsuranceFormComplete
	, CAST(0 AS BIT) AS IsMedicalFormComplete
	, CAST(1 AS BIT) AS IsResponsiblePartyFormComplete
	, CAST(0 AS BIT) AS IsStartSmilingAtHome
	, '' AS TreatmentCoordinator
	, CAST(0 AS BIT) AS ModuleAccess
	, '' AS InsuranceVerificationStatus
	, p.DateOfBirth
	, pl.FormsEffectiveDate
	, p.PrimaryGuardianId
	, gprimaryup.FirstName + ' ' + gprimaryup.LastName AS PrimaryContact
	, p.FinancialGuardianId
	, '' AS FinancialContact
	, patprac.FollowUpDate
	, NULL AS MedicalHistoryLastCompletedOn
	, CAST(0 AS BIT) AS IsFirstExam
	, c.CreatedOn AS EstimatedAppliancePlacementDate
	, CAST(1 AS BIT) AS IsFinancialContactSsnEntered
	, CAST(1 AS BIT) AS IsOrthoFiSubmittingInsurance
	, CAST(0 AS BIT) AS IsPreOrthoFi
	, CAST(0 AS BIT) AS HasFutureExam
	, pl.TimeZoneOffset
	, ic.InsuranceClaimId
	, -1 AS InsuranceFormSubmissionId
	--, NULL AS ContinuationSubmissionEligibilityDate
	, ip.RemainingFrequencyId
	, '' AS UserName
	, -1 AS PatientPendingReasonId
	, '' AS PatientPendingReasonOther
	, '' AS PatientPendingReason
	, '' AS PatientExamResult
	, ip.IsAutomaticPaymentDistribution
	, CAST(0 AS BIT) AS HasPausedInsurance
	, ISNULL(ip.IsTerminated, CAST(0 AS BIT)) AS IsTerminated
	, 0 AS DHMOCount
	, prac.NavLogoUrl
	, ippe.InsurancePolicyPatientEligibilityId
	, ic.EstimatedAR
	, '' AS NoBenefitReason

	FROM
		AdHocContract ac WITH (NOLOCK)
		INNER JOIN [Contract] c WITH (NOLOCK) ON c.contractid = ac.contractid
		INNER JOIN Patient p WITH (NOLOCK) ON p.patientid = c.patientid
		INNER JOIN Guardian g WITH (NOLOCK) ON g.guardianid = p.primaryguardianid
		INNER JOIN UserProfile gprimaryup WITH (NOLOCK) ON gprimaryup.userid = g.userid
		INNER JOIN PracticeLocation pl WITH (NOLOCK) ON pl.practicelocationid = c.practicelocationid
		INNER JOIN PatientPractice patprac WITH(NOLOCK) ON patprac.PracticeId = pl.PracticeId AND patprac.PatientId = p.PatientId
		INNER JOIN Practice prac WITH (NOLOCK) ON prac.practiceid = pl.practiceid
		INNER JOIN InsuranceClaim ic WITH (NOLOCK) ON ic.ContractId = c.ContractId
		INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK)  ON ic.InsurancePolicyPatientEligibilityId = ippe.InsurancePolicyPatientEligibilityId
		INNER JOIN InsurancePolicyPatient ipp WITH (NOLOCK) ON ipp.insurancepolicypatientid = ippe.insurancepolicypatientid
		INNER JOIN InsurancePolicy ip WITH (NOLOCK) ON ip.insurancepolicyid = ipp.insurancepolicyid
		LEFT JOIN InsuranceClaimSubmissionForm ifs WITH (NOLOCK) ON ifs.insuranceclaimid = ic.insuranceclaimid AND ifs.submissionstatusid <> 14
	WHERE
		ip.IsActive = 1 AND
		ac.AdHocContractStatusId = 2 AND
		ic.SubmissionStatusId NOT IN (14,16)
		AND (ifs.insuranceclaimsubmissionformid IS NULL OR ifs.SubmissionStatusId = 1)
UNION
SELECT DISTINCT
	GETDATE() AS AsOfDate
	, 'InsuranceVerification' AS ExamFilterType
    , 'https://portal.orthofi.com/InsuranceClaim/ClaimSummary/' + CAST(t.ContractId AS VARCHAR(8)) + '/#/summary/' + CAST(ip.InsuranceClaimId AS VARCHAR(8)) AS ICS_Link
    , 'https://portal.orthofi.com/Patient/Detail/'+CAST(pe.PatientId AS VARCHAR(8))+'#tab=nledger' AS PatientLink
	, pe.ExamTypeId
	, et.Name AS ExamType
	, ISNULL(GuardianInsuranceCount.InsuranceCount, 0) AS GuardianInsuranceCount
	, ISNULL(PatientInsuranceCount.InsuranceCount, 0) AS PatientInsuranceCount
	, pe.PatientExamId
	, pe.PatientFormsStatusId
	, pe.PatientId
	, p.LastName + ', ' + p.FirstName AS Patient
	, pe.ExamDate
	, pe.InsuranceMaxAvailable
	, pe.RecordsDate
	, pl.PracticeId
	, pe.PracticeLocationId
	, prac.Name AS 'PracticeName'
	, pl.City AS 'PracticeLocation'
	, pt.ContractId
	, pt.PatientTreatmentStatusId
	, t.SelectedGuardianId
	, pe.PatientExamResultId
	, pt.StartDate
	, PendingDownPayments.PaymentPlanId
	, pe.IsHipaaFormComplete
	, pe.IsPatientFormComplete
	, pe.IsInsuranceFormComplete
	, pe.IsMedicalFormComplete
	, pe.IsResponsiblePartyFormComplete
	, CAST(ISNULL(pt.SelectedAtHome, 0) AS BIT) AS IsStartSmilingAtHome
	, LEFT(psup.FirstName, 1) + '.' + LEFT(psup.LastName, 1) + '.' AS TreatmentCoordinator
	, CAST(CASE WHEN pla.ApplicationModuleId IS NULL THEN 0 ELSE 1 END AS BIT) AS ModuleAccess
	, CASE 
		WHEN 
		(
			ISNULL(bpp.EstimatedInsurance, 0) = 0) AND pto.IsAppliancedateVerified = 0 
			AND 
			(
				ip.InsurancePolicyPatientEligibilityId IS NULL 
				OR
				(
					pla.ApplicationModuleId IS NOT NULL
					AND ip.IsManagedByOrthoFi = 0 
					AND insum.InsuranceVerificationStatusId = 3 
					AND ippe4.InsuranceVerificationStatusId = 3 
					AND ippe4.NoBenefitReasonId > 0 
					AND ic.SubmissionStatusId = 1 
					AND t.EstimatedInsurance = 0
					AND ippe4.IsOverridden = 0
				)
			)
			THEN 'No Insurance' 
		ELSE 
			CASE 
				WHEN ivs.Name IS NULL THEN '' 
				ELSE ivs.NAME 
			END 
	END AS InsuranceVerificationStatus
	, p.DateOfBirth
	, pl.FormsEffectiveDate
	, p.PrimaryGuardianId
	, gprimaryup.FirstName + ' ' + gprimaryup.LastName AS PrimaryContact
	, p.FinancialGuardianId
	, gfinancialup.FirstName + ' ' + gfinancialup.LastName AS FinancialContact
	, patprac.FollowUpDate
	, LastMedicalHistoryForm.MedicalHistoryLastCompletedOn
	, CAST(CASE WHEN ISNULL(ExamCounts.ExamCount, 1) > 1 THEN 0 ELSE 1 END AS BIT) AS IsFirstExam
	, pto.ApplianceDate AS EstimatedAppliancePlacementDate
	, CAST(CASE WHEN LEN(gfinancial.SSN) > 0 THEN 1 ELSE 0 END AS BIT) AS IsFinancialContactSsnEntered
	, CAST(CASE 
		WHEN pl.SimplifiedPricingEffectiveDate < t.createdon 
		AND ippe4.InsurancePlanPriorityId IN (1,2) 
		AND insum.InsuranceVerificationStatusId IN (3,4,6,10) 
		--AND insum.InsuranceMaxAvailable > 0 
		THEN 1 
		ELSE 0 END AS BIT) AS IsOrthoFiSubmittingInsurance
	, CAST(CASE WHEN pl.FormsEffectiveDate > pe.ExamDate THEN 1 ELSE 0 END AS BIT) AS IsPreOrthoFi
	, CAST(0 AS BIT) AS HasFutureExam
	, pl.TimeZoneOffset
	, ip.InsuranceClaimId
	, -1 AS InsuranceFormSubmissionId
	--, NULL AS ContinuationSubmissionEligibilityDate
	, ip.RemainingFrequencyId
	, ISNULL(ahgup.username, gprimaryup.username) AS Username
	, patprac.PatientPendingReasonId
	, patprac.PatientPendingReasonOther
	, ppr.Name AS PatientPendingReason
	, per.Name AS PatientExamResult
	, ip.IsAutomaticPaymentDistribution
	, CAST(CASE WHEN ISNULL(PatientInsuranceCount.PausedCount, 0) > 0 THEN 1 ELSE 0 END AS BIT) HasPausedInsurance
	, ISNULL(ip.IsTerminated, CAST(0 AS BIT)) AS IsTerminated
	, 0 AS DHMOCount
	, prac.NavLogoUrl
	, ippee2.InsurancePolicyPatientEligibilityId
	, ic.EstimatedAR
	, '' AS NoBenefitReason
			
FROM	
	PatientExam pe WITH(NOLOCK) 
	LEFT JOIN InsurancePolicyPatientEligibilityExam ippee2 WITH(NOLOCK) ON pe.PatientExamId = ippee2.PatientExamId
	LEFT JOIN InsurancePolicyPatientEligibility ippe4 WITH(NOLOCK) ON ippee2.InsurancePolicyPatientEligibilityId = ippe4.InsurancePolicyPatientEligibilityId
	LEFT JOIN InsuranceClaim ic WITH(NOLOCK) on ic.InsurancePolicyPatientEligibilityId = ippee2.InsurancePolicyPatientEligibilityId
	INNER JOIN ExamType et WITH(NOLOCK) ON pe.ExamTypeId = et.ExamTypeId
	INNER JOIN Patient p WITH(NOLOCK) ON pe.PatientId = p.PatientId
	INNER JOIN PracticeLocation pl WITH(NOLOCK) ON pe.PracticeLocationId = pl.PracticeLocationId
	INNER JOIN PatientPractice patprac WITH(NOLOCK) ON patprac.PracticeId = pl.PracticeId AND patprac.PatientId = p.PatientId
	INNER JOIN Practice prac WITH(NOLOCK) ON pl.PracticeId = prac.PracticeId
	INNER JOIN PracticeStaff ps WITH(NOLOCK) ON pe.TreatmentCoordinatorId = ps.PracticeStaffId
	INNER JOIN UserProfile psup WITH(NOLOCK) ON ps.UserId = psup.UserId
	INNER JOIN TreatmentContract pt WITH(NOLOCK) ON pe.PatientExamId = pt.PatientExamId
	INNER JOIN Contract t WITH(NOLOCK) ON t.ContractId = pt.ContractId
	INNER JOIN dbo.PatientTreatmentOption pto WITH(NOLOCK) ON pt.SelectedPatientTreatmentOptionId = pto.PatientTreatmentOptionId
	LEFT JOIN Expense cex WITH(NOLOCK) ON pt.ContractId = pt.ContractId
	LEFT JOIN dbo.TreatmentContractExpense pte ON cex.ExpenseId = pte.ExpenseId
	INNER JOIN dbo.PaymentPlan bpp WITH(NOLOCK) ON pt.ContractId = bpp.ContractId
	INNER JOIN dbo.TreatmentPaymentPlan pp WITH(NOLOCK) ON pp.PaymentPlanId = bpp.PaymentPlanId
	LEFT JOIN (SELECT pp.PaymentPlanId, bpp.ContractId
				FROM PaymentPlan bpp WITH(NOLOCK)
					INNER JOIN TreatmentPaymentPlan pp WITH(NOLOCK) ON pp.PaymentPlanId = bpp.PaymentPlanId
					INNER JOIN Invoices i WITH(NOLOCK) ON pp.PaymentPlanId = i.PaymentPlanId AND i.InvoiceTypeId = 1 AND i.InvoiceClassId = 2 AND (i.InvoiceStatusId = 1 OR i.InvoiceStatusId = 6)
				WHERE
					bpp.PaymentPlanStatusId = 2) PendingDownPayments ON pt.ContractId = PendingDownPayments.ContractId
	LEFT JOIN (SELECT COUNT(1) AS InsuranceCount, SUM(CASE WHEN ippe.InsuranceVerificationStatusId = 8 THEN 1 ELSE 0 END) PausedCount, ippee.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam ippee WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) ON ippee.InsurancePolicyPatientEligibilityId = ippe.InsurancePolicyPatientEligibilityId
				GROUP BY ippee.PatientExamId) AS GuardianInsuranceCount ON pe.PatientExamId = GuardianInsuranceCount.PatientExamId
	LEFT JOIN (SELECT COUNT(1) AS InsuranceCount, SUM(CASE WHEN ippe.InsuranceVerificationStatusId = 8 THEN 1 ELSE 0 END) PausedCount, ippee.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam ippee WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) ON ippee.InsurancePolicyPatientEligibilityId = ippe.InsurancePolicyPatientEligibilityId
				WHERE (ippe.InsurancePlanPriorityId <> 5 OR ippe.InsurancePlanPriorityId IS NULL)
				GROUP BY ippee.PatientExamId) AS PatientInsuranceCount ON pe.PatientExamId = PatientInsuranceCount.PatientExamId
	LEFT JOIN Guardian g2 WITH(NOLOCK) ON p.PrimaryGuardianId = g2.GuardianId
	LEFT JOIN (SELECT DISTINCT peg1.PatientExamId, 
					SUBSTRING((SELECT ',' + CAST(peg2.GuardianId AS VARCHAR) AS [text()]
					FROM PatientExamGuardian peg2 WITH(NOLOCK)
							INNER JOIN Guardian g WITH(NOLOCK) ON peg2.GuardianId = g.GuardianId
							INNER JOIN UserProfile up WITH(NOLOCK) ON g.UserId = up.UserId
					WHERE peg1.PatientExamId = peg2.PatientExamId
					ORDER BY peg1.PatientExamId
					FOR XML PATH ('')),2, 1000) [Guardians]
				FROM PatientExamGuardian peg1 WITH(NOLOCK)) AS PatientExamGuardianInfo ON pe.PatientExamId = PatientExamGuardianInfo.PatientExamId
	LEFT JOIN (SELECT DISTINCT gp1.PatientId, 
					SUBSTRING((SELECT ',' + (CAST(up.UserId AS VARCHAR) + '|' + CAST(up.HasRegistered AS VARCHAR) + '|' + ISNULL(up.SecurityQuestion, '') + '|' + up.FirstName + '|' + up.LastName + '|' + CAST(g.GuardianId AS VARCHAR) + '|' + CASE WHEN g.CreditCheckAuthorization = 1 AND g.SSN IS NOT NULL AND LEN(g.SSN) > 0 THEN 'True' ELSE 'False' END + '|' + up.UserName) AS [text()]
					FROM GuardianPatient gp2 WITH(NOLOCK)
							INNER JOIN Guardian g WITH(NOLOCK) ON gp2.GuardianId = g.GuardianId
							INNER JOIN UserProfile up WITH(NOLOCK) ON g.UserId = up.UserId
					WHERE gp1.PatientId = gp2.PatientId
					ORDER BY gp1.PatientId
					FOR XML PATH ('')),2, 1000) [Guardians]
				FROM GuardianPatient gp1 WITH(NOLOCK)) AS PatientGuardianInfo ON pe.PatientId = PatientGuardianInfo.PatientId
	LEFT JOIN dbo.PracticeLocationApplicationModule pla WITH(NOLOCK) ON (pe.PracticeLocationId = pla.PracticeLocationId AND pla.ApplicationModuleId IN (12) AND pl.InsuranceSubmissionEffectiveDate IS NOT NULL AND ISNULL(pe.RecordsDate, pe.ExamDate) >= pl.InsuranceSubmissionEffectiveDate)
	LEFT JOIN dbo.PracticeLocationApplicationModule plaapp WITH(NOLOCK) ON (pe.PracticeLocationId = plaapp.PracticeLocationId AND plaapp.ApplicationModuleId IN (70))	
	LEFT JOIN dbo.InsuranceSummary insum WITH(NOLOCK) ON pe.PatientExamId = insum.PatientExamId
	LEFT JOIN dbo.InsuranceVerificationStatus ivs WITH(NOLOCK) ON insum.InsuranceVerificationStatusId = ivs.InsuranceVerificationStatusId
	LEFT JOIN 
	(
		SELECT 
			ippee2.PatientExamId, 
			ippee2.InsurancePolicyPatientEligibilityId,
			ic2.IsManagedByOrthoFi,
			ic2.SubmissionStatusId,
			ippe2.InsurancePlanPriorityId,
			ippe2.InsuranceVerificationStatusId,
			ip2.RemainingFrequencyId,
			ip2.IsAutomaticPaymentDistribution,
			ip2.IsTerminated,
			ic2.InsuranceClaimId
		FROM PatientExam pe300 WITH(NOLOCK)
		LEFT JOIN InsurancePolicyPatientEligibilityExam ippee2 WITH(NOLOCK) ON ippee2.PatientExamId = pe300.PatientExamId
		LEFT JOIN InsurancePolicyPatientEligibility ippe2 WITH(NOLOCK) ON ippe2.InsurancePolicyPatientEligibilityId = ippee2.InsurancePolicyPatientEligibilityId
		LEFT JOIN InsuranceClaim ic2 WITH(NOLOCK) ON ic2.InsurancePolicyPatientEligibilityId = ippe2.insurancepolicypatienteligibilityid
		LEFT JOIN InsurancePolicyPatient ipp2 WITH(NOLOCK) ON ipp2.insurancepolicypatientid = ippe2.insurancepolicypatientid
		LEFT JOIN insurancepolicy ip2 WITH(NOLOCK) ON ip2.insurancepolicyid = ipp2.insurancepolicyid
		WHERE
		(
			ippee2.PatientExamId IS NULL -- Pre-OrthoFi Patients with no policy record
		)
		OR
		(
			ippee2.PatientExamId IS NOT NULL
			AND ippee2.InsurancePolicyPatientEligibilityId = 
			(
				SELECT TOP 1 ippee3.InsurancePolicyPatientEligibilityId 
					FROM InsurancePolicyPatientEligibilityExam ippee3 WITH(NOLOCK)
					INNER JOIN InsurancePolicyPatientEligibility ippe3 WITH(NOLOCK) ON ippee3.InsurancePolicyPatientEligibilityId = ippe3.InsurancePolicyPatientEligibilityId
					INNER JOIN InsurancePolicyPatient ipp3 WITH(NOLOCK) ON ipp3.insurancepolicypatientid = ippe3.insurancepolicypatientid
					INNER JOIN insurancepolicy ip3 WITH(NOLOCK) ON ip3.insurancepolicyid = ipp3.insurancepolicyid
					WHERE ippee3.PatientExamId = pe300.PatientExamId  
					AND ippe3.InsurancePlanPriorityId = 1 
					AND ippe3.InsuranceVerificationStatusId IN (3,4,6,10)
				ORDER BY ip3.IsTerminated ASC, ip3.SubscriberPlanEffectiveDateEnd DESC
		)
		)
	) AS ip ON ip.PatientExamId = pe.PatientExamId
	LEFT JOIN Guardian gprimary WITH(NOLOCK) ON p.PrimaryGuardianId = gprimary.GuardianId
	LEFT JOIN UserProfile gprimaryup WITH(NOLOCK) ON gprimary.UserId = gprimaryup.UserId
	LEFT JOIN Guardian gfinancial WITH(NOLOCK) ON p.FinancialGuardianId = gfinancial.GuardianId
	LEFT JOIN UserProfile gfinancialup WITH(NOLOCK) ON gfinancial.UserId = gfinancialup.UserId
	LEFT JOIN (SELECT pe2.PatientId, MAX(pemh.UpdatedOn) AS MedicalHistoryLastCompletedOn
				FROM PatientExamMedicalHistory pemh WITH(NOLOCK)
					INNER JOIN PatientExam pe2 WITH(NOLOCK) ON pemh.PatientExamId = pe2.PatientExamId
				GROUP BY
					pe2.PatientId) AS LastMedicalHistoryForm ON pe.PatientId = LastMedicalHistoryForm.PatientId
	LEFT JOIN Guardian accountHoldingGuardian WITH(NOLOCK) ON gprimary.accountHoldingGuardianId = accountHoldingGuardian.GuardianId
	LEFT JOIN UserProfile ahgup WITH(NOLOCK) ON accountHoldingGuardian.UserId = ahgup.UserId
	LEFT JOIN PatientPendingReason ppr WITH(NOLOCK) ON patprac.PatientPendingReasonId = ppr.PatientPendingReasonId
	LEFT JOIN PatientExamResult per WITH(NOLOCK) ON pe.PatientExamResultId = per.PatientExamResultId
	INNER JOIN (SELECT pe2.PatientId, COUNT(1) AS ExamCount
				FROM PatientExam pe2 WITH(NOLOCK)
				GROUP BY pe2.PatientId) AS ExamCounts ON p.PatientId = ExamCounts.PatientId

WHERE
	PaymentPlanStatusId = 2
	AND p.IsActive = 1
	AND pe.IsActive = 1
	AND (t.IsInsuranceVerified = 0 OR ic.SubmissionStatusId = 1)
	AND (pto.ApplianceDate <= GETUTCDATE() OR pto.ApplianceDate IS NULL)
	AND pl.InsuranceSubmissionEffectiveDate IS NOT NULL
	AND (pl.InsuranceSubmissionEffectiveDate <= pt.StartDate OR pt.StartDate IS NULL)
	AND 
	(
		(
			-- There is no insurance policy, it's a pre-orthofi patient:
			ip.InsurancePolicyPatientEligibilityId IS NULL
			AND (insum.InsuranceVerificationStatusId = 3 OR insum.InsuranceVerificationStatusId IS NULL)
			AND (ISNULL(bpp.EstimatedInsurance, 0) > 0)
		)
		OR
		(
			-- There is no insurance policy and we need to show to verify appliance placement date
			plaapp.ApplicationModuleId IS NOT NULL -- Has Application Date Verification Module
			AND (ISNULL(bpp.EstimatedInsurance, 0) = 0)
			AND pto.IsApplianceDateVerified = 0
			AND pto.ApplianceDate < GETUTCDATE()
			AND 
			(
				ip.InsurancePolicyPatientEligibilityId IS NULL
				OR
				(
					(
						ip.IsManagedByOrthoFi = 0 
						AND insum.InsuranceVerificationStatusId = 3 
						AND ippe4.InsuranceVerificationStatusId = 3 
						AND ippe4.NoBenefitReasonId > 0 
						AND ic.SubmissionStatusId = 1 
						AND t.EstimatedInsurance = 0
						AND ippe4.IsOverridden = 0
					)
				)
			)
		)
		OR
		(
			ip.InsurancePolicyPatientEligibilityId IS NOT NULL
			AND 
			(
				ippe4.InsurancePlanPriorityId = 1 OR (ippe4.InsurancePlanPriorityId = 2 AND ippe4.InsuranceVerificationStatusId IN (6,10) AND ip.InsuranceVerificationStatusId = 3)
			)
			AND (ip.SubmissionStatusId = 1 OR ip.SubmissionStatusId IS NULL)
			AND 
			(
				(
					ip.IsManagedByOrthoFi = 1 AND insum.InsuranceVerificationStatusId IN (3,6,10) AND pt.StartDate >= /*@PatientStartCutoffDate*/CAST('2019' AS DATETIME) 
				)
				OR (ip.IsManagedByOrthoFi = 1 AND ip.InsuranceVerificationStatusId = 3 AND ippe4.InsurancePlanPriorityId = 2 AND ippe4.InsuranceVerificationStatusId NOT IN (6,10))
				OR (ip.IsManagedByOrthoFi = 0 AND insum.InsuranceVerificationStatusId IN (4,6,10) AND ippe4.InsuranceVerificationStatusId NOT IN (3,5) AND pt.StartDate >= /*@PatientStartCutoffDate*/CAST('2019' AS DATETIME))
				OR (ip.IsManagedByOrthoFi = 0 AND insum.InsuranceVerificationStatusId IN (4,6,10) AND ippe4.InsurancePlanPriorityId = 2 AND pt.StartDate >= /*@PatientStartCutoffDate*/CAST('2019' AS DATETIME))
				OR (ip.IsManagedByOrthoFi = 0 AND insum.InsuranceVerificationStatusId = 3 AND ippe4.InsuranceVerificationStatusId = 3 AND ippe4.IsOverridden = 1 AND ic.SubmissionStatusId = 1)
				OR (ip.IsManagedByOrthoFi IS NULL AND ippe4.InsuranceVerificationStatusId IN(4, 6, 10) AND ippe4.InsuranceExamPriorityId = 5)
			)
		)
	)
UNION
SELECT DISTINCT
	GETDATE() AS AsOfDate
	, 'InsuranceVerification' AS ExamFilterType
    , 'https://portal.orthofi.com/InsuranceClaim/ClaimSummary/' + CAST(t.ContractId AS VARCHAR(8)) + '/#/summary/' + CAST(ip.InsuranceClaimId AS VARCHAR(8)) AS ICS_Link
    , 'https://portal.orthofi.com/Patient/Detail/'+CAST(pe.PatientId AS VARCHAR(8))+'#tab=nledger' AS PatientLink
	, pe.ExamTypeId
	, et.Name AS ExamType
	, ISNULL(GuardianInsuranceCount.InsuranceCount, 0) AS GuardianInsuranceCount
	, ISNULL(PatientInsuranceCount.InsuranceCount, 0) AS PatientInsuranceCount
	, pe.PatientExamId
	, pe.PatientFormsStatusId
	, pe.PatientId
	, p.LastName + ', ' + p.FirstName AS Patient
	, pe.ExamDate
	, pe.InsuranceMaxAvailable
	, pe.RecordsDate
	, pl.PracticeId
	, pe.PracticeLocationId
	, prac.Name AS 'PracticeName'
	, pl.City AS 'PracticeLocation'
	, pt.ContractId
	, pt.PatientTreatmentStatusId
	, t.SelectedGuardianId
	, pe.PatientExamResultId
	, pt.StartDate
	, PendingDownPayments.PaymentPlanId
	, pe.IsHipaaFormComplete
	, pe.IsPatientFormComplete
	, pe.IsInsuranceFormComplete
	, pe.IsMedicalFormComplete
	, pe.IsResponsiblePartyFormComplete
	, CAST(ISNULL(pt.SelectedAtHome, 0) AS BIT) AS IsStartSmilingAtHome
	, LEFT(psup.FirstName, 1) + '.' + LEFT(psup.LastName, 1) + '.' AS TreatmentCoordinator
	, CAST(CASE WHEN pla.ApplicationModuleId IS NULL THEN 0 ELSE 1 END AS BIT) AS ModuleAccess
	, CASE WHEN ivs.Name IS NULL THEN '' ELSE ivs.NAME END AS InsuranceVerificationStatus
	, p.DateOfBirth
	, pl.FormsEffectiveDate
	, p.PrimaryGuardianId
	, gprimaryup.FirstName + ' ' + gprimaryup.LastName AS PrimaryContact
	, p.FinancialGuardianId
	, gfinancialup.FirstName + ' ' + gfinancialup.LastName AS FinancialContact
	, patprac.FollowUpDate
	, LastMedicalHistoryForm.MedicalHistoryLastCompletedOn
	, CAST(CASE WHEN ISNULL(ExamCounts.ExamCount, 1) > 1 THEN 0 ELSE 1 END AS BIT) AS IsFirstExam
	, pto.ApplianceDate AS EstimatedAppliancePlacementDate
	, CAST(CASE WHEN LEN(gfinancial.SSN) > 0 THEN 1 ELSE 0 END AS BIT) AS IsFinancialContactSsnEntered
	, CAST(CASE 
		WHEN pl.SimplifiedPricingEffectiveDate < t.createdon 
		AND ippe4.InsurancePlanPriorityId IN (1,2) 
		AND insum.InsuranceVerificationStatusId IN (3,4,6,10) 
		--AND insum.InsuranceMaxAvailable > 0 
		THEN 1 
		ELSE 0 END AS BIT) AS IsOrthoFiSubmittingInsurance
	, CAST(CASE WHEN pl.FormsEffectiveDate > pe.ExamDate THEN 1 ELSE 0 END AS BIT) AS IsPreOrthoFi
	, CAST(0 AS BIT) AS HasFutureExam
	, pl.TimeZoneOffset
	, ip.InsuranceClaimId
	, ifs.InsuranceClaimSubmissionFormId
	--, ifs.ContinuationSubmissionEligibilityDate
	, ip.RemainingFrequencyId
	, ISNULL(ahgup.username, gprimaryup.username) AS Username
	, patprac.PatientPendingReasonId
	, patprac.PatientPendingReasonOther
	, ppr.Name AS PatientPendingReason
	, per.Name AS PatientExamResult
	, ip.IsAutomaticPaymentDistribution
	, CAST(CASE WHEN ISNULL(PatientInsuranceCount.PausedCount, 0) > 0 THEN 1 ELSE 0 END AS BIT) HasPausedInsurance
	, ISNULL(ip.IsTerminated, CAST(0 AS BIT)) AS IsTerminated
	, 0 AS DHMOCount
	, prac.NavLogoUrl
	, ippee2.InsurancePolicyPatientEligibilityId
	, ic.EstimatedAR
	, '' AS NoBenefitReason
			
FROM	
	PatientExam pe WITH(NOLOCK) 
	LEFT JOIN InsurancePolicyPatientEligibilityExam ippee2 WITH(NOLOCK) ON pe.PatientExamId = ippee2.PatientExamId
	LEFT JOIN InsurancePolicyPatientEligibility ippe4 WITH(NOLOCK) ON ippee2.InsurancePolicyPatientEligibilityId = ippe4.InsurancePolicyPatientEligibilityId
	LEFT JOIN InsuranceClaim ic WITH(NOLOCK) on ic.InsurancePolicyPatientEligibilityId = ippee2.InsurancePolicyPatientEligibilityId
	INNER JOIN ExamType et WITH(NOLOCK) ON pe.ExamTypeId = et.ExamTypeId
	INNER JOIN Patient p WITH(NOLOCK) ON pe.PatientId = p.PatientId
	INNER JOIN PracticeLocation pl WITH(NOLOCK) ON pe.PracticeLocationId = pl.PracticeLocationId
	INNER JOIN PatientPractice patprac WITH(NOLOCK) ON patprac.PracticeId = pl.PracticeId AND patprac.PatientId = p.PatientId
	INNER JOIN PracticeLocationApplicationModule continuationModule ON continuationModule.PracticeLocationId = pl.PracticeLocationId AND continuationModule.ApplicationModuleId = 21
	INNER JOIN Practice prac WITH(NOLOCK) ON pl.PracticeId = prac.PracticeId
	INNER JOIN PracticeStaff ps WITH(NOLOCK) ON pe.TreatmentCoordinatorId = ps.PracticeStaffId
	INNER JOIN UserProfile psup WITH(NOLOCK) ON ps.UserId = psup.UserId
	INNER JOIN TreatmentContract pt WITH(NOLOCK) ON pe.PatientExamId = pt.PatientExamId
	INNER JOIN Contract t WITH(NOLOCK) ON t.ContractId = pt.ContractId
	INNER JOIN dbo.PatientTreatmentOption pto WITH(NOLOCK) ON pt.SelectedPatientTreatmentOptionId = pto.PatientTreatmentOptionId
	LEFT JOIN Expense cex WITH(NOLOCK) ON pt.COntractId = cex.ContractId
	LEFT JOIN dbo.TreatmentContractExpense pte ON cex.ExpenseId = pt.ContractId
	INNER JOIN dbo.PaymentPlan bpp WITH(NOLOCK) ON pt.ContractId = bpp.ContractId
	INNER JOIN dbo.TreatmentPaymentPlan pp WITH(NOLOCK) ON bpp.PaymentPlanId = pp.PaymentPlanId
	LEFT JOIN (SELECT pp.PaymentPlanId, bpp.ContractId
				FROM PaymentPlan bpp WITH(NOLOCK)
					INNER JOIN TreatmentPaymentPlan pp WITH(NOLOCK) ON pp.PaymentPlanId = bpp.PaymentPlanId
					INNER JOIN Invoices i WITH(NOLOCK) ON pp.PaymentPlanId = i.PaymentPlanId AND i.InvoiceTypeId = 1 AND i.InvoiceClassId = 2 AND (i.InvoiceStatusId = 1 OR i.InvoiceStatusId = 6)
				WHERE
					bpp.PaymentPlanStatusId = 2) PendingDownPayments ON pt.ContractId = PendingDownPayments.ContractId
	LEFT JOIN (SELECT COUNT(1) AS InsuranceCount, SUM(CASE WHEN ippe.InsuranceVerificationStatusId = 8 THEN 1 ELSE 0 END) PausedCount, ippee.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam ippee WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) ON ippee.InsurancePolicyPatientEligibilityId = ippe.InsurancePolicyPatientEligibilityId
				GROUP BY ippee.PatientExamId) AS GuardianInsuranceCount ON pe.PatientExamId = GuardianInsuranceCount.PatientExamId
	LEFT JOIN (SELECT COUNT(1) AS InsuranceCount, SUM(CASE WHEN ippe.InsuranceVerificationStatusId = 8 THEN 1 ELSE 0 END) PausedCount, ippee.PatientExamId
				FROM InsurancePolicyPatientEligibilityExam ippee WITH(NOLOCK)
				INNER JOIN InsurancePolicyPatientEligibility ippe WITH(NOLOCK) ON ippee.InsurancePolicyPatientEligibilityId = ippe.InsurancePolicyPatientEligibilityId
				WHERE (ippe.InsurancePlanPriorityId <> 5 OR ippe.InsurancePlanPriorityId IS NULL)
				GROUP BY ippee.PatientExamId) AS PatientInsuranceCount ON pe.PatientExamId = PatientInsuranceCount.PatientExamId
	LEFT JOIN Guardian g2 WITH(NOLOCK) ON p.PrimaryGuardianId = g2.GuardianId
	LEFT JOIN (SELECT DISTINCT peg1.PatientExamId, 
					SUBSTRING((SELECT ',' + CAST(peg2.GuardianId AS VARCHAR) AS [text()]
					FROM PatientExamGuardian peg2 WITH(NOLOCK)
							INNER JOIN Guardian g WITH(NOLOCK) ON peg2.GuardianId = g.GuardianId
							INNER JOIN UserProfile up WITH(NOLOCK) ON g.UserId = up.UserId
					WHERE peg1.PatientExamId = peg2.PatientExamId
					ORDER BY peg1.PatientExamId 
					FOR XML PATH ('')),2, 1000) [Guardians]
				FROM PatientExamGuardian peg1 WITH(NOLOCK)) AS PatientExamGuardianInfo ON pe.PatientExamId = PatientExamGuardianInfo.PatientExamId
	LEFT JOIN (SELECT DISTINCT gp1.PatientId, 
					SUBSTRING((SELECT ',' + (CAST(up.UserId AS VARCHAR) + '|' + CAST(up.HasRegistered AS VARCHAR) + '|' + ISNULL(up.SecurityQuestion, '') + '|' + up.FirstName + '|' + up.LastName + '|' + CAST(g.GuardianId AS VARCHAR) + '|' + CASE WHEN g.CreditCheckAuthorization = 1 AND g.SSN IS NOT NULL AND LEN(g.SSN) > 0 THEN 'True' ELSE 'False' END + '|' + up.UserName) AS [text()]
					FROM GuardianPatient gp2 WITH(NOLOCK)
							INNER JOIN Guardian g WITH(NOLOCK) ON gp2.GuardianId = g.GuardianId
							INNER JOIN UserProfile up WITH(NOLOCK) ON g.UserId = up.UserId
					WHERE gp1.PatientId = gp2.PatientId
					ORDER BY gp1.PatientId
					FOR XML PATH ('')),2, 1000) [Guardians]
				FROM GuardianPatient gp1 WITH(NOLOCK)) AS PatientGuardianInfo ON pe.PatientId = PatientGuardianInfo.PatientId
	LEFT JOIN dbo.PracticeLocationApplicationModule pla WITH(NOLOCK) ON (pe.PracticeLocationId = pla.PracticeLocationId AND pla.ApplicationModuleId IN (12) AND pl.InsuranceSubmissionEffectiveDate IS NOT NULL AND ISNULL(pe.RecordsDate, pe.ExamDate) >= pl.InsuranceSubmissionEffectiveDate)
	LEFT JOIN dbo.InsuranceSummary insum WITH(NOLOCK) ON pe.PatientExamId = insum.PatientExamId
	LEFT JOIN dbo.InsuranceVerificationStatus ivs WITH(NOLOCK) ON insum.InsuranceVerificationStatusId = ivs.InsuranceVerificationStatusId
	LEFT JOIN 
	(
		SELECT 
			ippee2.PatientExamId, 
			ippee2.InsurancePolicyPatientEligibilityId,
			ic2.IsManagedByOrthoFi,
			ic2.SubmissionStatusId,
			ippe2.InsurancePlanPriorityId,
			ippe2.InsuranceVerificationStatusId,
			ip2.RemainingFrequencyId,
			ip2.IsAutomaticPaymentDistribution,
			ip2.IsTerminated,
			ic2.InsuranceClaimId
		FROM PatientExam pe300 WITH(NOLOCK)
		LEFT JOIN InsurancePolicyPatientEligibilityExam ippee2 WITH(NOLOCK) ON ippee2.PatientExamId = pe300.PatientExamId
		LEFT JOIN InsurancePolicyPatientEligibility ippe2 WITH(NOLOCK) ON ippe2.InsurancePolicyPatientEligibilityId = ippee2.InsurancePolicyPatientEligibilityId
		LEFT JOIN InsuranceClaim ic2 WITH(NOLOCK) ON ic2.InsurancePolicyPatientEligibilityId = ippe2.insurancepolicypatienteligibilityid
		LEFT JOIN InsurancePolicyPatient ipp2 WITH(NOLOCK) ON ipp2.insurancepolicypatientid = ippe2.insurancepolicypatientid
		LEFT JOIN insurancepolicy ip2 WITH(NOLOCK) ON ip2.insurancepolicyid = ipp2.insurancepolicyid
		WHERE
		(
			ippee2.PatientExamId IS NULL -- Pre-OrthoFi Patients with no policy record
		)
		OR
		(
			ippee2.PatientExamId IS NOT NULL
			AND ippee2.InsurancePolicyPatientEligibilityId = 
			(
				SELECT TOP 1 ippee3.InsurancePolicyPatientEligibilityId 
					FROM InsurancePolicyPatientEligibilityExam ippee3 WITH(NOLOCK)
					INNER JOIN InsurancePolicyPatientEligibility ippe3 WITH(NOLOCK) ON ippee3.InsurancePolicyPatientEligibilityId = ippe3.InsurancePolicyPatientEligibilityId
					INNER JOIN InsurancePolicyPatient ipp3 WITH(NOLOCK) ON ipp3.insurancepolicypatientid = ippe3.insurancepolicypatientid
					INNER JOIN insurancepolicy ip3 WITH(NOLOCK) ON ip3.insurancepolicyid = ipp3.insurancepolicyid
					WHERE ippee3.PatientExamId = pe300.PatientExamId  
					AND ippe3.InsurancePlanPriorityId = 1 
					AND ippe3.InsuranceVerificationStatusId IN (3,4,6,10)
				ORDER BY ip3.IsTerminated ASC, ip3.SubscriberPlanEffectiveDateEnd DESC
		)
		)
	) AS ip ON ip.PatientExamId = pe.PatientExamId
	LEFT JOIN Guardian gprimary WITH(NOLOCK) ON p.PrimaryGuardianId = gprimary.GuardianId
	LEFT JOIN UserProfile gprimaryup WITH(NOLOCK) ON gprimary.UserId = gprimaryup.UserId
	LEFT JOIN Guardian gfinancial WITH(NOLOCK) ON p.FinancialGuardianId = gfinancial.GuardianId
	LEFT JOIN UserProfile gfinancialup WITH(NOLOCK) ON gfinancial.UserId = gfinancialup.UserId
	LEFT JOIN (SELECT pe2.PatientId, MAX(pemh.UpdatedOn) AS MedicalHistoryLastCompletedOn
				FROM PatientExamMedicalHistory pemh WITH(NOLOCK)
					INNER JOIN PatientExam pe2 WITH(NOLOCK) ON pemh.PatientExamId = pe2.PatientExamId
				GROUP BY
					pe2.PatientId) AS LastMedicalHistoryForm ON pe.PatientId = LastMedicalHistoryForm.PatientId
	LEFT JOIN Guardian accountHoldingGuardian WITH(NOLOCK) ON gprimary.accountHoldingGuardianId = accountHoldingGuardian.GuardianId
	LEFT JOIN UserProfile ahgup WITH(NOLOCK) ON accountHoldingGuardian.UserId = ahgup.UserId
	LEFT JOIN PatientPendingReason ppr WITH(NOLOCK) ON patprac.PatientPendingReasonId = ppr.PatientPendingReasonId
	LEFT JOIN PatientExamResult per WITH(NOLOCK) ON pe.PatientExamResultId = per.PatientExamResultId
	INNER JOIN (SELECT pe2.PatientId, COUNT(1) AS ExamCount
				FROM PatientExam pe2 WITH(NOLOCK)
				GROUP BY pe2.PatientId) AS ExamCounts ON p.PatientId = ExamCounts.PatientId
	INNER JOIN InsuranceClaimSubmissionForm ifs WITH(NOLOCK) ON ifs.insuranceclaimid = ip.insuranceclaimid
WHERE
	PaymentPlanStatusId = 2
	AND (ippe4.InsurancePlanPriorityId = 1 OR (ippe4.InsurancePlanPriorityId = 2 AND ippe4.InsuranceVerificationStatusId IN (6,10) AND ip.InsuranceVerificationStatusId = 3))
	AND (pto.ApplianceDate <= GETUTCDATE() OR pto.ApplianceDate IS NULL)
	AND p.IsActive = 1
	AND pe.IsActive = 1
	AND ifs.ContinuationSubmissionEligibilityDate <= GETUTCDATE()
	AND ifs.SubmissionStatusId = 1
	AND ((ip.IsManagedByOrthoFi = 1 AND insum.InsuranceVerificationStatusId = 3) 
	OR (ip.IsManagedByOrthoFi = 1 AND ip.InsuranceVerificationStatusId = 3 AND ippe4.InsurancePlanPriorityId = 2 AND ippe4.InsuranceVerificationStatusId NOT IN (6,10))
	OR (ip.IsManagedByOrthoFi = 0 AND insum.InsuranceVerificationStatusId IN (4,6,10) AND ippe4.InsuranceVerificationStatusId IN (4,6,10) AND pt.StartDate >= DATEADD(MONTH, -18, /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))))
	OR (ip.IsManagedByOrthoFi = 0 AND insum.InsuranceVerificationStatusId IN (4,6,10) AND ippe4.InsurancePlanPriorityId = 2 AND pt.StartDate >= DATEADD(MONTH, -18, /*@Today*/DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())) ))
	OR (ip.IsManagedByOrthoFi = 0 AND insum.InsuranceVerificationStatusId = 3 AND ippe4.InsuranceVerificationStatusId = 3 AND ippe4.IsOverridden = 1 AND ic.SubmissionStatusId = 1))
)


