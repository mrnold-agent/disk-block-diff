package main

import "testing"

func TestDiffRecordTransfersBytes(t *testing.T) {
	if diffRecordTransfersBytes("missing_on_source", 1<<30) {
		t.Fatal("missing_on_source should not count toward transfer")
	}
	if !diffRecordTransfersBytes("hash_mismatch", 1<<30) {
		t.Fatal("hash_mismatch should count toward transfer")
	}
	if !diffRecordTransfersBytes("missing_on_dest", 1<<30) {
		t.Fatal("missing_on_dest should count toward transfer")
	}
}

func TestFormatETARepairSize(t *testing.T) {
	const oneGiB = 1 << 30
	// 3 TiB @ 110 MiB/s (1 GbE) ≈ 8h
	threeTiB := int64(3 * 1024 * oneGiB)
	eta := formatETA(0, threeTiB, 110*1024*1024)
	if eta == "" || eta == "unknown" {
		t.Fatalf("expected ETA, got %q", eta)
	}
}
