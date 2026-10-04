package com.afitree.rizqi

// Banks/wallets listed in ThaiBankDetector but missing from the slip keyword chains in
// MainActivity / SlipDetectionService, so their saved slips were never picked up.
// Short codes (kma, uob, kkp, ghb, lhb, make) are matched only as the album name to avoid false hits inside random filenames.
internal fun detectExtraSlipBank(combinedSearch: String, lowerBucket: String): String? {
    return when {
        combinedSearch.contains("krungsri") || combinedSearch.contains("กรุงศรี") || lowerBucket == "kma" || lowerBucket == "kept" -> "กรุงศรี (KMA)"
        combinedSearch.contains("tmrw") || lowerBucket == "uob" -> "UOB TMRW"
        combinedSearch.contains("cimb") -> "CIMB Thai"
        combinedSearch.contains("kiatnakin") || lowerBucket == "kkp" || lowerBucket == "dime" -> "เกียรตินาคินภัทร (KKP)"
        combinedSearch.contains("อาคารสงเคราะห์") || lowerBucket == "ghb" -> "ธอส. (GHB)"
        combinedSearch.contains("tisco") -> "TISCO"
        combinedSearch.contains("lhbank") || combinedSearch.contains("lh bank") || lowerBucket == "lhb" -> "LH Bank"
        combinedSearch.contains("baac") || combinedSearch.contains("a-mobile") || combinedSearch.contains("ธ.ก.ส") -> "ธ.ก.ส. (BAAC)"
        combinedSearch.contains("make by kbank") || lowerBucket == "make" -> "MAKE by KBank"
        else -> null
    }
}
