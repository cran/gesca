gsca.mg <- function (z0, group_var, W00, C00, B00,
			loadtype = matrix(1,1,ncol(W00)), nbt = 100, itmax = 100,
			ceps = 0.00001, moption = 0, missingvalue = NULL)
{
	#---------------------------------------
	# Last revised April 7, 2016
	# revised to compute FIT_M when all indicators are formative
	# for all missing data cases
	# moption = 0 (no missing), 1 (listwise deletion), 2 (mean substitution), 3 (least squares imputation)
	#---------------------------------------

	# listwise deletion
	if ( moption == 1 ) {
		nrow <- nrow(z0)
		row_index <- rep(1,nrow)
		for (i in 1:nrow) {
			if ( sum(which(z0[i,] == missingvalue)) > 0 ) { row_index[i] = 0 }
		}
		rindex <- which(row_index != 0)
		z0 <- z0[rindex,]
		group_var <- group_var[rindex]
	}

	# number of groups and cases per group
	nobs_tot <- nrow(z0)
	nvar <- ncol(z0)
	ng <- length(unique(group_var))
	nobs_g <- matrix(,1,ng)
	for (j in 1:ng) {
		nobs_g[,j] <- as.numeric(table(group_var))[j]
	}

	# case numbers for each group
	case_index <- matrix(,ng,2)
	kk <- 0
	for (j in 1:ng) {
		k <- kk + 1
		kk <- kk + nobs_g[j]
		case_index[j,1] = k
		case_index[j,2] = kk
	}

	# ---------------------------------------
	# model specification for a single group
	# ---------------------------------------

	nlv <- length(loadtype)		# number of latents
	ntv <- nvar + nlv			# sum of indicators and latents
	for (j in 1:nlv) {
		if ( loadtype[j] == 0 ) { C00[j,] = matrix(0,1,nvar) }
	}
	A00 <- cbind(C00,B00)

	#V001 <- matrix(0,nvar,nvar)
	#for (j in 1:nlv) {
	#	nzaj <- which(C00[j,] != 0)
	#	num_nzaj <- length(nzaj)
	#		for (i in 1:1:num_nzaj) {
	#			V001[nzaj[i],nzaj[i]] = 1
	#		}
	#}
	V001 <- diag(1,nvar)
	V00 <- cbind(V001,W00)

	# ---------------------------------------
	# model specification for all groups & initial random starts
	# ---------------------------------------
	Wi <- W00
	Ai <- A00
	windex0 <- which(W00 == 99)
	aindex0 <- which(A00 == 99)
	W0 <- matrix(0,ng*nvar,ng*nlv)
	A0 <- matrix(0,ng*nlv,ntv)
	V0 <- matrix(0,ng*nvar,ng*ntv)
	W <- W0
	A <- A0
	V <- V0
	kk <- 0
	ss <- 0
	ll <- 0
	for (j in 1:ng) {
		k <- kk + 1
		kk <- kk + nvar
		s <- ss + 1
		ss <- ss + nlv
		l <- ll + 1
		ll <- ll + ntv
		W0[k:kk,s:ss] <- W00
		Wi[windex0] <- runif(length(windex0))
		W[k:kk,s:ss] <- Wi
		A0[s:ss,] <- A00
		Ai[aindex0] <- runif(length(aindex0))
		A[s:ss,] <- Ai
		V0[k:kk,l:ll] <- V00
		V[k:kk,l:ll] <- cbind(V001,Wi)
	}
	I <- matrix(0,ntv*ng,ntv)
	kk <- 0
	for (g in 1:ng) {
	    k <- kk + 1
		kk <- kk + ntv
		I[k:kk,] <- diag(1,ntv)
	}

	# generate orthogonal projector of equality constraints
	output.constmat <- constmat(A0)
	PHT <- output.constmat$PHT
	num_nzct <- output.constmat$num_nzct
	num_const <- output.constmat$num_const

	# ---------------------------------------
	# bootstrap starts here
	# ---------------------------------------

	# number of weights, loadings and path coefficients per group
	num_nnz_W00 <- length(W00[!W00 == 0])
	num_nnz_C00 <- length(C00[!C00 == 0])
	num_nnz_B00 <- length(B00[!B00 == 0])

	vec_FIT <- matrix(0,nbt,1)
	vec_FIT_m <- matrix(0,nbt,1)
	vec_FIT_s <- matrix(0,nbt,1)
	vec_AFIT <- matrix(0,nbt,1)
	vec_GFI <- matrix(0,nbt,1)
	vec_SRMR <- matrix(0,nbt,1)

	MatW <- matrix(0,nbt,num_nnz_W00*ng)
	Matload <- matrix(0,nbt,num_nnz_C00*ng)
	Matbeta <- matrix(0,nbt,num_nnz_B00*ng)
	Matsmc <- matrix(0,nbt,num_nnz_C00*ng)
	MatcorF <- matrix(0,nbt, nlv^2*ng)

	MatTE_S <- c()
	MatID_S <- c()
	MatTE_M <- c()
	MatID_M <- c()

	for (b in 0:nbt) {

		# generate a bootstrap sample Z (when b == 0, use the original data)
		if (b == 0) {
			if (moption > 1) {
				output.bootsample.imp <- bootsample.imp(z0, case_index, nvar, nobs_g, ng, b, nobs_tot, moption, missingvalue)
				Z <- output.bootsample.imp$Z
				z0_meanimp <- output.bootsample.imp$z0_meanimp
				rawz0 <- output.bootsample.imp$rawz0
			} else {
				output.bootsample <- bootsample(z0, case_index, nvar, nobs_g, ng, b, nobs_tot)
				Z <- output.bootsample$Z
			}
		} else {
			output.bootsample <- bootsample(z0, case_index, nvar, nobs_g, ng, b, nobs_tot)
			Z <- output.bootsample$Z
		}

		# parameter estimation
		if (b == 0) {
			if (moption == 3) {
				output.als.mg.imp <- als.mg.imp(Z, rawz0, W0, A0, W, A, V, I, PHT, nvar, nlv, ng, missingvalue, itmax, ceps)
				W <- output.als.mg.imp$W
				A <- output.als.mg.imp$A
				ZZ <- output.als.mg.imp$Z
				Psi <- output.als.mg.imp$Psi
				Gamma <- output.als.mg.imp$Gamma
				f <- output.als.mg.imp$f
				it <- output.als.mg.imp$it
				imp <- output.als.mg.imp$imp
			} else {
				output.als.mg <- als.mg(Z, W0, A0, W, A, V, I, PHT, nvar, nlv, ng, itmax, ceps)
				W <- output.als.mg$W
				A <- output.als.mg$A
				Psi <- output.als.mg$Psi
				Gamma <- output.als.mg$Gamma
				f <- output.als.mg$f
				it <- output.als.mg$it
				imp <- output.als.mg$imp
			}
		} else {
			output.als.mg <- als.mg(Z, W0, A0, W, A, V, I, PHT, nvar, nlv, ng, itmax, ceps)
			W <- output.als.mg$W
			A <- output.als.mg$A
			Psi <- output.als.mg$Psi
			Gamma <- output.als.mg$Gamma
			f <- output.als.mg$f
			it <- output.als.mg$it
			imp <- output.als.mg$imp
		}

		corF <- t(Gamma) %*% Gamma 	# latent correlations across groups
		CR <- t(A[,1:nvar]) 		# loadings
		BR <- t(A[,(nvar+1):ntv]) 	# path coefficients

		DF <- nobs_tot*nvar
		npw <- length(which(W0 == 99))
		dpht <- diag(PHT)
		if ( num_nzct == 0 ) {
			cnzt <- length(which(dpht == 1))
		} else {
			cnzt <- num_const + length(which(dpht == 1))
		}
		NPAR <- cnzt + npw			# number of parameters

		# model fit measures
		Fit <- 1 - f/sum(diag(t(Psi)%*%Psi))
		dif_m <- Psi[,1:nvar] - Gamma%*%t(CR)
		dif_s <- Psi[,(nvar+1):ntv] - Gamma%*%t(BR)
		Fit_m <- 1 - sum(diag(t(dif_m)%*%dif_m))/sum(diag(t(Z)%*%Z))
		Fit_s <- 1 - sum(diag(t(dif_s)%*%dif_s))/sum(diag(t(Gamma)%*%Gamma))
		Afit <- 1 - ((1-Fit)*(DF)/(DF - NPAR))
		output.modelfit.mg <- modelfit.mg(Z, W, A, nvar, nlv, ng, case_index)
		Gfi <- output.modelfit.mg$GFI
		Srmr <- output.modelfit.mg$SRMR
		COR_RES <- output.modelfit.mg$COR_RES

		# total and indirect effects in structural & measurement models
		total_s <- matrix(0,ng*nlv,nlv)			# total effects of latents in structural model
		indirect_s <- matrix(0,ng*nlv,nlv)		# indirect effects in structural model
		total_m <- matrix(0,ng*nlv,nvar)		# total effects of latent variables on indcators in measurement model
		indirect_m <- matrix(0,ng*nlv,nvar)		# indirect effect in measurement model
		k <- kk <- 0
		for (g in 1:ng) {
			k = kk + 1
			kk = kk + nlv
			output.effects <- effects(BR[,k:kk],CR[,k:kk])
			te_s <- output.effects$te_s
			ie_s <- output.effects$ie_s
			te_m <- output.effects$te_m
			ie_m <- output.effects$ie_m
			total_s[k:kk,] <- te_s
			indirect_s[k:kk,] <- ie_s
			total_m[k:kk,] <- te_m
			indirect_m[k:kk,] <- ie_m
		}

		# original sample solution
		if ( b == 0 ) {

			if ( moption == 2 ) { z0 <- z0_meanimp
			} else if ( moption == 3 ) {
				z0 <- matrix(0,nobs_tot,nvar)
				kk <- 0
				for (g in 1:ng) {
					k <- kk + 1
					kk <- kk + nvar
					z0[case_index[g,1]:case_index[g,2],] = ZZ[case_index[g,1]:case_index[g,2],k:kk]
					# ZZ - data after LS imputation
				}
			}

			if ( it <= itmax ) {
				if ( imp <= ceps ) {
				  message(paste("The ALS algorithm converged in", it, "iterations (convergence criterion =", ceps, ")", "\n"))
				} else {
				  message(paste("The ALS algorithm failed to converge in", it, "iterations (convergence criterion =", ceps, ")", "\n"))
				}
			}

			WR <- W
			Cr <- CR
			Br <- BR
			samplesizes <- nobs_g 					# sample size per group
			NPAR
			FIT <- Fit
			FIT_M <- Fit_m
			FIT_S <- Fit_s
			AFIT <- Afit
			GFI <- Gfi
			SRMR <- Srmr
			R2 <- matrix(0,ng,nlv)
			AVE <- matrix(0,ng,nlv)
			Alpha <- matrix(0,ng,nlv)
			rho <- matrix(0,ng,nlv)      			# Dillong-Goldstein's rho (composite reliablity)
			Dimension <- matrix(0,ng,nlv)			# Dimensionality per block
			lvmean <- matrix(0,ng,nlv)
			lvvar <- matrix(0,ng,nlv)
			corr_corres <- matrix(0,ng*nvar,nvar)	# matrix with correlations in lower trigular and correlation residuals in upper triangular
			ss <- 0
			kk <- 0
			for (g in 1:ng) {
				s <- ss + 1
				ss <- ss + nlv
				k <- kk + 1
				kk <- kk + nvar
				if ( moption == 3 ) {
					z0_g <- z0_meanimp[case_index[g,1]:case_index[g,2],]
				} else {
					z0_g <- z0[case_index[g,1]:case_index[g,2],]
				}
				W_g <- W[k:kk,s:ss]
				CF_g <- corF[s:ss,s:ss]
				B <- t(BR[,s:ss])
				stdL <- CR[,s:ss]
				# j2 <- 0 # removed june 22,2016
				for (j in 1:nlv) {
					R2[g,j] <- t(B[,j,drop=FALSE])%*%CF_g[,j,drop=FALSE]
					zind <- which(W00[,j] != 0) # moved from below, june 22,2016
					nnzload <- length(zind)
					# nnzload <- length(C00[j,][!C00[j,] == 0]) # removed june 22,2016
					# j1 <- j2 + 1 # removed june 22,2016
					# j2 <- j2 + nnzload # removed june 22,2016
					if ( nnzload > 0 ) {
						sumload <- sum(stdL[zind,j]^2) # removed june 22,2016
						sumload_rho1 <- sum(stdL[zind,j])^2 # removed june 22,2016
						sumload_rho2 <- sum(1-stdL[zind,j]^2) # removed june 22,2016
						AVE[g,j] <- sumload/nnzload
						rho[g,j] <- sumload_rho1/(sumload_rho1 + sumload_rho2)
					}
					nzj = length(zind)
					if ( nzj > 1 ) {
						zsubset <- z0_g[,zind]
						Alpha[g,j] <- cronbach.alpha(zsubset)
						eigval <- svd(cor(zsubset))$d
						kr <- length(which(eigval>1))	# number of eigenvalues greater than 1
						Dimension[g,j] <- kr
					} else {
						Alpha[g,j] <- 1
					}
				}

				# calculate latent scores
				lvscore_g <- lvscore(z0_g, W_g)
				lvmean[g,] <- apply(lvscore_g,2,mean)
				lvvar[g,] <- apply(lvscore_g,2,var)
				sample_corr <- cor(z0_g)
				corr_corres[k:kk,][upper.tri(corr_corres[k:kk,], diag = FALSE)] <- COR_RES[k:kk,][upper.tri(COR_RES[k:kk,], diag = FALSE)]
				corr_corres[k:kk,][lower.tri(corr_corres[k:kk,], diag = FALSE)] <- sample_corr[lower.tri(sample_corr, diag = FALSE)]
			}

			R2
			AVE
			Alpha
			rho
			LV_MEAN <- lvmean # Means of latent variables
			LV_VAR <- lvvar
			corr_corres
			Dimension
			mW <- as.matrix(W[which(!W == 0)])
			mC <- as.matrix(CR[which(!CR == 0)])
			mB <- as.matrix(BR[which(!BR == 0)])
			mSMC <- mC^2
			mCF <- as.matrix(corF[which(!corF == 0)])
			latentcorr <- corF

			TE_S <- total_s
			ID_S <- indirect_s
			TE_M <- total_m
			ID_M <- indirect_m

		} else {	# bootstrap sample solution
			vecw <- as.matrix(W[which(!W == 0)])
			vecload <- as.matrix(CR[which(!CR == 0)])
			vecbeta <- as.matrix(BR[which(!BR == 0)])
			veccorF <- as.matrix(corF[which(!corF == 0)])

			vec_FIT[b] <- Fit
			vec_FIT_m[b] <- Fit_m
			vec_FIT_s[b] <- Fit_s
			vec_AFIT[b] <- Afit
			vec_GFI[b] <- Gfi
			vec_SRMR[b] <- Srmr

			MatW[b,] <- t(vecw)
			Matload[b,] <- t(vecload)
			Matbeta[b,] <- t(vecbeta)
			Matsmc[b,] <- t(vecload^2)
			MatcorF[b,] <- t(veccorF)

			MatTE_S <- rbind(MatTE_S,total_s[which(!total_s == 0)])
			MatID_S <- rbind(MatID_S,indirect_s[which(!indirect_s == 0)])
			MatTE_M <- rbind(MatTE_M,total_m[which(!total_m == 0)])
			MatID_M <- rbind(MatID_M,indirect_m[which(!indirect_m == 0)])
		}
	}

	# display bootstrap GSCA output
	if ( nbt > 0 ) {

	lb <- ceiling(nbt*0.025)
	ub <- ceiling(nbt*0.975)
	sortFIT <- sort(vec_FIT)
	sortFIT_m <- sort(vec_FIT_m)
	sortFIT_s <- sort(vec_FIT_s)
	sortAFIT <- sort(vec_AFIT)
	sortGFI <- sort(vec_GFI)
	sortSRMR <- sort(vec_SRMR)
	sortw <- apply(MatW,2,sort)
	sortload <- apply(Matload,2,sort)
	sortbeta <- apply(Matbeta,2,sort)
	sortsmc <- apply(Matsmc,2,sort)
	sortcorF <- apply(MatcorF,2,sort)
	sortte_s <- apply(MatTE_S,2,sort)
	sortid_s <- apply(MatID_S,2,sort)
	sortte_m <- apply(MatTE_M,2,sort)
	sortid_m <- apply(MatID_M,2,sort)

	output.gsca.mg <- list(WR = WR, CR = Cr, BR = Br, samplesizes = samplesizes, NPAR = NPAR,
						FIT = FIT, FIT_M = FIT_M, FIT_S = FIT_S, AFIT = AFIT, GFI = GFI, SRMR = SRMR,
						R2 = R2, AVE = AVE, Alpha = Alpha, rho = rho, LV_MEAN = LV_MEAN, LV_VAR = LV_VAR,
						corr_corres = corr_corres, Dimension = Dimension, latentcorr = latentcorr,
						TE_S = TE_S, ID_S = ID_S, TE_M = TE_M, ID_M = ID_M,
						mW = mW, mC = mC, mB = mB, mSMC = mSMC, mCF = mCF,
						lb = lb, ub = ub, vec_FIT = vec_FIT, vec_FIT_m = vec_FIT_m, vec_FIT_s = vec_FIT_s, vec_AFIT = vec_AFIT,
						vec_GFI = vec_GFI, vec_SRMR = vec_SRMR, MatW = MatW, Matload = Matload, Matbeta = Matbeta,
						Matsmc = Matsmc, MatcorF = MatcorF, MatTE_S = MatTE_S, MatID_S = MatID_S, MatTE_M = MatTE_M, MatID_M = MatID_M,
						sortFIT = sortFIT, sortFIT_m = sortFIT_m, sortFIT_s = sortFIT_s,
						sortAFIT = sortAFIT, sortGFI = sortGFI, sortSRMR = sortSRMR, sortw = sortw,
						sortload = sortload, sortbeta = sortbeta, sortsmc = sortsmc, sortcorF = sortcorF,
						sortte_s = sortte_s, sortid_s = sortid_s, sortte_m = sortte_m, sortid_m = sortid_m)
	output.gsca.mg

	} else {

	output.gsca.mg <- list(WR = WR, CR = Cr, BR = Br, samplesizes = samplesizes, NPAR = NPAR,
						FIT = FIT, FIT_M = FIT_M, FIT_S = FIT_S, AFIT = AFIT, GFI = GFI, SRMR = SRMR,
						R2 = R2, AVE = AVE, Alpha = Alpha, rho = rho, LV_MEAN = LV_MEAN, LV_VAR = LV_VAR,
						corr_corres = corr_corres, Dimension = Dimension, latentcorr = latentcorr,
						TE_S = TE_S, ID_S = ID_S, TE_M = TE_M, ID_M = ID_M,
						mW = mW, mC = mC, mB = mB, mSMC = mSMC, mCF = mCF)
	output.gsca.mg

	}
}
