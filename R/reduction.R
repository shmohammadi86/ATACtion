reduce_peaks_using_ACTION <- function(ace, reduced_dim = 50, max_iter = 5, assay_name = "bin_counts", reduction_slot = "ACTION", seed = 0, SVD_algorithm = 0) {
    ace <- as(ace, "ACTIONetExperiment")
	if(! (assay_name %in% names(assays(ace))) & ("counts" %in% names(assays(ace)))) {
		B = as(assays(ace)[["counts"]], 'sparseMatrix')
		B@x = rep(1, length(B@x))
		assays(ace)[[assay_name]] = B
	}

  if(is.null(rownames(ace))){
    GR = SummarizedExperiment::rowRanges(ace)
    rnames = paste(as.character(seqnames(GR)), start(GR), end(GR), sep = "_")
    rownames(ace) = rnames
  }

	ace = reduce.ace(ace, reduced_dim = reduced_dim, max_iter = max_iter, assay_name = assay_name, reduction_slot = reduction_slot, seed = seed, SVD_algorithm = 0)

	return(ace)
}


reduce_peaks_using_chromVAR <- function(ace, reduced_dim = 50, max_iter = 100, assay_name = "bin_counts", reduction_slot = "chromVAR", seed = 0, SVD_algorithm = 0, thread_no = 1) {
	library(chromVAR)
	library(chromVARmotifs)
	library(motifmatchr)
	library(Matrix)
	library(BiocParallel)

    ace <- as(ace, "ACTIONetExperiment")
	if(! (assay_name %in% names(assays(ace))) & ("counts" %in% names(assays(ace)))) {
		B = as(assays(ace)[["counts"]], 'sparseMatrix')
		B@x = rep(1, length(B@x))
		assays(ace)[[assay_name]] = B
	}

  if(is.null(rownames(ace))){
    GR = SummarizedExperiment::rowRanges(ace)
    rnames = paste(as.character(seqnames(GR)), start(GR), end(GR), sep = "_")
    rownames(ace) = rnames
  }

    if (is.null(colnames(ace))) {
        colnames(ace) = sapply(1:ncol(ace), function(i) sprintf("Cell%d",
            i))
    } else {
        cn = colnames(ace)
        if (length(unique(cn)) < length(cn)) {
            colnames(ace) = make.names(cn, unique = TRUE)
        }
    }

    for (n in names(assays(ace))) {
        rownames(assays(ace)[[n]]) = rownames(ace)
        colnames(assays(ace)[[n]]) = colnames(ace)
    }

	filtered.peaks = which(ACTIONet::fast_row_sums(assays(ace)[[assay_name]]) == 0)
	if(length(filtered.peaks) > 0)
		ace = ace[-filtered.peaks, ]

	if(thread_no == 1)
		register(SerialParam())
	else
		register(MulticoreParam(thread_no, progressbar = TRUE))

	GR = SummarizedExperiment::rowRanges(ace)
	reference_genome = tolower(genome(GR))
	if(length(reference_genome) > 0)
		reference_genome = reference_genome[[1]]
	else {
	  print("Unknown genome");
	  return()
	}

	if( !("motif_matches" %in% names(rowData(ace))) ) {
	  ace = add_motif_matched_to_ATACtion(ace)
	}


	if(reference_genome == 'hg19' || reference_genome == 'grch37') {
		library(BSgenome.Hsapiens.UCSC.hg19)
		ace <- addGCBias(ace, genome = BSgenome.Hsapiens.UCSC.hg19)
	}
	else if(reference_genome == 'hg38' || reference_genome == 'grch38') {
		library(BSgenome.Hsapiens.UCSC.hg38)
		ace <- addGCBias(ace, genome = BSgenome.Hsapiens.UCSC.hg38)

	}
	else if(reference_genome == 'mm10') {
		library(BSgenome.Mmusculus.UCSC.mm10)
		ace <- addGCBias(ace, genome = BSgenome.Mmusculus.UCSC.mm10)
	}
	else if(reference_genome == 'mm9') {
		library(BSgenome.Mmusculus.UCSC.mm9)
		ace <- addGCBias(ace, genome = BSgenome.Mmusculus.UCSC.mm9)
	}
	else {
	  R.utils::printf('Species %s not supported. Please run chromVAR manually\n', reference_genome)
	  return();
	}

	bg <- getBackgroundPeaks(object = ace)

	sce_chromVAR <- computeDeviations(object = ace, annotations = rowMaps(ace)[["motif_matches"]], background_peaks = bg)
	Z = assays(sce_chromVAR)[['z']]

	filtered.rows = which(is.na(ACTIONet::fastRowSums(sce_chromVAR@assays[['z']])))
	if(length(filtered.rows) > 0)
	Z = Z[-filtered.rows, ]

	colnames(Z) = colnames(ace)

    colMaps(ace)[[reduction_slot]] <- Matrix::t(Z)
    colMapTypes(ace)[[reduction_slot]] = "reduction"


	svd <- IRLB_SVD_full(Z, reduced_dim, max_iter, seed)
	svdDiag <- matrix(0, nrow=reduced_dim, ncol=reduced_dim)
	diag(svdDiag) <- svd$d
	Z_reduced <- as.matrix(svd$v %*% svdDiag)
	rownames(Z_reduced) <- colnames(ace)
	colnames(Z_reduced) <- paste0("Dim",seq_len(ncol(Z_reduced)))

    colMaps(ace)[[sprintf("%s_reduced", reduction_slot)]] <- Z_reduced
    colMapTypes(ace)[[sprintf("%s_reduced", reduction_slot)]] = "reduction"



	return(ace)
}


reduce_peaks_using_LSI <- function(ace, site_frequency_threshold = 0.0, logTF=FALSE, scale.factor=100000, reduced_dim = 50, max_iter = 100, assay_name = "bin_counts", reduction_slot = "LSI", seed = 0, SVD_algorithm = 0) {
    ace <- as(ace, "ACTIONetExperiment")
	if(! (assay_name %in% names(assays(ace))) & ("counts" %in% names(assays(ace)))) {
		B = as(assays(ace)[["counts"]], 'sparseMatrix')
		B@x = rep(1, length(B@x))
		assays(ace)[[assay_name]] = B
	}

  if(is.null(rownames(ace))){
    GR = SummarizedExperiment::rowRanges(ace)
    rnames = paste(as.character(seqnames(GR)), start(GR), end(GR), sep = "_")
    rownames(ace) = rnames
  }
    if (is.null(colnames(ace))) {
        colnames(ace) = sapply(1:ncol(ace), function(i) sprintf("Cell%d",
            i))
    } else {
        cn = colnames(ace)
        if (length(unique(cn)) < length(cn)) {
            colnames(ace) = make.names(cn, unique = TRUE)
        }
    }

    for (n in names(assays(ace))) {
        rownames(assays(ace)[[n]]) = rownames(ace)
        colnames(assays(ace)[[n]]) = colnames(ace)
    }

	filtered.peaks = which(ACTIONet::fast_row_sums(assays(ace)[[assay_name]]) == 0)
	if(length(filtered.peaks) > 0)
		ace = ace[-filtered.peaks, ]

	atac_matrix = assays(ace)[[assay_name]]

	if(site_frequency_threshold > 0) {
		rs = ACTIONet::fast_row_sums(atac_matrix > 0)
		threshold = ncol(atac_matrix) * site_frequency_threshold
		atac_matrix = atac_matrix[rs >= threshold,]
	}

	#Calc TF-IDF
	print("Computing TF-IDF ...")

	npeaks <- ACTIONet::fast_column_sums(atac_matrix)
	tf <- Matrix::t(Matrix::t(atac_matrix) / npeaks)
	if(logTF){
		message("Epoch: running log term frequency ...");
        tf@x = log1p(tf@x * scale.factor);
	}

	idf <- log(1+ ncol(atac_matrix) / ACTIONet::fast_row_sums(atac_matrix))

	tfidf <- as(Diagonal(n = length(idf), x = as.vector(idf)), 'sparseMatrix') %*% tf
	tfidf[is.na(tfidf)] <- 0

	#Calc SVD then LSI
	svd <- IRLB_SVD(tfidf, reduced_dim, max_iter, seed)
	svdDiag <- matrix(0, nrow=reduced_dim, ncol=reduced_dim)
	diag(svdDiag) <- svd$d
	LSI <- as.matrix(svd$v %*% svdDiag)
	rownames(LSI) <- colnames(ace)
	colnames(LSI) <- paste0("LSI",seq_len(ncol(LSI)))

    colMaps(ace)[[reduction_slot]] <- LSI
    colMapTypes(ace)[[reduction_slot]] = "reduction"

	return(ace)
}


reduce_peaks_using_LSACTION <- function(ace, scale.factor=100000, reduced_dim = 50, max_iter = 100, assay_name = "bin_counts", reduction_slot = "LSI", seed = 0, SVD_algorithm = 0) {

    ace <- as(ace, "ACTIONetExperiment")
	if(! (assay_name %in% names(assays(ace))) & ("counts" %in% names(assays(ace)))) {
		B = as(assays(ace)[["counts"]], 'sparseMatrix')
		B@x = rep(1, length(B@x))
		assays(ace)[[assay_name]] = B
	}

	filtered.peaks = which(ACTIONet::fast_row_sums(assays(ace)[[assay_name]]) == 0)
	if(length(filtered.peaks) > 0)
		ace = ace[-filtered.peaks, ]

  if(is.null(rownames(ace))){
    GR = SummarizedExperiment::rowRanges(ace)
    rnames = paste(as.character(seqnames(GR)), start(GR), end(GR), sep = "_")
    rownames(ace) = rnames
  }

	atac_matrix = assays(ace)[[assay_name]]

	npeaks <- ACTIONet::fast_column_sums(atac_matrix)
	tf <- Matrix::t(Matrix::t(atac_matrix) / npeaks)
	tf@x = log1p(tf@x * scale.factor);
	idf <- log(1+ ncol(atac_matrix) / ACTIONet::fast_row_sums(atac_matrix))

	tfidf <- as(Diagonal(n = length(idf), x = as.vector(idf)), 'sparseMatrix') %*% tf
	tfidf[is.na(tfidf)] <- 0

	assays(ace)[["tf_idf"]] = tfidf

	ace = reduce.ace(ace, reduced_dim = reduced_dim, max_iter = max_iter, assay_name = "tf_idf", reduction_slot = reduction_slot, seed = seed, SVD_algorithm = 0)

	return(ace)
}
